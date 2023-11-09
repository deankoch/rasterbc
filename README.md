The rasterbc R Package
================
Dean Koch
2023-11-09

<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- badges: start -->
<!-- badges: end -->

`rasterbc` provides access to a collection of 100m resolution gridded
spatial ecological data on the province of British Columbia during the
period 2001-2018, including yearly rasterized Forest Insect and Disease
Survey (FIDS) pest damage polygons. Given a user-defined geographical
region (polygon), the package downloads and imports requested data
layers into R as SpatRaster objects. The goal is to improve access to a
number of publicly accessible datasets on BC forests and simplify data
ingress for modellers.

The available layers are:

- [BC biogeoclimatic
  zone](https://github.com/deankoch/rasterbc_src/blob/master/src_bgcz.knit.md)
  (‘bgcz’), from the [BC Ministry of
  Forests](https://catalogue.data.gov.bc.ca/dataset/f358a53b-ffde-4830-a325-a5a03ff672c3)
- [Geographical coordinates
  grid](https://github.com/deankoch/rasterbc_src/blob/master/src_borders.knit.md)
  (‘borders’), from [Natural Resources
  Canada](https://natural-resources.canada.ca/maps-tools-and-publications/maps/topographic-maps/10995)
- [Consolidated cutblocks,
  2001-2018](https://github.com/deankoch/rasterbc_src/blob/master/src_cutblocks.knit.md)
  (‘cutblocks’), from the [BC Ministry of
  Forests](https://catalogue.data.gov.bc.ca/dataset/harvested-areas-of-bc-consolidated-cutblocks-)
- [Digital elevation
  model](https://github.com/deankoch/rasterbc_src/blob/master/src_dem.knit.md)
  (‘dem’) from [Natural Resources
  Canada](https://ftp.maps.canada.ca/pub/nrcan_rncan/elevation/cdem_mnec/doc/CDEM_en.pdf)
- [Forest insect and disease survey,
  2001-2018](https://github.com/deankoch/rasterbc_src/blob/master/src_fids.knit.md)
  (‘fids’), from the [BC Ministry of
  Forests](https://catalogue.data.gov.bc.ca/dataset/pest-infestation-polygons)
- [Forest extent and change,
  2001-2019](https://github.com/deankoch/rasterbc_src/blob/master/src_gfc.knit.md)
  (‘gfc’), from [Hansen et al.,
  (2013)](http://earthenginepartners.appspot.com/science-2013-global-forest)
- [Canadian national fire database,
  2001-2018](https://github.com/deankoch/rasterbc_src/blob/master/src_nfdb.knit.md)
  (‘nfdb’), from [Natural Resources
  Canada](https://cwfis.cfs.nrcan.gc.ca/ha/nfdb)
- [Interpolated forest attributes, 2001,
  2011](https://github.com/deankoch/rasterbc_src/blob/master/src_pine.knit.md)
  (‘pine’) from [Beaudoin et
  al. (2017)](https://doi.org/10.1139/cjfr-2017-0184)

All datasets were downloaded and processed in the years 2018-2020, then
stored as raster tiles in the standard [BC
Albers](https://spatialreference.org/ref/epsg/nad83-bc-albers/)
projection, and hosted on [FRDR](https://www.frdr-dfdr.ca/repo/). Follow
the links in the list above for code and documentation on this process.
The collection is published as a [data
publication](https://doi.org/10.20383/101.0283) for permanence and easy
referencing.

## Vignette

See the [introduction
vignette](https://github.com/deankoch/rasterbc/blob/master/vignettes/vignette_intro.md)
for instructions on getting started with this package.

<img src="https://raw.githubusercontent.com/deankoch/rasterbc/master/vignettes/vignette_intro_okanagan_location-1.png" width="30%"></img>
<img src="https://raw.githubusercontent.com/deankoch/rasterbc/master/vignettes/vignette_intro_okanagan_elevation_tiles-1.png" width="30%"></img>
<img src="https://raw.githubusercontent.com/deankoch/rasterbc/master/vignettes/vignette_intro_okanagan_bgcz-1.png" width="30%"></img>

## Releases

`rasterbc` is available on CRAN:

[rasterbc v1.0.2](https://CRAN.R-project.org/package=rasterbc)

[![](https://cranlogs.r-pkg.org/badges/rasterbc)](https://cran.r-project.org/package=rasterbc)

Install it in R using the command

``` r
install.packages('rasterbc')
```

This will also install the dependencies `sf` and `terra`, if you don’t
have them already.

Note that FRDR’s direct download services may occasionally be
unavailable, during which the download functionality of rasterbc will
also be unavailable. If you are having trouble downloading data tiles
with rasterbc, first check [the FRDR
homepage](https://www.frdr-dfdr.ca/repo/) for news about maintenance
downtime.

## About

This project grew out of my [doctoral thesis
project](https://doi.org/10.7939/r3-91zn-v276) on modelling outbreaks of
the mountain pine beetle in central BC. Parts of of the `rasterbc`
collection can be found in research publications with professors Mark
Lewis and Subhash Lele on [statistical methods for spatial
data](https://doi.org/10.7939/r3-g6qb-bq70), [models for animal
dispersal](https://doi.org/10.1098/rsif.2020.0434), and [an analysis of
MPB activity in the Merrit
TSA](https://doi.org/10.1007/s11538-021-00899-z). We gratefully
acknowledge the support of NSERC, TRIA-Net, and the University of
Alberta Lewis Lab in this work.

<!-- README.md is generated from README.Rmd. Please edit that file -->
<!-- rmarkdown::render('README.Rmd') -->
