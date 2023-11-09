#' Download data from the rasterbc collection
#'
#' Downloads all mapsheet layers (geoTIFFs) covering the geographical extent of \code{geo} for the
#' specified \code{collection}, \code{varname}, and \code{year}. Input \code{geo} can be a vector
#' of (4-character) NTS/SNRC mapsheet codes or a geometry of class \code{sfc}.
#'
#' The data files are written to the directory returned by \code{rasterbc::datadir_bc()}. Mapsheets
#' found there (already downloaded) are not downloaded again unless \code{force.dl==TRUE}. Users
#' should only need to download a mapsheet once - there are no plans to update the rasterbc
#' collection in the future.
#'
#' @param geo vector of character strings (NTS/SNRC codes) or a geometry of class \code{sfc}
#' @param collection character string indicating the data collection to query
#' @param varname character string indicating the layer to query
#' @param year integer indicating the year to query (if applicable)
#' @param force.dl logical indicating whether to overwrite any existing data
#' @param quiet logical, suppresses console messages
#'
#' @return a vector of character string(s) containing the absolute path(s) to the downloaded file(s)
#'
#' @seealso \code{\link{findblocks_bc}} to identify which mapsheets will be downloaded
#' @seealso \code{\link{listdata_bc}} for a list of available collections, variable names, years
#'
#' @importFrom utils download.file
#' @importFrom utils setTxtProgressBar
#' @importFrom utils txtProgressBar
#' @export
#' @examples
#' # define a location of interest, and a polygon around it then fetch the corresponding DEM data
#' input.point = sf::st_point(c(x=-120.1, y=50.1)) |> sf::st_sfc(crs='EPSG:4326')
#'
#' if( requireNamespace('units', quietly = TRUE) ) {
#' input.polygon = input.point |> sf::st_buffer(units::set_units(10, km))
#'
#' \dontrun{
#' # the following downloads data from FRDR
#' block.path = getdata_bc(input.point, 'dem')
#' getdata_bc(input.polygon, 'dem')
#'
#' # load one of the mapsheets
#' terra::rast(block.path)
#' }
#' }
getdata_bc = function(geo=NULL, collection=NULL, varname=NULL, year=NULL, force.dl=FALSE, quiet=FALSE)
{
  # get the data storage directory or prompt to create one if it doesn't exist yet
  data.dir = datadir_bc(quiet=TRUE)
  if( is.null(data.dir) ) data.dir = datadir_bc(NA)

  # find the required mapsheet codes and files
  geo.codes = findblocks_bc(geo)
  listfiles.out = listfiles_bc(collection, varname, year)

  # unpack listfiles.out and update input arguments (possibly modified by listfiles_bc)
  collection = listfiles.out$collection
  varname = listfiles.out$varname
  fnames = listfiles.out$filenames
  is.timeseries = listfiles.out$is.timeseries

  # find the index of the particular blocks needed
  idx.geo = names(fnames) %in% geo.codes

  # build the full list of urls for this collection/varname/year and their local paths
  urls = paste0(rasterbc::metadata_bc[[collection]]$frdr, fnames)
  dest.files = file.path(data.dir, fnames)

  # check to see which (if any) of these blocks have been downloaded already
  dl.success = TRUE
  idx.exists = listdata_bc(collection=collection, varname=varname, year=year, simple=TRUE)[idx.geo]
  if(any(!idx.exists))
  {
    # some blocks are missing. Print a message before downloading them
    msg.action = paste0('downloading ', sum(!idx.exists), ' block(s) to: ', data.dir, '/', collection)
    msg.struct = paste0('[', collection, ']:[', varname, ']')
    if( is.timeseries ) msg.struct = paste0('[', year, ']:', msg.struct)
    if( !quiet ) cat(paste(msg.struct, msg.action, '\n'))

    # create subdirectories of data.dir differently for time series data
    dpath = file.path(data.dir, collection, 'blocks')
    if( !is.timeseries ) { suppressWarnings(dir.create(dpath, recursive=TRUE)) } else {
      suppressWarnings(dir.create(file.path(dpath, year), recursive=TRUE))
    }

    # download the blocks in a loop with a progress bar printout
    if(!quiet) pb = txtProgressBar(min=0, max=sum(!idx.exists), style=3)
    for(idx.queue in 1:sum(!idx.exists))
    {
      # index of url to try and some console messages
      idx.todl = which(idx.geo)[idx.queue]
      if(!quiet)
      {
        setTxtProgressBar(pb, idx.queue)
        cat(paste('\ndownloading to:', fnames[idx.todl], '\n'))
      }

      # print failed URL in case of download errors
      dl.result = tryCatch(
        expr = { download.file(urls[idx.todl], dest.files[idx.todl], mode='wb', quiet=quiet) },
        error = function(cond) {
          message(paste0('download failed for URL: ', urls[idx.todl]))
          message('Try downloading the file to your local data directory using a web browser.')
          message(paste('original error message:', cond))
          }
        )

      # flag for download errors
      if( is.null(dl.result) ) dl.success = FALSE
    }
    if(!quiet) close(pb)

  } else {

    # print a message when no downloads are necessary
    cat(paste('all', sum(idx.geo), 'block(s) found in local data storage. Nothing to download\n'))
  }

  # default behaviour: return the vector of file paths
  return(dest.files[idx.geo])
}
