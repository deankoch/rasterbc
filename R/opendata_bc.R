#' Load blocks and (optionally) merge/clip/mask them
#'
#' Loads (as a single RasterLayer) all blocks covering the geographical extent specified in input argument `geo`. This can be a vector of
#' (4-character) NTS/SNRC block codes, or any geometry set of type `sfc`.
#'
#' Data for the layer specified by `collection`, `varname`, and (as needed) `year`, are fetched from the directory specified by
#' \code{\link{datadir_bc}}, merged into a single (mosaic) layer, cropped and masked as needed, and then loaded into memory and returned
#' as a \code{\link{RasterLayer-class}} object.
#'
#' Argument `load.mode` specifies whether/how the blocks should be loaded into memory. 'all' uses `gdalUtils::gdal_mosaic` to merge the
#' blocks into a larger rasterLayer, covering all (and likely more) of the input extent; 'clip' and 'mask' (the default) assume that `geo`
#' is a (multi)polygon, cropping the merged blocks to its boundary; and  with 'mask', all data not inside the polygon is set to NA.
#'
#' @param geo vector of character strings (NTS/SNRC codes) or any geometry set of type sfc
#' @param collection character string, indicating the data collection to query
#' @param varname character string, indicating the layer to query
#' @param year integer, indicating the year to query
#' @param load.mode character string, one of 'all', 'clip', 'mask'
#'
#' @return A `rasterLayer` (or list of them)
#' @importFrom methods as
#' @importFrom utils download.file
#' @importFrom utils setTxtProgressBar
#' @importFrom utils txtProgressBar
#' @export
opendata_bc = function(geo=NULL, collection=NULL, varname=NULL, year=NULL, load.mode='mask')
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

  # build a list of filenames available to download for this collection/varname/year
  if(all(is.na(rasterbc::metadata_bc[[collection]]$metadata$year[[varname]])))
  {
    # case: data are one-time, not time series
    fnames = rasterbc::metadata_bc[[collection]]$fname$block[[varname]]

  } else {

    # case: data are from time-series
    year.string = paste0('yr', year)
    fnames = rasterbc::metadata_bc[[collection]]$fname$block[[year.string]][[varname]]
  }
  dest.files = file.path(data.dir, fnames)

  # find the index of the particular blocks needed
  idx.geo = names(fnames) %in% geo

  # check that all of these blocks have been downloaded already
  idx.exists = listdata_bc(collection=collection, varname=varname, year=year, verbose=0, return.boolean=TRUE)[idx.geo]
  if(any(!idx.exists))
  {
    # error if some blocks are missing
    stop(paste('blocks', paste(names(idx.exists)[idx.exists], collapse=', '), 'not found! Use getdata_bc to download them'))

  }

  # check how many blocks are requested
  if(sum(idx.geo)==1)
  {
    # when only a single block is requested, load it directly, assign min/max stats
    out.raster = raster::setMinMax(raster::raster(dest.files[idx.geo]))

  } else {

    # ... otherwise, merge the blocks into a bigger geotiff
    print(paste('creating mosaic of', sum(idx.geo), 'block(s)'))
    out.raster = do.call(raster::merge, lapply(dest.files[idx.geo], raster::raster))

  }

  # assign variable name
  names(out.raster) = paste(c(varname, year), collapse='_')

  if(load.mode %in% c('clip', 'mask'))
  {
    if(is.poly)
    {
      print('clipping layer...')
      out.raster = raster::crop(out.raster, as(geo.input, 'Spatial'))
      if(load.mode == 'mask')
      {
        print('masking layer...')
        out.raster = raster::mask(out.raster, as(geo.input, 'Spatial'))
      }

    } else {

      print('loading block(s)')
    }
  }

  return(out.raster)

}
