# USDA ERS Food Dollar

For each $1 spent on food in a given context, where does that dollar go? ([More info](http://www.ers.usda.gov/data-products/food-dollar-series.aspx))

See it on github pages: http://rmosolgo.github.io/usda-ers-food-dollar/


## Example

![image](https://cloud.githubusercontent.com/assets/2231765/9151980/5bc2e8bc-3dcc-11e5-8330-8ed546bcfbf0.png)

## How

- Pull data from the API with `ruby food_dollar.rb {API_KEY}`
- Write data into `food_dollar.json`
- Render charts with `index.html` + `food_dollar.js`
