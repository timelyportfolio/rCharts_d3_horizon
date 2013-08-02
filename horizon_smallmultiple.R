require(rCharts)

rChart <- rCharts$new()
rChart$setLib('http://timelyportfolio.github.io/rCharts_d3_horizon/libraries/widgets/d3_horizon')
rChart$setTemplate(script = 'http://timelyportfolio.github.io/rCharts_d3_horizon/libraries/widgets/d3_horizon/layouts/d3_horizon_smallmultiple.html')

rChart$set(
  bands = 3,
  mode = "mirror",
  interpolate = "basis",
  width = 700,
  height = 300
)

require(quantmod)
#get sp500 prices and convert them to monthly
SP500 <- to.monthly(
  getSymbols("^GSPC", from = "1990-01-01", auto.assign = FALSE)
)[,4]
Nasdaq <- to.monthly(
  getSymbols("^IXIC", from = "1990-01-01", auto.assign = FALSE)
)[,4]
Dax <- to.monthly(
  getSymbols("^GDAXI", from = "1990-01-01", auto.assign = FALSE)
)[,4]

#get 12 month rolling return
prices <- merge(SP500,Nasdaq,Dax)
returns <- na.omit(ROC(prices, type = "discrete", n = 12))
returns.df <- cbind(
  as.numeric(as.POSIXct(as.Date(index(returns)))),
  coredata(returns)
)

colnames(returns.df) <- c("date","SP500","Nasdaq","DAX")

#supply the data to our dataless but no longer naked rChart

rChart$set(data = returns.df)
rChart$set(x = "date")
rChart