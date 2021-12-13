#' National Topographic System Index Maps for British Columbia.
#'
#' Mapsheet boundary polygons for 1:250,000 scale maps, from Natural Resources Canada. The
#' \href{https://open.canada.ca/en/open-government-licence-canada}{Open Government License - Canada} applies.
#' More info \href{https://www.nrcan.gc.ca/earth-sciences/geography/topographic-information/maps/9765}{available here}
#'
#' @format Simple feature collection (of type POLYGON), with 89 features and 1 field:
#' \describe{
#'   \item{NTS_SNRC}{four-character mapsheet code}
#' }
#' @source Reproduced (in NAD83 / BC Albers projection) from the shapefile 'nts_snrc_250k.shp' in the zip archive 'nts_snrc.zip'
#' available from \href{http://ftp.geogratis.gc.ca/pub/nrcan_rncan/vector/index/}{http://geogratis.gc.ca/} (accessed June 11, 2020).
'ntspoly_bc'

#' Metadata for rasterbc collections
#'
#' This will soon be filled in with a shortened version of the info available at the
#' \href{https://github.com/deankoch/rasterbc_src}{rasterbc_src} github repository. The script ('metadata.R')
#' used to generate this file can be found in the rasterbc/data-raw/ subdirectory (updated November 23, 2021).
#'
#' @format Nested list containing metadata and URLs for all of the files available through rasterbc
#' \describe{
#'   \item{dem}{Digital Elevation Model data from Natural Resources Canada}
#' }
#' @source Various Canadian government environment ministries
'metadata_bc'
