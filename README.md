
<!-- README.md is generated from README.Rmd. Please edit that file -->

# rasterbc

<!-- badges: start -->

<!-- badges: end -->

rasterbc provides a simple set of helper functions for accessing a large
set of spatial ecological data on the province of BC during the period
2001-2018, in raster format.

Links to metadata associated with these layers, and code for downloading
them from their original sources can be found in a sister repository,
[rasterbc\_src](https://github.com/deankoch/rasterbc_src), and all
raster data files will be hosted as a data publication (with associated
DOI) on [FRDR](https://www.frdr-dfdr.ca/repo/) for permanence and easy
referencing.

## Installation

This package is still in development, but a release on
[CRAN](https://CRAN.R-project.org) is planned in the near future. For
now the package may be tested by installing the `devtools` package (run
`install.packages('devtools')`), and running the following two lines:

``` r
library(devtools)
install_github('deankoch/rasterbc')
```

## Basic usage

`rasterbc` is a data-retrieval tool. Start by setting a storage
directory for the raster layers:

``` r
library(rasterbc)
datadir_bc(select=TRUE, 'H:/rasterbc_data')
#> [1] "data storage path set to: H:/rasterbc_data"
#> [1] "directory exists"
#> [1] "H:/rasterbc_data"
```

Depending on the geographical extent of interest and the number
different layers requested, the cumulative filesize of the downloaded
data can be quite large. For example, if every layer is downloaded, then
around 30 GB of space is needed. Make sure you have selected a drive
with enough free space for your project.

To demonstrate this package we’ll need a polygon covering a (relatively)
small geographical extent in BC. Start by loading the `bcmaps` package
and grabbing the polygons for the BC provincial boundary and the Central
Okanagan Regional District

``` r
library(bcmaps)
example.name = 'Regional District of Central Okanagan'
bc.bound.sf = bc_bound()
districts.sf = regional_districts()
example.sf = districts.sf[districts.sf$ADMIN_AREA_NAME==example.name, ]
```

Any sfc class object could be used here, provided its geometry
intersects with the provincial boundary of BC. The idea is that the user
specifes their study area, and rasterbc downloads only the required
data, avoiding cumbersome and memory-intensive intermediate steps
involving large rasters.

Have a look at where the selected district lies in the province, with
reference to the NTS/SNRC grid (sf object `NTS.polygons`, which is
lazy-loaded with this package): You can Use `st_geometry` to drop the
feature columns from the `sf` objects and keep only the geometries,
which helps to de-clutter plots whenever you’re just interested in the
location(s) of something, and not the attributes attached to those
locations.

``` r
plot(st_geometry(NTS.polygons), main=example.name, border='red')
plot(st_geometry(bc.bound.sf), add=TRUE, col=adjustcolor('blue', alpha.f=0.2))
plot(st_geometry(example.sf), add=TRUE, col=adjustcolor('yellow', alpha.f=0.5))
```

<img src="man/figures/README-plot-example-1.png" width="100%" />

<!-- README.md is generated from README.Rmd. Please edit that file -->

rmarkdown::render(‘README.Rmd’)
