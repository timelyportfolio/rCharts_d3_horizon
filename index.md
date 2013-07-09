---
title: rCharts Extra - d3 Horizon Conversion
author: Timely Portfolio
github: {user: timelyportfolio, repo: rCharts_d3_horizon, branch: "gh-pages"}
framework: bootstrap
mode: selfcontained
highlighter: prettify
hitheme: twitter-bootstrap
widgets: "d3_horizon"
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
- uses [mustache templates](http://mustache.github.io/) through the R package [`whisker`](https://github.com/edwindj/whisker) to bind html/js with `R`, and
- employs [YAML](http://www.yaml.org/) through the R package [`yaml`](http://cran.r-project.org/web/packages/yaml/index.html) for configuration,
- passes data and parameters with [`RJSONIO`](http://cran.r-project.org/web/packages/RJSONIO/index.html).


---
<br/>
### rCharts Innards
<h4>A Naked rChart</h4>
What does a naked rChart look like?


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
##   ..$ dom   : chr "charteb8717a58db"
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

Only if it matters to you, a [`rChart`](https://github.com/ramnathv/rCharts/blob/master/R/rChartsClass.R) is a [R5 object or reference class](https://github.com/hadley/devtools/wiki/R5).  If it doesn't matter to you, just forget what I just said.  As the `str` output tells us, this rChart has 8 fields and 24 methods (functions), of which 12 "are possibly relevant".  I am guessing some like `width` and `height` do not need much explanation, but the others might not be immediately understood.  Since I learn by breaking, what happens if we call `rChart`?


```r
rChart
```

```
## Warning: cannot open file '/layouts/chart.html': No such file or directory
```


---
<h4>Templates with Mustaches</h4>

Darn it didn't work, but we did get a clue `/layouts/chart.html`.  This falls into the `templates` field in the `str` output above and looks like a file and directory.  I guess it would be wise to inspect this `templates` field.  In it, we find `page`, `chartDiv`, and `script`.  `page` and `script` look like html files, so let's find out where these are and what's inside.  `page` is defined as rChart.html, which is inside your `R` rCharts package.  You can see for yourself by typing the following in `R`:


```r
readLines(system.file("rChart.html", package = "rCharts"))
```


or you can also find the rChart.html [here in source](https://github.com/ramnathv/rCharts/blob/master/inst/rChart.html).  I would show it, but all these `{` and `}` do not show up. The reason why they don't show up is also some of the magic behind rCharts.  These multiple `{` and `}` are mustaches and get filled through the `R` package [`whisker`](https://github.com/edwindj/whisker) as described in the `whisker` [Readme.md](https://github.com/edwindj/whisker/blob/master/readme.md).

<blockquote>Whisker is a {{Mustache}} implementation in R confirming to the Mustache specification. Mustache is a logicless templating language, meaning that no programming source code can be used in your templates. This may seem very limited, but Mustache is nonetheless powerful and has the advantage of being able to be used unaltered in many programming languages. It makes it very easy to write a web application in R using Mustache templates which could also be re-used for client-side rendering with "Mustache.js".

Mustache (and therefore whisker) takes a simple, but different, approach to templating compared to most templating engines. Most templating libraries, such as Sweave, knitr and brew, allow the user to mix programming code and text throughout the template. This is powerful, but ties your template directly to a programming language and makes it difficult to seperate programming code from templating code.

Whisker, on the other hand, takes a Mustache template and uses the variables of the current environment (or the supplied list) to fill in the variables.
</blockquote>

So all these multiple mustaches `{` `}` will get filled with `R` variables or function output.  For instance, the three mustache `chartId` will get populated by the R variable `chartId`.  This gets assigned in the [`render` method](https://github.com/ramnathv/rCharts/blob/master/R/rChartsClass.R#L64) `chartId = params$dom`.  If we look back at our `str` output above we see

```
$ params   :List of 3
   ..$ dom   : chr "charteb8717a58db"
```
so once we fix our error (nope, still haven't even come close to fixing), we should see this is our html output.  Now let's see why our mustache is full of [YAML](http://www.yaml.org/).

---
<h4>Mustache Full of YAML</h4>
If we are working with html/js, we have to expect some js and css file dependencies that we will need to load.  `rCharts` looks for a [YAML](http://www.yaml.org/) file config.yml to tell us the location for all these js and css files.  This [line]([YAML](https://github.com/ramnathv/rCharts/blob/master/R/rChartsClass.R#L63)

```
 assets = get_assets(LIB, static = T, cdn = cdn)
```

calls this [line](https://github.com/ramnathv/rCharts/blob/master/R/utils.R#L34)

```
get_assets <- function(LIB, static = T, cdn = F){
  config = yaml.load_file(file.path(LIB$url, 'config.yml'))[[1]]
```

which parses the YAML for our js and css file locations.  As an example, below is the [config.yml](https://github.com/ramnathv/rCharts/blob/master/inst/libraries/nvd3/config.yml) for the `rCharts` implementation of `NVD3`.

```
nvd3:
  css: [css/nv.d3.css, css/rNVD3.css]
  jshead: [js/jquery-1.8.2.min.js, js/d3.v3.min.js, "js/nv.d3.min-new.js", js/fisheye.js]
  cdn:
    css: http://nvd3.org/src/nv.d3.css
    jshead: 
      - "http://ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"
      - "http://d3js.org/d3.v2.min.js"
      - "http://nvd3.org/nv.d3.js"
      - "http://nvd3.org/lib/fisheye.js"
```





<h4>Get Data and Transform</h4>


### Thanks
As I hope you can tell, this post was more a function of the efforts of others than of my own.

Thanks specifically:
- Ramnath Vaidyanathan for [rCharts](http://rcharts.io/site) and [slidify](http://slidify.org).
- [Jason Davies](http://www.jasondavies.com/) for the [Horizon Chart d3 plugin](https://github.com/d3/d3-plugins/blob/master/horizon/horizon.js) and all his contributions and examples.
- [Mike Bostock](http://bost.ocks.org/mike/) for everything.
- Google fonts [Raleway](http://www.google.com/fonts/specimen/Raleway) and [Oxygen](http://www.google.com/fonts/specimen/Oxygen)
