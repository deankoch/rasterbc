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
#' This file contains a summary of metadata about the available datasets in rasterbc. The script ('metadata.R') used to
#' generate this file can be found in the subdirectory rasterbc/data-raw/ (updated November 23, 2021).
#'
#' Relevant contents of the file can be accessed dataframe using the function listdata_bc.
#'
#' The rasterbc collection is published as \href{https://www.frdr-dfdr.ca/repo/handle/doi:10.20383/101.0283}{a data publication}
#' with associated \href{https://doi.org/10.20383/101.0283}{DOI} for permanence and easy referencing. For a more complete
#' description, along with instructions on downloading the collections from their sources and reproducing the collection,
#' see the \href{https://github.com/deankoch/rasterbc_src}{rasterbc_src} github repository.
#'
#' All were downloaded from sources and processed in the years 2018-2020, then stored as raster tiles in the standard
#' \href{https://spatialreference.org/ref/epsg/nad83-bc-albers/}{BC Albers} projection, and hosted on
#' \href{https://www.frdr-dfdr.ca/repo/}{FRDR}.
#'
#' @format Nested list containing metadata and URLs for all of the files available as rasterbc collections
#' \describe{
#'   \item{bgcz}{\href{https://github.com/deankoch/rasterbc_src/blob/master/src_bgcz.knit.md}{BC biogeoclimatic zone} from BC Ministry of Forests}
#'   \item{borders}{\href{https://github.com/deankoch/rasterbc_src/blob/master/src_borders.knit.md}{Geographical coordinates grid} from Natural Resources Canada}
#'   \item{cutblocks}{\href{https://github.com/deankoch/rasterbc_src/blob/master/src_cutblocks.knit.md}{Consolidated cutblocks}, 2001-2018, from BC Ministry of Forests}
#'   \item{dem}{\href{https://github.com/deankoch/rasterbc_src/blob/master/src_dem.knit.md}{Digital elevation model} from Natural Resources Canada}
#'   \item{fids}{\href{https://github.com/deankoch/rasterbc_src/blob/master/src_fids.knit.md}{Forest insect and disease survey}, 2001-2018, from BC Ministry of Forests}
#'   \item{gfc}{\href{https://github.com/deankoch/rasterbc_src/blob/master/src_gfc.knit.md}{Forest extent and change}, 2001-2019 from Hansen et al. \href{https://www.nrcresearchpress.com/doi/full/10.1139/cjfr-2013-0401}{(2013)}}
#'   \item{nfdb}{\href{https://github.com/deankoch/rasterbc_src/blob/master/src_nfdb.knit.md}{Canadian national fire database}, 2001-2018, from Natural Resources Canada}
#'   \item{pine}{\href{https://github.com/deankoch/rasterbc_src/blob/master/src_pine.knit.md}{Interpolated forest attributes}, 2001, 2011, from Beaudoin et al. \href{https://www.nrcresearchpress.com/doi/full/10.1139/cjfr-2017-0184}{(2017)}}
#' }
#' @source Original data sources were published by the Canadian Journal of Forest Research and various Canadian government environment ministries, and are described in full at \href{https://github.com/deankoch/rasterbc_src}{rasterbc_src}
'metadata_bc'
