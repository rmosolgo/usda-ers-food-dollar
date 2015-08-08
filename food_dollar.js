var FoodDollar = {
  render: function(data) {
    var container = document.getElementById("food-dollar")
    data.forEach(function(table) {
      var tableContainer = prepareContainer(table)
      renderChartIntoContainer(table, tableContainer)
      container.appendChild(tableContainer)
    })
  },

  width: 800,
  height: 500,
  area: d3.svg.area()
    .x(function(d) {  return FoodDollar.xScale(d.x); })
    .y0(function(d) { return FoodDollar.yScale(d.y0); })
    .y1(function(d) { return FoodDollar.yScale(d.y0 + d.y); }),
  color: d3.scale.ordinal()
    .domain(
      [
        "Agribusiness", "Farm production", "Food processing",
        "Packaging", "Transportation", "Wholesale trade",
        "Retail trade", "Foodservices", "Energy",
        "Finance & Insurance", "Advertising", "Legal & accounting"
      ]
    )
    .range(
      [
        "#f00", "#f90", "#ff0", "#ff9",
        "#0f0", "#0f9", "#0ff", "#9ff",
        "#00f", "#09f", "#f0f", "#f9f",
      ]
    ),

}

FoodDollar.xScale = d3.scale.linear()
  .domain([1993, 2012])
  .range([0, FoodDollar.width]);

FoodDollar.yScale = d3.scale.linear()
  .domain([0, 1])
  .range([0, FoodDollar.height - 30]);

FoodDollar.xAxis = d3.svg.axis()
    .scale(FoodDollar.xScale)
    .tickFormat(d3.format(".0d"))
    .orient("bottom")
    .tickValues([1995, 2000, 2005, 2010])

function prepareContainer(table) {
  var container = document.createElement("div")
  var header = document.createElement("h2")
  header.innerText = table.name
  container.appendChild(header)
  return container
}

function renderChartIntoContainer(table, container) {
  var stack = d3.layout.stack()
    .offset("expand")

  var layers = stack(table.categories)
  console.log(table.name, layers)

  var svg = d3.select(container).append("svg")
      .attr("width", FoodDollar.width)
      .attr("height", FoodDollar.height);

  svg.selectAll("path")
      .data(layers)
    .enter().append("path")
      .attr("d", function(d) { console.log(d); return FoodDollar.area(d) } )
      .style("fill", function() { return FoodDollar.color(Math.random()); })
    .append("title")
      .text(function(d) { return d[0].category + " [" + d.map(function(i) { return "" + i.x + ": " + Math.round(i.y * 100) / 100 }).join(", ") + "]" });

  svg.append("g")
    .attr("transform", "translate(0," + (FoodDollar.height - 30) + ")")
    .call(FoodDollar.xAxis);
}
