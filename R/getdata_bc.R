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
#'
#' @return Either: a (vector of) character string(s) containing the absolute path(s) to the file(s) written (default); or a
#' RasterLayer object containing the requested data
#' @importFrom methods as
#' @importFrom utils download.file
#' @importFrom utils setTxtProgressBar
#' @importFrom utils txtProgressBar
#' @export
getdata_bc = function(geo=NULL, collection=NULL, varname=NULL, year=NULL, force.dl=FALSE, load.mosaic=TRUE)
{
  # May add this later:
  # If no extent object (`geo`) is supplied, then all required blocks are downloaded. Missing arguments to `collection`,
  # `varname`, and `year` will prompt the function to download ALL corresponding layers. eg. getdata_bc('dem') will
  # download all three layers (`dem`, `aspect`, `slope`) in the `dem` collection; and getdata_bc('fids', year=2012) will download
  # 'fids' layers from the year 2012.
  #

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
      stop(paste('found no match in BC for the following NTS/SNRC code(s):', paste(geo[!idx.valid], collapse=', ')))
    }

    # codes are verified, save a copy in a new object
    geo.codes = geo

  } else {

    if(any(c('sf', 'sfc') %in% class(geo)))
    {
      # for simple features, retain only the geometry and merge multiple polygons into one
      geo = sf::st_geometry(geo) |> sf::st_union()
      if(sf::st_geometry_type(geo) %in% c('POLYGON', 'MULTIPOLYGON'))
      {
        # this will later allow load.mode 'clip' and 'mask' to proceed
        is.poly = TRUE
      }

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
    listdata_bc(verbose=0)
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

  # find the index of the particular blocks needed
  idx.geo = names(fnames) %in% geo.codes

  # build the full list of urls for this collection/varname/year and their local paths
  urls = paste0(rasterbc::metadata_bc[[collection]]$frdr, fnames)
  dest.files = file.path(data.dir, fnames)

  # check to see which (if any) of these blocks have been downloaded already
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
    print(paste(printout.prefix, printout.suffix))

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

  if(load.mosaic)
  {
    # merge blocks, clip/mask as needed, and return RasterLayer pointing to a tempfile
    return(opendata_bc(geo, collection, varname, year))

  } else {

    # default behaviour: return the vector of file paths
    return(dest.files[idx.geo])

  }
}
