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
datadir_bc('H:/rasterbc_data', TRUE)

example.name = 'Regional District of Central Okanagan'
bc.bound.sf = bc_bound()
districts.sf = regional_districts()
example.sf = districts.sf[districts.sf$ADMIN_AREA_NAME==example.name, ]

listdata_bc(verbose=0)
listdata_bc(verbose=1)
listdata_bc(verbose=2)

collection = 'dem'
varname = 'dem'
listdata_bc(collection)
listdata_bc(collection, verbose=0)
listdata_bc(collection, verbose=2)
listdata_bc(collection, varname)

geotest = getdata_bc(geo=example.sf, collection, varname)
plot(geotest, col=rainbow(255))


listdata_bc('bgcz', verbose=2)


collection = 'fids'
varname = 'IBM_max'
year = 2008
listdata_bc(collection, verbose=2)
listdata_bc(collection, varname)
listdata_bc(collection, varname, year, verbose=2)

listdata_bc(collection, verbose=0)
listdata_bc(collection, varname)
listdata_bc(collection, varname, year)

getdata_bc(geo=example.sf, collection, varname, year)
geotest = opendata_bc(geo=example.sf, collection, varname, year)
plot(geotest)

collection = 'bgcz'
varname = 'zone'
year = 2011
listdata_bc(collection)
listdata_bc(collection, varname)
listdata_bc(collection, varname, year)
getdata_bc(geo=example.sf, collection, varname, year)
geotest = opendata_bc(geo=example.sf, collection, varname, year)
plot(geotest)

collection = 'gfc'
varname = 'treecover'
listdata_bc(collection)
listdata_bc(collection, verbose=2)
listdata_bc(collection, varname)
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

example.blockcodes = c('092B', '092C')
example.tif = getdata_bc(example.blockcodes, collection='dem', varname='slope')
plot(example.tif)


#+ include=FALSE
# Convert to markdown by running the following line (uncommented)...
# rmarkdown::render(here('demo.R'), run_pandoc=FALSE, clean=TRUE)
# ... or to html ...
# rmarkdown::render(here('demo.R'))
