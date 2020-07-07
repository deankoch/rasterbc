#' ---
#' title: "demo.R"
#' author: "Dean Koch"
#' date: "June 19, 2020"
#' output: github_document
#' ---
#'
#' **Development version**: testing R code for fetching/caching/loading mapsheets

library(raster)
library(bcmaps)

library(devtools)
load_all()
datadir_bc(select=TRUE, 'H:/rasterbc_data')

example.name = 'Regional District of Central Okanagan'
bc.bound.sf = bc_bound()
districts.sf = regional_districts()
example.sf = districts.sf[districts.sf$ADMIN_AREA_NAME==example.name, ]

x = listdata_bc()

collection = 'dem'
varname = 'aspect'
z = listdata_bc(collection)
y = listdata_bc(collection, varname)
getdata_bc(geo=example.sf, collection, varname)
geotest = opendata_bc(geo=example.sf, collection, varname)
plot(geotest)


z = listdata_bc('bgcz', verbose=2)


collection = 'fids'
varname = 'IBM_mid'
year = 2018
z = listdata_bc(collection)
y = listdata_bc(collection, varname)
x = listdata_bc(collection, varname, c(2017,2018))
getdata_bc(geo=example.sf, collection, varname, year)
geotest = opendata_bc(geo=example.sf, collection, varname, year)
plot(geotest)

collection = 'bgcz'
varname = 'zone'
year = 2011
z = listdata_bc(collection)
y = listdata_bc(collection, varname)
x = listdata_bc(collection, varname, year)
getdata_bc(geo=example.sf, collection, varname, year)
geotest = opendata_bc(geo=example.sf, collection, varname, year)
plot(geotest)

collection = 'gfc'
varname = 'treecover'
z = listdata_bc(collection)
y = listdata_bc(collection, varname)
getdata_bc(geo=example.sf, collection, varname)
geotest = opendata_bc(geo=example.sf, collection, varname)
plot(geotest)


collection = 'gfc'
varname = 'loss'
year = 2019
z = listdata_bc(collection)
y = listdata_bc(collection, varname)
getdata_bc(geo=example.sf, collection, varname, year)
geotest = opendata_bc(geo=example.sf, collection, varname, year)
plot(geotest)


#+ include=FALSE
# Convert to markdown by running the following line (uncommented)...
# rmarkdown::render(here('demo.R'), run_pandoc=FALSE, clean=TRUE)
# ... or to html ...
# rmarkdown::render(here('demo.R'))
