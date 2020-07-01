#' Download multiple blocks, and (optionally) merge/clip/mask them
#'
#' Downloads and/or loads all blocks covering the geographical extent specified in input argument `geo`. This can be a vector of
#' (4-character) NTS/SNRC block codes, or any geometry set of type `sfc`.
#'
#' Data for the layer specified by `collection`, `varname`,
#' and `year` are written to the directory specified by `rasterbc::datadir_bc`, and blocks already downloaded are not downloaded
#' again (unless `force.dl==TRUE`).
#'
#' Note that if no extent object (`geo`) is supplied, then all required blocks are downloaded. Missing arguments to `collection`,
#' `varname`, and `year` will prompt the function to download ALL corresponding layers. eg. getdata_bc('dem') will
#' download all three layers (`dem`, `aspect`, `slope`) in the `dem` collection; and getdata_bc('fids', year=2012) will download
#' 'fids' layers from the year 2012.
#'
#' @param geo vector of character strings (NTS/SNRC codes) or any geometry set of type sfc
#' @param collection character string, indicating the data collection to query
#' @param varname character string, indicating the layer to query
#' @param year integer, indicating the year to query
#' @param force.dl boolean, indicates to download (and overwrite) any existing data
#'
#' @return A character string (or vector of them) containing the absolute path(s) to the file(s) written
#' @importFrom methods as
#' @importFrom utils download.file
#' @importFrom utils setTxtProgressBar
#' @importFrom utils txtProgressBar
#' @export
getdata_bc = function(geo=NULL, collection=NULL, varname=NULL, year=NULL, force.dl=FALSE)
{
  # get the data storage directory...
  data.dir = getOption('rasterbc.data.dir')
  if(is.null(data.dir))
  {
    # ... or prompt to create one if it doesn't exist yet
    stop('Data directory undefined. Set it using raster::datadir_bc()')
  }

  # check that geo is valid, replace (as needed)with the required mapsheet codes
  is.poly = FALSE
  if(is.character(geo))
  {
    # compare with list of BC codes
    idx.valid = geo %in% rasterbc::ntspoly_bc$NTS_SNRC
    if(!all(idx.valid))
    {
      stop(paste('found no match in BC for the following NTS/SNRC code(s):', paste(geo[!idx.valid], collapse=', ')))
    }

  } else {

    if(any(c('sf', 'sfc') %in% class(geo)))
    {
      # for simple features, retain only the geometry
      geo = sf::st_geometry(geo)
      if(sf::st_geometry_type(geo) %in% c('POLYGON', 'MULTIPOLYGON'))
      {
        # this will later allow load.mode 'clip' and 'mask' to proceed
        is.poly = TRUE
      }

      # find the mapsheet codes, overwrite geo but keep a backup
      geo.input = geo
      geo = findblocks_bc(geo)

    } else {

      # unrecognize input type:
      stop('geo must of type sf, sfc, or character (vector of NTS/SNRC codes)')
    }
  }

  # find the index of the particular blocks needed
  idx.geo = names(rasterbc::metadata_bc[[collection]]$fname$block[[varname]]) %in% geo

  # build the full list of blocks available to download
  fnames = rasterbc::metadata_bc[[collection]]$fname$block[[varname]]
  urls = paste0(rasterbc::metadata_bc[[collection]]$frdr, fnames)
  dest.files = file.path(data.dir, collection, fnames)

  # check to see which (if any) of these blocks have been downloaded already
  idx.exists = listdata_bc(collection=collection, varname=varname, year=year, verbose=0)[idx.geo]
  if(any(!idx.exists))
  {
    # some blocks are missing. Print a message before downloading them
    printout.prefix = paste0('[', collection, ']:[', varname, ']')
    if(!is.null(year))
    {
      printout.prefix = paste0('[', year, ']:', printout.prefix)
    }
    printout.suffix = paste0('downloading ', sum(!idx.exists), ' block(s) to: ', data.dir, '/', collection)
    print(paste(printout.prefix, printout.suffix))

    # create subdirectories of data.dir as needed
    suppressWarnings(dir.create(file.path(data.dir, collection, 'blocks'), recursive=TRUE))

    # download the blocks in a loop with a progress bar printout
    pb = txtProgressBar(min=0, max=sum(!idx.exists), style=3)
    for(idx.queue in 1:sum(!idx.exists))
    {
      setTxtProgressBar(pb, idx.queue)
      idx.todownload = which(idx.geo)[idx.queue]
      print(paste(' writing to:', fnames[idx.todownload]))
      download.file(urls[idx.todownload], dest.files[idx.todownload], mode='wb')
    }
    close(pb)

  } else {

    # print a message when no downloads are necessary
    print(paste('all', sum(idx.geo), 'block(s) found in local data storage. Nothing to download'))

  }

  return(dest.files[idx.geo])
}
