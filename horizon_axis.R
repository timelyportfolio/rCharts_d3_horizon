require(rCharts)

rChart <- rCharts$new()
rChart$setLib('libraries/widgets/d3_horizon')
rChart$setTemplate(script = "libraries/widgets/d3_horizon/layouts/d3_horizon_axes.html")

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
)

#get 12 month rolling return
SP500.ret <- na.omit(ROC(SP500[,4], type = "discrete", n = 12))
SP500.df <- cbind(
  as.numeric(as.POSIXct(as.Date(index(SP500.ret)))),
  coredata(SP500.ret)
)

colnames(SP500.df) <- c("date","SP500")

#supply the data to our dataless but no longer naked rChart

rChart$set(data = SP500.df)
rChart$set(x = "date", y = "SP500")
rChart