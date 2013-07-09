---
title: rCharts Extra - d3 Horizon Conversion
author: Timely Portfolio
github: {user: timelyportfolio, repo: rCharts_d3_horizon, branch: "gh-pages"}
framework: bootstrap
mode: selfcontained
widgets: "d3_horizon"
highlighter: prettify
hitheme: twitter-bootstrap
assets:
  css:
    - "http://fonts.googleapis.com/css?family=Raleway:300"
    - "http://fonts.googleapis.com/css?family=Oxygen"
---

<style>
body{
  font-family: 'Oxygen', sans-serif;
  font-size: 16px;
  line-height: 24px;
}

h1,h2,h3,h4 {
  font-family: 'Raleway', sans-serif;
}

.container { width: 1000px; }

h3 {
  background-color: #D4DAEC;
  text-indent: 100px; 
}

h4 {
  text-indent: 100px;
}

g-table-intro h4 {
  text-indent: 0px;
}
</style>

<a href="https://github.com/timelyportfolio/rCharts_d3_horizon"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_darkblue_121621.png" alt="Fork me on GitHub"></a>

# rCharts Conversion of d3 Horizon Plot Plugin

---
<br/>
### Disclaimer and Attribution

**Much of this work is based on the [horizon plot plugin](https://github.com/d3/d3-plugins/blob/master/horizon/horizon.js) by Jason Davies and the [example](http://bl.ocks.org/mbostock/1483226) by Mike Bostock.** 




---
<br/>
### rCharts Extra
  
[`rCharts`](http://rcharts.io/site) provides almost every chart type imaginable through multiple js libraries.  The speed at which it has added libraries shows that the authors are well aware of the quick pace of innovation in the visualization community especially around [d3.js](http://d3js.org).  It is foolish to think though that every chart in every combination with every interaction will be available, so fortunately `rCharts` is designed to also easily accommodate custom charts.

There are already some very impressive conversions of complicated NY Times Interactive pieces, but I thought it would be helpful to show how we might convert a more basic chart type with less moving parts.  Since I love horizon plots, summarized in [Horizon Plots with plot.xts](http://timelyportfolio.blogspot.com/2012/08/horizon-plots-with-plotxts.html) and explained in [More on Horizon Charts](http://timelyportfolio.blogspot.com/2012/08/more-on-horizon-charts.html), the [horizon plot d3 plugin](https://github.com/d3/d3-plugins/blob/master/horizon/horizon.js) from Jason Davies will be our target.

This tutorial will go in depth to explain some of the inner workings of `rCharts` as we work through an implementation of d3 horizon plots.  We will see how `rCharts`
- employs [YAML](http://www.yaml.org/) through the R package [`yaml`](http://cran.r-project.org/web/packages/yaml/index.html) for configuration,
- uses [mustache templates](http://mustache.github.io/) through the R package [`whisker`](https://github.com/edwindj/whisker) to bind html/js with `R`, and
- passes data and parameters with [`RJSONIO`](http://cran.r-project.org/web/packages/RJSONIO/index.html).


---
<br/>
### rCharts Innards
<h4>A Naked rChart</h4>
Only if it matters to you, a [`rChart`](https://github.com/ramnathv/rCharts/blob/master/R/rChartsClass.R) is a [R5 object or reference class](https://github.com/hadley/devtools/wiki/R5).  If it doesn't matter to you, just forget what I just said.  Let's see what a naked rChart looks like.


```r
# if you do not have rCharts or if you have an outdated version
# require(devtools) install_github('rCharts', 'ramnathv')
require(rCharts)
rChart <- rCharts$new()
str(rChart)
```

```
## Reference class 'rCharts' [package "rCharts"] with 8 fields
##  $ params   :List of 3
##   ..$ dom   : chr "chart25484f9962cf"
##   ..$ width : num 800
##   ..$ height: num 400
##  $ lib      : chr "rcharts"
##  $ LIB      :List of 2
##   ..$ name: chr "rcharts"
##   ..$ url : chr ""
##  $ srccode  : NULL
##  $ tObj     : list()
##  $ container: chr "div"
##  $ html_id  : chr ""
##  $ templates:List of 3
##   ..$ page    : chr "rChart.html"
##   ..$ chartDiv: NULL
##   ..$ script  : chr "/layouts/chart.html"
##  and 24 methods, of which 12 are possibly relevant:
##    addParams, getPayload, html, initialize, print, publish, render, save,
##    set, setLib, setTemplate, show#envRefClass
```


<h4>Get Data and Transform</h4>


### Thanks
As I hope you can tell, this post was more a function of the efforts of others than of my own.

Thanks specifically:
- Ramnath Vaidyanathan for [rCharts](http://rcharts.io/site) and [slidify](http://slidify.org).
- [Jason Davies](http://www.jasondavies.com/) for the [Horizon Chart d3 plugin](https://github.com/d3/d3-plugins/blob/master/horizon/horizon.js) and all his contributions and examples.
- [Mike Bostock](http://bost.ocks.org/mike/) for everything.
- Google fonts [Raleway](http://www.google.com/fonts/specimen/Raleway) and [Oxygen](http://www.google.com/fonts/specimen/Oxygen)
