#' Download multiple blocks, and (optionally) merge/clip/mask them
#'
#' Downloads and/or loads all blocks covering the geographical extent specified in input argument `geo`. This can be a vector of
#' (4-character) NTS/SNRC block codes, or any geometry set of type `sfc`.
#'
#' Data for the layer specified by `collection`, `varname`, and `year` are written to the directory specified by `rasterbc::datadir_bc`,
#' and blocks already downloaded are not downloaded again (unless `force.dl==TRUE`). Default behaviour is to merge blocks as needed
#' to construct a raster containing the requested data, returning it as a RasterLayer. If `load.mosaic==FALSE`, the function downloads
#' any missing blocks (as needed), returning their filenames instead of loading them.
#'
#' @param geo A vector of (NTS/SNRC code) strings, or any geometry set of type sfc, specifying geographical extent to load
#' @param collection A character string indicating the data collection to query
#' @param varname A character string indicating the layer to query
#' @param year An integer indicating the year to query (if applicable)
#' @param force.dl A boolean indicating whether to overwrite any existing data
#' @param load.mosaic A boolean indicating whether to return the full (merged) raster
#' @param quiet logical, suppresses console messages
#'
#' @return Either: a (vector of) character string(s) containing the absolute path(s) to the file(s) written (default); or a
#' RasterLayer object containing the requested data
#' @importFrom methods as
#' @importFrom utils download.file
#' @importFrom utils setTxtProgressBar
#' @importFrom utils txtProgressBar
#' @export
getdata_bc = function(geo=NULL, collection=NULL, varname=NULL, year=NULL, force.dl=FALSE, load.mosaic=TRUE, quiet=FALSE)
{
  # get the data storage directory or prompt to create one if it doesn't exist yet
  data.dir = datadir_bc(quiet=TRUE)
  if(is.null(data.dir)) data.dir = datadir_bc(NA)

  # check that geo is valid, replace (as needed) with the required mapsheet codes
  is.poly = FALSE
  if(is.character(geo))
  {
    # compare with list of BC codes and stop if any are misspelled
    idx.valid = geo %in% rasterbc::ntspoly_bc$NTS_SNRC
    if(!all(idx.valid))
    {
      msg.invalid = 'found no match in BC for the following NTS/SNRC code(s):'
      stop(paste(msg.invalid, paste(geo[!idx.valid], collapse=', ')))
    }

    # codes are verified, save a copy in a new object
    geo.codes = geo

  } else {

    if(any(c('sf', 'sfc') %in% class(geo)))
    {
      # for simple features, retain only the geometry and merge multiple polygons into one
      geo = sf::st_geometry(geo) |> sf::st_union()
      is.poly = sf::st_geometry_type(geo) %in% c('POLYGON', 'MULTIPOLYGON')

      # transform to BC Albers projection
      geo = sf::st_transform(geo, crs='EPSG:3005')

      # find the mapsheet codes
      geo.codes = findblocks_bc(geo)

    } else {

      # unrecognized input type:
      stop('geo must of type sf, sfc, or character (vector of NTS/SNRC codes)')
    }
  }

  # handle empty collection argument
  if(is.null(collection))
  {
    # printout of collection and variables names
    if(!quiet) cat('no collection specified. Returning list of collection names\n')
    return(listdata_bc(verbose=0))
  }

  # build a list of filenames available to download for this collection/varname/year
  if(all(is.na(rasterbc::metadata_bc[[collection]]$metadata$year[[varname]])))
  {
    # case: data are one-time, not time series
    fnames = rasterbc::metadata_bc[[collection]]$fname$block[[varname]]

  } else {

    # case: data are from time-series. Check for year argument
    if(is.null(year))
    {
      err.msg.line1 = paste0('Variable \"', varname, '\" from collection \"', collection, '\" requires a year argument')
      err.msg.line2 = paste0('Please specify one of the years: ', rasterbc::metadata_bc[[collection]]$metadata$df[varname, 'year'])
      stop(paste(c(err.msg.line1, err.msg.line2), collapse='\n'))
    }

    year.string = paste0('yr', year)
    fnames = rasterbc::metadata_bc[[collection]]$fname$block[[year.string]][[varname]]
  }

  # catch invalid requests (no matching files)
  if(is.null(fnames))
  {
    # prompt an informative warning then stop with an error
    listdata_bc(collection=collection, varname=varname, year=year, simple=TRUE)
    stop('no files matching request. Check arguments and see ?listdata_bc')
  }

  # find the index of the particular blocks needed
  idx.geo = names(fnames) %in% geo.codes

  # build the full list of urls for this collection/varname/year and their local paths
  urls = paste0(rasterbc::metadata_bc[[collection]]$frdr, fnames)
  dest.files = file.path(data.dir, fnames)

  # check to see which (if any) of these blocks have been downloaded already
  download.success = TRUE
  idx.exists = listdata_bc(collection=collection, varname=varname, year=year, simple=TRUE)[idx.geo]
  if(any(!idx.exists))
  {
    # some blocks are missing. Print a message before downloading them
    printout.prefix = paste0('[', collection, ']:[', varname, ']')
    if(!is.null(year))
    {
      printout.prefix = paste0('[', year, ']:', printout.prefix)
    }
    printout.suffix = paste0('downloading ', sum(!idx.exists), ' block(s) to: ', data.dir, '/', collection)
    if(!quiet) cat(paste(printout.prefix, printout.suffix, '\n'))

    # create subdirectories of data.dir as needed
    if(all(is.na(rasterbc::metadata_bc[[collection]]$metadata$year[[varname]])))
    {
      # case: data are one-time, not time series
      suppressWarnings(dir.create(file.path(data.dir, collection, 'blocks'), recursive=TRUE))

    } else {

      # case: data are from time-series
      suppressWarnings(dir.create(file.path(data.dir, collection, 'blocks', year), recursive=TRUE))
    }

    # download the blocks in a loop with a progress bar printout
    if(!quiet) pb = txtProgressBar(min=0, max=sum(!idx.exists), style=3)
    for(idx.queue in 1:sum(!idx.exists))
    {
      # index of url to try and some console messages
      idx.todownload = which(idx.geo)[idx.queue]
      if(!quiet)
      {
        setTxtProgressBar(pb, idx.queue)
        cat(paste('\ndownloading to:', fnames[idx.todownload], '\n'))
      }

      # print failed URL in case of download errors
      download.result = tryCatch(
        expr = { download.file(urls[idx.todownload], dest.files[idx.todownload], mode='wb', quiet=quiet) },
        error = function(cond) {
          message(paste0('download failed for URL: ', urls[idx.todownload]))
          message('Try calling the function again, or download the file to your local data directory using a web browser.')
          message(paste('original error message:', cond))
          }
        )

      # flag for download errors
      if( is.null(download.result) ) download.success = FALSE
    }
    if(!quiet) close(pb)

  } else {

    # print a message when no downloads are necessary
    cat(paste('all', sum(idx.geo), 'block(s) found in local data storage. Nothing to download\n'))
  }

  # mosaic mode: merge blocks, clip/mask as needed, and return RasterLayer in memory
  if(load.mosaic & download.success) return(opendata_bc(geo, collection, varname, year, quiet=quiet))

  # default behaviour: return the vector of file paths
  return(dest.files[idx.geo])
}
