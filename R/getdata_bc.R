#' Download multiple blocks, and (optionally) merge/clip/mask them
#'
#' Downloads and/or loads all blocks covering the geographical extent specified in input argument `geo`. This can be a vector of
#' (4-character) NTS/SNRC block codes, or any geometry set of type `sfc`.
#'
#' Data for the layer specified by `collection`, `varname`,
#' and `year` are written to the directory specified by `rasterbc::datadir_bc`, and blocks already downloaded are not downloaded
#' again (unless `force.dl==TRUE`).
#'
#' Argument `load.mode` specifies whether/how the blocks should be loaded into memory. 'noload' only downloads the blocks, but
#' does not load them (returning NULL); The others return a rasterLayer: 'all' uses `gdalUtils::gdal_mosaic` to merge the blocks
#' into a larger rasterLayer, covering all (and likely more) of the input extent; 'clip' and 'mask' (the default) assume that `geo`
#' is a (multi)polygon, cropping the merged blocks to its boundary; and  with 'mask', all data not inside the polygon is set to NA.
#'
#' Note that if no extent object (`geo`) is supplied, then all required blocks are downloaded. Missing arguments to `collection`,
#' `varname`, and `year` will prompt the function to download ALL corresponding layers. eg. getdata_bc('dem') will
#' download all three layers (`dem`, `aspect`, `slope`) in the `dem` collection; and getdata_bc('fids', year=2012) will download
#' 'fids' layers from the year 2012. When a large number of layers are queued up in this way, consider setting `load.mode` to 'noload'
#' to avoid attempting to load too much data into R at once.
#'
#' @param geo vector of character strings (NTS/SNRC codes) or any geometry set of type sfc
#' @param collection character string, indicating the data collection to query
#' @param varname character string, indicating the layer to query
#' @param year integer, indicating the year to query
#' @param load.mode character string, one of 'noload', 'all', 'clip', 'mask'
#' @param force.dl boolean, indicates to download (and overwrite) any existing data
#'
#' @return A `rasterLayer` (or list of them) or NULL, depending on the value of `load.mode`
#' @importFrom methods as
#' @importFrom utils download.file
#' @importFrom utils setTxtProgressBar
#' @importFrom utils txtProgressBar
#' @export
getdata_bc = function(geo=NULL, collection=NULL, varname=NULL, year=NULL, load.mode='mask', force.dl=FALSE)
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
  dest.files = paste0(data.dir, collection, '/', fnames)

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
    printout.suffix = paste('downloading', sum(!idx.exists), 'block(s) to: ', data.dir, collection)
    print(paste(printout.prefix, printout.suffix))

    # create subdirectories of data.dir as needed
    dir.create(paste0(data.dir, collection, '/blocks'), recursive=TRUE)

    # download the blocks in a loop with a progress bar printout
    pb = txtProgressBar(min=1, max=sum(!idx.exists), style=3)
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

  # if in download-only mode...
  if(load.mode == 'noload')
  {
    # ...we're finished...
    return(NULL)

  } else {

    # ... otherwise, merge the blocks
    tempfile.tif = paste0(tempfile(), '.tif')
    gdalUtils::mosaic_rasters(dest.files[idx.geo], dst_dataset=tempfile.tif)

    # load the output, assign min/max stats and variable name
    out.raster = raster::setMinMax(raster::raster(tempfile.tif))
    #unlink(tempfile.tif)
  }

  if(load.mode %in% c('clip', 'mask'))
  {
    if(!is.poly)
    {
      warning('cannot clip to this geometry')

    } else {

      out.raster = raster::crop(out.raster, as(geo.input, 'Spatial'))
      if(load.mode == 'mask')
      {
        out.raster = raster::mask(out.raster, as(geo.input, 'Spatial'))
      }
    }
  }

  return(out.raster)



}
