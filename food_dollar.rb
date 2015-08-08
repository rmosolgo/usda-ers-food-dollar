require 'net/http'
require 'uri'
require 'json'

# Get a data type from the API:
class EndpointURL
  attr_reader :to_s
  def initialize(name)
    @to_s = "http://api.data.gov/USDA/ERS/data/FoodDollar/#{name}"
  end
end

# Fetch JSON from the API
class DataRequest
  API_KEY = ARGV[0] || raise("Pass an API Key, eg `ruby food_dollar.rb 12345`")

  attr_reader :url, :params

  def initialize(url, params={})
    @url = url
    @params = params.merge({
      api_key: API_KEY,
    })
  end

  def result
    @result ||= fetch_result
  end

  def all_pages_data_table
    info = result["infoTable"][0]
    data_table = result["dataTable"]

    if info["recordCount"] > params[:size] * (info["pageIndex"] + 1)
      next_page_params = params.merge(start: params[:start] + params[:size])
      next_page_request = self.class.new(url, next_page_params)
      next_data_table = next_page_request.all_pages_data_table
      data_table += next_data_table
    end

    data_table
  rescue StandardError => e
    p "#{e} #{e.backtrace}"
    p info
  end


  private

  def fetch_result
    uri = URI(url)
    uri.query = URI.encode_www_form(params)
    puts "#{uri}"
    response = Net::HTTP.get(uri)
    JSON.parse(response)
  end
end

# For a given food-dollar, year-over-year percentages
class FoodDollarTable
  attr_reader :name
  def initialize(name, years:, categories:)
    @name = name
    @years = years
    @categories = categories
    @entries = []
  end

  def add_entry(entry)
    @entries << entry
  end

  # Serialize for rendering with D3
  def as_hash
    {
      name: name,
      categories: @categories.map do |category|
        next if category == "Total"
        years = @years.map do |year|
          hash = {x: year, category: category}
          entry = @entries.find {|entry| entry.year == year && entry.category == category}
          hash[:y] = if entry
              entry.value
            else
              hash[:missing] = true
              0
            end
          hash
        end.compact
      end.compact
    }
  end
end

class FoodDollarEntry
  attr_reader :year, :category, :value
  def initialize(year:, category:, value:)
    @year = year
    @category = category
    @value = value
  end
end

# First, get all the years:
years_url = EndpointURL.new("Years").to_s
years_request = DataRequest.new(years_url, scope: "real")
years = years_request.result.map(&:to_i)

# Then get all the categories
categories_url = EndpointURL.new("Categories").to_s
categories_request = DataRequest.new(categories_url)
categories = categories_request.result["dataTable"].map {|cat| cat["category_desc"] }

# Get all the tables:
tables_url = EndpointURL.new("Tables").to_s
tables_request = DataRequest.new(tables_url)
tables = tables_request.result["dataTable"]

TABLES = tables.each_with_object({}) do |t, memo|
  memo[t["table_num"]] = FoodDollarTable.new(t["table_name"], years: years, categories: categories)
end

# Then get all the entries
entries_url = EndpointURL.new("Nominal").to_s
entries_request = DataRequest.new(entries_url, size: 200, start: 0)
entries = entries_request.all_pages_data_table
entries.each do |entry|
  entry_obj = FoodDollarEntry.new(
    year: entry["year"],
    category: entry["category_desc"],
    value: entry["total"]
  )
  TABLES[entry["table_num"]].add_entry(entry_obj)
end
puts "Found #{entries.length} entries"

tables_json = JSON.pretty_generate(TABLES.values.map(&:as_hash))
File.write("food_dollar.json", tables_json)
