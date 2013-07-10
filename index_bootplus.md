---
title: rCharts Extra - d3 Horizon Conversion
author: Timely Portfolio
github: {user: timelyportfolio, repo: rCharts_d3_horizon, branch: "gh-pages"}
framework: bootplus
layout: post
mode: selfcontained
highlighter: prettify
hitheme: twitter-bootstrap
widgets: "d3_horizon"
assets:
  css:
    - "http://fonts.googleapis.com/css?family=Raleway:300"
    - "http://fonts.googleapis.com/css?family=Oxygen"
---

# Why Custom?

<style>
body{
  font-family: 'Oxygen', sans-serif;
  font-size: 15px;
  line-height: 22px;
}

h1,h2,h3,h4 {
  font-family: 'Raleway', sans-serif;
}
</style>


[`rCharts`](http://rcharts.io/site) provides almost every chart type imaginable through multiple js libraries.  The speed at which it has added libraries shows that the authors are well aware of the quick pace of innovation in the visualization community especially around [d3.js](http://d3js.org).  It is foolish to think though that every chart in every combination with every interaction will be available, so fortunately `rCharts` is designed to also easily accommodate custom charts.

There are already some very impressive conversions of complicated NY Times Interactive pieces, but I thought it would be helpful to show how we might convert a more basic chart type with less moving parts.  Since I love horizon plots (summarized in [Horizon Plots with plot.xts](http://timelyportfolio.blogspot.com/2012/08/horizon-plots-with-plotxts.html) and explained in [More on Horizon Charts](http://timelyportfolio.blogspot.com/2012/08/more-on-horizon-charts.html)), the [horizon plot d3 plugin](https://github.com/d3/d3-plugins/blob/master/horizon/horizon.js) from Jason Davies will be a lovely target.

This tutorial will go in depth to explain some of the inner workings of `rCharts` as we work through an implementation of d3 horizon plots.  We will see how `rCharts`
- uses [mustache templates](http://mustache.github.io/) through the R package [`whisker`](https://github.com/edwindj/whisker) to bind html/js with `R,
- employs [YAML](http://www.yaml.org/) through the R package [`yaml`](http://cran.r-project.org/web/packages/yaml/index.html) for configuration, and
- passes data and parameters with [`RJSONIO`](http://cran.r-project.org/web/packages/RJSONIO/index.html).


### Disclaimer and Attribution

**Much of this work is based on the [horizon plot plugin](https://github.com/d3/d3-plugins/blob/master/horizon/horizon.js) by Jason Davies and the [example](http://bl.ocks.org/mbostock/1483226) by Mike Bostock.** 





---.RAW
### rCharts Innards
<h4>A Naked rChart</h4>
What does a naked rChart look like?


```r
#if you do not have rCharts or if you have an outdated version
#require(devtools)
#install_github('rCharts', 'ramnathv')
require(rCharts)
rChart <- rCharts$new()
str(rChart)
```

Reference class 'rCharts' [package "rCharts"] with 8 fields
 $ params   :List of 3
  ..$ dom   : chr "chart249c4ba54a27"
  ..$ width : num 800
  ..$ height: num 400
 $ lib      : chr "rcharts"
 $ LIB      :List of 2
  ..$ name: chr "rcharts"
  ..$ url : chr ""
 $ srccode  : NULL
 $ tObj     : list()
 $ container: chr "div"
 $ html_id  : chr ""
 $ templates:List of 3
  ..$ page    : chr "rChart.html"
  ..$ chartDiv: NULL
  ..$ script  : chr "/layouts/chart.html"
 and 24 methods, of which 12 are possibly relevant:
   addParams, getPayload, html, initialize, print, publish, render, save,
   set, setLib, setTemplate, show#envRefClass

Only if it matters to you, a [`rChart`](https://github.com/ramnathv/rCharts/blob/master/R/rChartsClass.R) is a [R5 object or reference class](https://github.com/hadley/devtools/wiki/R5).  If it doesn't matter to you, just forget what I just said.  As the `str` output tells us, this rChart has 8 fields and 24 methods (functions), of which 12 "are possibly relevant".  I am guessing some like `width` and `height` do not need much explanation, but the others might not be immediately understood.  Since I learn by breaking, what happens if we call `rChart`?


```r
rChart
```


<h4>Templates with Mustaches</h4>

Darn it didn't work, but we did get a clue `/layouts/chart.html`.  This falls into the `templates` field in the `str` output above and looks like a file and directory.  I guess it would be wise to inspect this `templates` field.  In it, we find `page`, `chartDiv`, and `script`.  `page` and `script` look like html files, so let's find out where these are and what's inside.  `page` is defined as rChart.html, which is inside your `R` rCharts package.  You can see for yourself by typing the following in `R`:


```r
readLines(system.file('rChart.html', package = 'rCharts'))
```


or you can also find the rChart.html [here in source](https://github.com/ramnathv/rCharts/blob/master/inst/rChart.html).

```
<!doctype HTML>
<meta charset = 'utf-8'>
<html>
  <head>
    {{# assets.css }}
    <link rel='stylesheet' href='{{{ . }}}'>
    {{/ assets.css }}
    
    {{# assets.jshead }}
    <script src='{{{ . }}}' type='text/javascript'></script>
    {{/ assets.jshead }}
    
    <style>
    .rChart {
      display: block;
      margin-left: auto; 
      margin-right: auto;
      width: {{params.width}}px;
      height: {{params.height}}px;
    }  
    </style>
    
  </head>
  <body>
    {{# chartId }}
    <{{container}} id='{{chartId}}' class='rChart {{ lib }}'></{{container}}>  
    {{/ chartId }}
    
    {{{ script }}}
    
  </body>
</html>
```

All the `{{{ }}}` provide some of the magic behind rCharts.  These multiple `{{{ }}}` are mustaches and get filled through the `R` package [`whisker`](https://github.com/edwindj/whisker) as described in the `whisker` [Readme.md](https://github.com/edwindj/whisker/blob/master/readme.md).

<blockquote>Whisker is a {{Mustache}} implementation in R confirming to the Mustache specification. Mustache is a logicless templating language, meaning that no programming source code can be used in your templates. This may seem very limited, but Mustache is nonetheless powerful and has the advantage of being able to be used unaltered in many programming languages. It makes it very easy to write a web application in R using Mustache templates which could also be re-used for client-side rendering with "Mustache.js".

Mustache (and therefore whisker) takes a simple, but different, approach to templating compared to most templating engines. Most templating libraries, such as Sweave, knitr and brew, allow the user to mix programming code and text throughout the template. This is powerful, but ties your template directly to a programming language and makes it difficult to seperate programming code from templating code.

Whisker, on the other hand, takes a Mustache template and uses the variables of the current environment (or the supplied list) to fill in the variables.
</blockquote>

So all these multiple mustaches `{{{ }}}` get shaven and replaced with `R` variables or function output.  For instance, the mustached `{{ chartId }}` will get populated by the R variable `chartId`.  This gets assigned in the [`render` method](https://github.com/ramnathv/rCharts/blob/master/R/rChartsClass.R#L64) `chartId = params$dom`.  If we look back at our `str` output above we see

```
$ params   :List of 3
   ..$ dom   : chr "chart249c23a11dcc"
```
so once we fix our error (nope, still haven't even come close to fixing), we should see this is our html output.  Now let's see why our mustache is full of [YAML](http://www.yaml.org/).

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
`rCharts` is smart enough to handle the css and js for both a local rendering and a rendering which might be happier served from a CDN.  `whisker` and `mustache` are smart enough to handle array type structures to list each file if there is more than one file.

You might wonder if we will ever fix our error and see a horizon plot.  Let's do both at the same time in the next section.

---.RAW
### Convert the Horizon
<h4>Finally, Fix Our Error and Start to See the Horizon</h4>
The reason for our error
```
## Warning: cannot open file '/layouts/chart.html': No such file or directory
```
is mustache tries to fill the `{{{ script }}}` portion of rChart.html with a file specified by  which is


```r
rChart$templates$script
```

[1] "/layouts/chart.html"

which might or might not exist.  We can get away with not specifying the location of `templates$page` (rChart.html).  It is designed to be fairly universal, so there is a default in the rCharts package, but the script template for each library or custom implementation will be different.  In each of the library implementations, `templates$script` will be populated at initialization in these [two lines of code](https://github.com/ramnathv/rCharts/blob/master/R/rChartsClass.R#L8).
```
lib <<- tolower(as.character(class(.self)))
LIB <<- get_lib(lib) # library name and url to library folder
```
Here is the [chart.html script template](https://github.com/ramnathv/rCharts/blob/master/inst/libraries/nvd3/layouts/chart.html) for NVD3, which `rCharts` will assume is in libraries/nvd3/layouts/ directory, since the reference class for NVD3 is called Nvd3 [`setRefClass('Nvd3'...`](https://github.com/ramnathv/rCharts/blob/master/R/Nvd3.R#L7).

<h4>Roll Your Own Template</h4>

For custom charts, we will need to write our own script (easy enough usually with a lot of copy/paste) and tell rCharts where to find it.  We could put it anywhere.  For this tutorial, I will be using the `R` package [slidify](http://slidify.org) which will prefer that my directory is in /libraries/widgets/.  To be original I will name my widget d3_horizon and my script template d3_horizon.html, so the full directory will be /libraries/widgets/d3_horizon/layouts/d3_horizon.html.  Here is how we would tell `rCharts` to find our custom template.


```r
rChart$setLib('libraries/widgets/d3_horizon')
rChart$setTemplate(script = "libraries/widgets/d3_horizon/layouts/d3_horizon.html")
```


As I said, the script template usually will be a lot of copy/paste if you are trying to recreate something you have seen.  For the horizon plot, let's copy/paste from this example by [Mike Bostock](http://bl.ocks.org/mbostock/1483226).

<h4>Draw a Mustache on Your Copy/Paste</h4>

The basic process is find each of the variables or parameters we would like to define in `R`.  All of the parameters for our horizon plot are nicely provided in the [first couple lines of code](https://github.com/d3/d3-plugins/blob/master/horizon/horizon.js#L3) in the horizon.js plugin.

```
    var bands = 1, // between 1 and 5, typically
        mode = "offset", // or mirror
        interpolate = "linear", // or basis, monotone, step-before, etc.
        x = d3_horizonX,
        y = d3_horizonY,
        w = 960,
        h = 40,
        duration = 0;
```

In R, we can set these with `set` like this


```r
rChart$set(
  bands = 3,
  mode = "mirror",
  interpolate = "basis",
  width = 700,
  height = 300
)
```

and all of these will go into the `rCharts$params` list.  Remember our powerful and sexy mustache.  We can get these parameters with it.  Just triple mustache `{{{ params }}}`.

Now let's find the relevant parts of the code from the example.

```
var chart = d3.horizon()
    .width(width)
    .height(height)
    .bands(1)
    .mode("mirror")
    .interpolate("basis");

var svg = d3.select("body").append("svg")
    .attr("width", width)
    .attr("height", height);
    
...

// Render the chart.
svg.data([data]).call(chart);
```
We will change them just slightly to the following.

```
var params = {{{ chartParams }}};

var svg = d3.select('#' + params.id).append("svg")
    .attr("width", params.width)
    .attr("height", params.height);
    
var chart = d3.horizon()
    .width(params.width)
    .height(params.height)
    .bands(params.band)
    .mode(params.mode)
    .interpolate(params.interpolate);
    
svg.data(params.data).call(chart)
```

If you are following along at home, copy and paste that into your script template chart.html.  You can see mine [here](https://github.com/timelyportfolio/rCharts_d3_horizon/blob/gh-pages/libraries/widgets/d3_horizon/layouts/d3_horizon_no_data.html).

<h4>Supply the Data</h4>
Those paying real close attention will know `params$data` has not been defined.  Let's supply some data in the form of rolling 12-month returns on the S&P 500.


```r
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
```

You might think we are done, but if you call `rChart` our error is fixed, but we get a new error in the browser because we did not transform our data.  This is a common, sometimes easily fixed, sometimes very difficult piece.  If we debug the example, we will see the data is provided as an array of arrays.

![Screenprint of Expected Data](images/expected_data.png)

Real quickly, now is a great time to cover how everything is converted from R vectors, lists, data.frames, etc. to javascript.  This all happens with the R package [`RJSONIO`](http://cran.r-project.org/web/packages/RJSONIO/index.html).  In this case, our `params$data` is converted to `JSON` as an array of objects.

We will need to allow an `x` and `y` to be specified in `R`


```r
rChart$set(x = "date", y = "SP500")
```


and write a simple javascript `map` transform to do the conversion in our script template

```
data = [params.data.map(function(d) {return[d[params.x],d[params.y]]})];

svg.data(data).call(chart);
```
Just one last final item.  We need to supply a config.yml for `rCharts` to know where we have copied d3js and the horizon plugin.  It should look something like this.
```
d3_horizon:
  jshead: [js/d3.v3.js,js/horizon.js]
  cdn:
    jshead: 
      - "http://d3js.org/d3.v3.min.js"
      - "http://timelyportfolio.github.io/rCharts_d3_horizon/libraries/widgets/js/d3_horizon/horizon.js"

```


---
### Our Horizon Chart
Now for the magic moment.


```r
rChart
```


<div id='chart249c4ba54a27' class='rChart d3_horizon'></div>
<!--Attribution:
Jason Davies https://github.com/d3/d3-plugins/tree/master/horizon
Mike Bostock http://bl.ocks.org/mbostock/1483226
-->

<script>
var params = {
 "dom": "chart249c4ba54a27",
"width":    700,
"height":    300,
"id": "chart249c4ba54a27",
"bands":      3,
"mode": "mirror",
"interpolate": "basis",
"data": [ {
 "date": 6.6269e+08,
"SP500": 0.045126 
},
{
 "date": 6.6537e+08,
"SP500":  0.106 
},
{
 "date": 6.6779e+08,
"SP500": 0.10378 
},
{
 "date": 6.7046e+08,
"SP500": 0.13464 
},
{
 "date": 6.7306e+08,
"SP500": 0.079174 
},
{
 "date": 6.7573e+08,
"SP500": 0.036702 
},
{
 "date": 6.7833e+08,
"SP500": 0.088895 
},
{
 "date": 6.81e+08,
"SP500": 0.22591 
},
{
 "date": 6.8368e+08,
"SP500": 0.26731 
},
{
 "date": 6.8628e+08,
"SP500": 0.29095 
},
{
 "date": 6.8895e+08,
"SP500": 0.16448 
},
{
 "date": 6.9155e+08,
"SP500": 0.26307 
},
{
 "date": 6.9422e+08,
"SP500": 0.18856 
},
{
 "date": 6.969e+08,
"SP500": 0.12431 
},
{
 "date": 6.9941e+08,
"SP500": 0.075875 
},
{
 "date": 7.0209e+08,
"SP500": 0.10553 
},
{
 "date": 7.0468e+08,
"SP500": 0.065464 
},
{
 "date": 7.0736e+08,
"SP500": 0.099634 
},
{
 "date": 7.0995e+08,
"SP500": 0.09386 
},
{
 "date": 7.1263e+08,
"SP500": 0.047037 
},
{
 "date": 7.1531e+08,
"SP500": 0.077193 
},
{
 "date": 7.179e+08,
"SP500": 0.066837 
},
{
 "date": 7.2058e+08,
"SP500": 0.14959 
},
{
 "date": 7.2317e+08,
"SP500": 0.044643 
},
{
 "date": 7.2585e+08,
"SP500": 0.073389 
},
{
 "date": 7.2852e+08,
"SP500": 0.07434 
},
{
 "date": 7.3094e+08,
"SP500": 0.11885 
},
{
 "date": 7.3362e+08,
"SP500": 0.060827 
},
{
 "date": 7.3621e+08,
"SP500": 0.083881 
},
{
 "date": 7.3889e+08,
"SP500": 0.10386 
},
{
 "date": 7.4148e+08,
"SP500": 0.056387 
},
{
 "date": 7.4416e+08,
"SP500": 0.11963 
},
{
 "date": 7.4684e+08,
"SP500": 0.098444 
},
{
 "date": 7.4943e+08,
"SP500": 0.11739 
},
{
 "date": 7.5211e+08,
"SP500": 0.070569 
},
{
 "date": 7.547e+08,
"SP500": 0.070552 
},
{
 "date": 7.5738e+08,
"SP500": 0.097612 
},
{
 "date": 7.6006e+08,
"SP500": 0.053588 
},
{
 "date": 7.6248e+08,
"SP500": -0.013063 
},
{
 "date": 7.6516e+08,
"SP500": 0.024353 
},
{
 "date": 7.6775e+08,
"SP500": 0.014016 
},
{
 "date": 7.7043e+08,
"SP500": -0.013895 
},
{
 "date": 7.7302e+08,
"SP500": 0.022605 
},
{
 "date": 7.757e+08,
"SP500": 0.025736 
},
{
 "date": 7.7838e+08,
"SP500": 0.0082366 
},
{
 "date": 7.8097e+08,
"SP500": 0.0096616 
},
{
 "date": 7.8365e+08,
"SP500": -0.01754 
},
{
 "date": 7.8624e+08,
"SP500": -0.015393 
},
{
 "date": 7.8892e+08,
"SP500": -0.023235 
},
{
 "date": 7.916e+08,
"SP500": 0.043349 
},
{
 "date": 7.9402e+08,
"SP500": 0.12325 
},
{
 "date": 7.9669e+08,
"SP500": 0.14149 
},
{
 "date": 7.9929e+08,
"SP500": 0.16846 
},
{
 "date": 8.0196e+08,
"SP500": 0.22617 
},
{
 "date": 8.0456e+08,
"SP500": 0.22651 
},
{
 "date": 8.0724e+08,
"SP500": 0.18169 
},
{
 "date": 8.0991e+08,
"SP500": 0.26302 
},
{
 "date": 8.1251e+08,
"SP500": 0.23108 
},
{
 "date": 8.1518e+08,
"SP500": 0.33433 
},
{
 "date": 8.1778e+08,
"SP500": 0.34111 
},
{
 "date": 8.2045e+08,
"SP500": 0.35203 
},
{
 "date": 8.2313e+08,
"SP500":  0.314 
},
{
 "date": 8.2564e+08,
"SP500": 0.28917 
},
{
 "date": 8.2832e+08,
"SP500": 0.27095 
},
{
 "date": 8.3091e+08,
"SP500": 0.25444 
},
{
 "date": 8.3359e+08,
"SP500": 0.23108 
},
{
 "date": 8.3618e+08,
"SP500": 0.13858 
},
{
 "date": 8.3886e+08,
"SP500": 0.16037 
},
{
 "date": 8.4154e+08,
"SP500": 0.17611 
},
{
 "date": 8.4413e+08,
"SP500": 0.21285 
},
{
 "date": 8.4681e+08,
"SP500": 0.25051 
},
{
 "date": 8.494e+08,
"SP500": 0.20264 
},
{
 "date": 8.5208e+08,
"SP500": 0.23606 
},
{
 "date": 8.5476e+08,
"SP500": 0.23483 
},
{
 "date": 8.5717e+08,
"SP500": 0.17292 
},
{
 "date": 8.5985e+08,
"SP500": 0.22497 
},
{
 "date": 8.6244e+08,
"SP500": 0.26775 
},
{
 "date": 8.6512e+08,
"SP500": 0.31986 
},
{
 "date": 8.6772e+08,
"SP500": 0.49123 
},
{
 "date": 8.7039e+08,
"SP500": 0.37958 
},
{
 "date": 8.7307e+08,
"SP500": 0.3782 
},
{
 "date": 8.7566e+08,
"SP500": 0.29684 
},
{
 "date": 8.7834e+08,
"SP500": 0.26205 
},
{
 "date": 8.8093e+08,
"SP500": 0.31008 
},
{
 "date": 8.8361e+08,
"SP500": 0.24692 
},
{
 "date": 8.8629e+08,
"SP500": 0.3269 
},
{
 "date": 8.8871e+08,
"SP500": 0.45519 
},
{
 "date": 8.9139e+08,
"SP500": 0.38736 
},
{
 "date": 8.9398e+08,
"SP500": 0.28592 
},
{
 "date": 8.9666e+08,
"SP500": 0.28097 
},
{
 "date": 8.9925e+08,
"SP500": 0.17432 
},
{
 "date": 9.0193e+08,
"SP500": 0.064271 
},
{
 "date": 9.0461e+08,
"SP500": 0.073611 
},
{
 "date": 9.072e+08,
"SP500": 0.20123 
},
{
 "date": 9.0988e+08,
"SP500": 0.21795 
},
{
 "date": 9.1247e+08,
"SP500": 0.26669 
},
{
 "date": 9.1515e+08,
"SP500": 0.30538 
},
{
 "date": 9.1783e+08,
"SP500": 0.1801 
},
{
 "date": 9.2025e+08,
"SP500": 0.16757 
},
{
 "date": 9.2292e+08,
"SP500": 0.20097 
},
{
 "date": 9.2552e+08,
"SP500": 0.19345 
},
{
 "date": 9.282e+08,
"SP500": 0.21067 
},
{
 "date": 9.3079e+08,
"SP500": 0.18565 
},
{
 "date": 9.3347e+08,
"SP500": 0.37934 
},
{
 "date": 9.3614e+08,
"SP500": 0.26126 
},
{
 "date": 9.3874e+08,
"SP500": 0.24053 
},
{
 "date": 9.4141e+08,
"SP500": 0.1936 
},
{
 "date": 9.4401e+08,
"SP500": 0.19526 
},
{
 "date": 9.4668e+08,
"SP500": 0.089728 
},
{
 "date": 9.4936e+08,
"SP500": 0.10344 
},
{
 "date": 9.5187e+08,
"SP500": 0.16497 
},
{
 "date": 9.5455e+08,
"SP500": 0.087816 
},
{
 "date": 9.5714e+08,
"SP500": 0.091225 
},
{
 "date": 9.5982e+08,
"SP500": 0.059656 
},
{
 "date": 9.6241e+08,
"SP500": 0.076848 
},
{
 "date": 9.6509e+08,
"SP500": 0.1494 
},
{
 "date": 9.6777e+08,
"SP500": 0.1199 
},
{
 "date": 9.7036e+08,
"SP500": 0.04877 
},
{
 "date": 9.7304e+08,
"SP500": -0.05325 
},
{
 "date": 9.7563e+08,
"SP500": -0.10139 
},
{
 "date": 9.7831e+08,
"SP500": -0.020402 
},
{
 "date": 9.8099e+08,
"SP500": -0.092563 
},
{
 "date": 9.834e+08,
"SP500": -0.22571 
},
{
 "date": 9.8608e+08,
"SP500": -0.13975 
},
{
 "date": 9.8868e+08,
"SP500": -0.11599 
},
{
 "date": 9.9135e+08,
"SP500": -0.15827 
},
{
 "date": 9.9395e+08,
"SP500": -0.15348 
},
{
 "date": 9.9662e+08,
"SP500": -0.25308 
},
{
 "date": 9.993e+08,
"SP500": -0.27537 
},
{
 "date": 1.0019e+09,
"SP500": -0.25858 
},
{
 "date": 1.0046e+09,
"SP500": -0.13347 
},
{
 "date": 1.0072e+09,
"SP500": -0.13043 
},
{
 "date": 1.0098e+09,
"SP500": -0.17263 
},
{
 "date": 1.0125e+09,
"SP500": -0.10743 
},
{
 "date": 1.0149e+09,
"SP500": -0.011152 
},
{
 "date": 1.0176e+09,
"SP500": -0.13809 
},
{
 "date": 1.0202e+09,
"SP500": -0.15024 
},
{
 "date": 1.0229e+09,
"SP500": -0.19157 
},
{
 "date": 1.0255e+09,
"SP500": -0.24736 
},
{
 "date": 1.0282e+09,
"SP500": -0.19188 
},
{
 "date": 1.0308e+09,
"SP500": -0.21678 
},
{
 "date": 1.0334e+09,
"SP500": -0.1642 
},
{
 "date": 1.0361e+09,
"SP500": -0.17828 
},
{
 "date": 1.0387e+09,
"SP500": -0.23366 
},
{
 "date": 1.0414e+09,
"SP500": -0.24288 
},
{
 "date": 1.0441e+09,
"SP500": -0.23997 
},
{
 "date": 1.0465e+09,
"SP500": -0.26077 
},
{
 "date": 1.0492e+09,
"SP500": -0.14857 
},
{
 "date": 1.0517e+09,
"SP500": -0.097035 
},
{
 "date": 1.0544e+09,
"SP500": -0.015478 
},
{
 "date": 1.057e+09,
"SP500": 0.086319 
},
{
 "date": 1.0597e+09,
"SP500": 0.10036 
},
{
 "date": 1.0624e+09,
"SP500": 0.22163 
},
{
 "date": 1.065e+09,
"SP500": 0.18622 
},
{
 "date": 1.0676e+09,
"SP500": 0.13018 
},
{
 "date": 1.0702e+09,
"SP500": 0.2638 
},
{
 "date": 1.0729e+09,
"SP500": 0.32188 
},
{
 "date": 1.0756e+09,
"SP500": 0.36116 
},
{
 "date": 1.0781e+09,
"SP500": 0.3278 
},
{
 "date": 1.0808e+09,
"SP500": 0.20763 
},
{
 "date": 1.0834e+09,
"SP500": 0.16303 
},
{
 "date": 1.086e+09,
"SP500": 0.17069 
},
{
 "date": 1.0886e+09,
"SP500": 0.1125 
},
{
 "date": 1.0913e+09,
"SP500": 0.095465 
},
{
 "date": 1.094e+09,
"SP500": 0.11909 
},
{
 "date": 1.0966e+09,
"SP500": 0.075654 
},
{
 "date": 1.0993e+09,
"SP500": 0.10926 
},
{
 "date": 1.1019e+09,
"SP500": 0.089935 
},
{
 "date": 1.1045e+09,
"SP500": 0.044327 
},
{
 "date": 1.1072e+09,
"SP500": 0.051234 
},
{
 "date": 1.1096e+09,
"SP500": 0.048286 
},
{
 "date": 1.1123e+09,
"SP500": 0.044748 
},
{
 "date": 1.1149e+09,
"SP500": 0.063194 
},
{
 "date": 1.1176e+09,
"SP500": 0.044257 
},
{
 "date": 1.1202e+09,
"SP500": 0.12023 
},
{
 "date": 1.1229e+09,
"SP500": 0.10513 
},
{
 "date": 1.1255e+09,
"SP500": 0.10249 
},
{
 "date": 1.1281e+09,
"SP500": 0.067961 
},
{
 "date": 1.1308e+09,
"SP500": 0.064456 
},
{
 "date": 1.1334e+09,
"SP500": 0.03001 
},
{
 "date": 1.1361e+09,
"SP500": 0.083647 
},
{
 "date": 1.1388e+09,
"SP500": 0.064025 
},
{
 "date": 1.1412e+09,
"SP500": 0.096799 
},
{
 "date": 1.1438e+09,
"SP500": 0.13291 
},
{
 "date": 1.1464e+09,
"SP500": 0.065959 
},
{
 "date": 1.1491e+09,
"SP500": 0.066203 
},
{
 "date": 1.1517e+09,
"SP500": 0.03442 
},
{
 "date": 1.1544e+09,
"SP500": 0.068416 
},
{
 "date": 1.1571e+09,
"SP500": 0.087109 
},
{
 "date": 1.1597e+09,
"SP500": 0.14161 
},
{
 "date": 1.1623e+09,
"SP500": 0.12097 
},
{
 "date": 1.1649e+09,
"SP500": 0.13619 
},
{
 "date": 1.1676e+09,
"SP500": 0.12355 
},
{
 "date": 1.1703e+09,
"SP500": 0.098512 
},
{
 "date": 1.1727e+09,
"SP500": 0.097299 
},
{
 "date": 1.1754e+09,
"SP500": 0.13105 
},
{
 "date": 1.178e+09,
"SP500": 0.20513 
},
{
 "date": 1.1807e+09,
"SP500": 0.18355 
},
{
 "date": 1.1832e+09,
"SP500": 0.1399 
},
{
 "date": 1.1859e+09,
"SP500": 0.13052 
},
{
 "date": 1.1886e+09,
"SP500": 0.14291 
},
{
 "date": 1.1912e+09,
"SP500": 0.12442 
},
{
 "date": 1.1939e+09,
"SP500": 0.057481 
},
{
 "date": 1.1965e+09,
"SP500": 0.035296 
},
{
 "date": 1.1991e+09,
"SP500": -0.041502 
},
{
 "date": 1.2018e+09,
"SP500": -0.054158 
},
{
 "date": 1.2043e+09,
"SP500": -0.069085 
},
{
 "date": 1.207e+09,
"SP500": -0.065287 
},
{
 "date": 1.2096e+09,
"SP500": -0.08509 
},
{
 "date": 1.2123e+09,
"SP500": -0.14857 
},
{
 "date": 1.2149e+09,
"SP500": -0.12911 
},
{
 "date": 1.2175e+09,
"SP500": -0.12969 
},
{
 "date": 1.2202e+09,
"SP500": -0.23605 
},
{
 "date": 1.2228e+09,
"SP500": -0.37475 
},
{
 "date": 1.2255e+09,
"SP500": -0.3949 
},
{
 "date": 1.2281e+09,
"SP500": -0.38486 
},
{
 "date": 1.2308e+09,
"SP500": -0.40091 
},
{
 "date": 1.2334e+09,
"SP500": -0.44756 
},
{
 "date": 1.2359e+09,
"SP500": -0.39679 
},
{
 "date": 1.2385e+09,
"SP500": -0.37008 
},
{
 "date": 1.2411e+09,
"SP500": -0.34365 
},
{
 "date": 1.2438e+09,
"SP500": -0.28178 
},
{
 "date": 1.2464e+09,
"SP500": -0.22085 
},
{
 "date": 1.2491e+09,
"SP500": -0.2044 
},
{
 "date": 1.2518e+09,
"SP500": -0.093693 
},
{
 "date": 1.2544e+09,
"SP500": 0.069615 
},
{
 "date": 1.257e+09,
"SP500": 0.22247 
},
{
 "date": 1.2596e+09,
"SP500": 0.23454 
},
{
 "date": 1.2623e+09,
"SP500": 0.30027 
},
{
 "date": 1.265e+09,
"SP500": 0.50252 
},
{
 "date": 1.2674e+09,
"SP500": 0.46569 
},
{
 "date": 1.2701e+09,
"SP500": 0.35962 
},
{
 "date": 1.2727e+09,
"SP500": 0.18525 
},
{
 "date": 1.2754e+09,
"SP500": 0.12117 
},
{
 "date": 1.2779e+09,
"SP500": 0.11557 
},
{
 "date": 1.2806e+09,
"SP500": 0.02813 
},
{
 "date": 1.2833e+09,
"SP500": 0.079578 
},
{
 "date": 1.2859e+09,
"SP500": 0.14193 
},
{
 "date": 1.2886e+09,
"SP500": 0.077508 
},
{
 "date": 1.2912e+09,
"SP500": 0.12783 
},
{
 "date": 1.2938e+09,
"SP500": 0.19765 
},
{
 "date": 1.2965e+09,
"SP500": 0.20166 
},
{
 "date": 1.2989e+09,
"SP500": 0.13374 
},
{
 "date": 1.3016e+09,
"SP500": 0.14909 
},
{
 "date": 1.3042e+09,
"SP500": 0.2348 
},
{
 "date": 1.3069e+09,
"SP500": 0.28129 
},
{
 "date": 1.3095e+09,
"SP500": 0.17309 
},
{
 "date": 1.3122e+09,
"SP500": 0.16159 
},
{
 "date": 1.3148e+09,
"SP500": -0.0085699 
},
{
 "date": 1.3174e+09,
"SP500": 0.059192 
},
{
 "date": 1.3201e+09,
"SP500": 0.056253 
},
{
 "date": 1.3227e+09,
"SP500": -3.1806e-05 
},
{
 "date": 1.3254e+09,
"SP500": 0.020441 
},
{
 "date": 1.3281e+09,
"SP500": 0.028978 
},
{
 "date": 1.3306e+09,
"SP500": 0.062331 
},
{
 "date": 1.3332e+09,
"SP500": 0.025154 
},
{
 "date": 1.3358e+09,
"SP500": -0.025922 
},
{
 "date": 1.3385e+09,
"SP500": 0.031439 
},
{
 "date": 1.3411e+09,
"SP500": 0.067354 
},
{
 "date": 1.3438e+09,
"SP500": 0.15398 
},
{
 "date": 1.3465e+09,
"SP500": 0.27333 
},
{
 "date": 1.349e+09,
"SP500": 0.12675 
},
{
 "date": 1.3517e+09,
"SP500": 0.13571 
},
{
 "date": 1.3543e+09,
"SP500": 0.13406 
},
{
 "date": 1.357e+09,
"SP500": 0.1415 
},
{
 "date": 1.3597e+09,
"SP500": 0.1091 
},
{
 "date": 1.3621e+09,
"SP500": 0.11411 
},
{
 "date": 1.3648e+09,
"SP500": 0.14283 
},
{
 "date": 1.3674e+09,
"SP500": 0.24453 
},
{
 "date": 1.37e+09,
"SP500": 0.17922 
},
{
 "date": 1.3726e+09,
"SP500": 0.19792 
} ],
"x": "date",
"y": "SP500" 
};

var svg = d3.select('#' + params.id).append("svg")
    .attr("width", params.width)
    .attr("height", params.height);
    
var chart = d3.horizon()
    .width(params.width)
    .height(params.height)
    .bands(params.bands)
    .mode(params.mode)
    .interpolate(params.interpolate);
    
data = [params.data.map(function(d) {return[d[params.x],d[params.y]]})]    
    
svg.data(data).call(chart)
</script>


---
### Thanks
As I hope you can tell, this post was more a function of the efforts of others than of my own.

Thanks specifically:
- Ramnath Vaidyanathan for [rCharts](http://rcharts.io/site) and [slidify](http://slidify.org).
- [Jason Davies](http://www.jasondavies.com/) for the [Horizon Chart d3 plugin](https://github.com/d3/d3-plugins/blob/master/horizon/horizon.js) and all his contributions and examples.
- [Mike Bostock](http://bost.ocks.org/mike/) for everything.
- Google fonts [Raleway](http://www.google.com/fonts/specimen/Raleway) and [Oxygen](http://www.google.com/fonts/specimen/Oxygen)
