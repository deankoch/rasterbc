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

  # find the index of the particular blocks needed
  idx.geo = names(rasterbc::metadata_bc[[collection]]$fname$block[[varname]]) %in% geo

  # build the full list of blocks
  fnames = rasterbc::metadata_bc[[collection]]$fname$block[[varname]]
  dest.files = file.path(data.dir, collection, fnames)

  # check that all of these blocks have been downloaded already
  idx.exists = listdata_bc(collection=collection, varname=varname, year=year, verbose=0)[idx.geo]
  if(any(!idx.exists))
  {
    # error if some blocks are missing
    stop(paste('blocks', paste(names(idx.exists)[idx.exists], collapse=', '), 'not found! Use getdata_bc to download them'))

  }

  # ... otherwise, merge the blocks into a bigger geotiff using a temporary file
  tempfile.tif = tempfile(fileext='.tif')
  print(paste('output to temporary file:', tempfile.tif))
  if(sum(idx.geo)>1)
  {
    print(paste('creating mosaic of', sum(idx.geo), 'block(s)'))
    gdalUtils::mosaic_rasters(dest.files[idx.geo], dst_dataset=tempfile.tif)
  }

  # load the output, assign min/max stats and variable name
  out.raster = raster::setMinMax(raster::raster(tempfile.tif))
  names(out.raster) = paste(c(year, varname), collapse='_')

  if(load.mode %in% c('clip', 'mask'))
  {
    print('clipping layer...')
    if(!is.poly)
    {
      warning('cannot clip to this geometry')

    } else {

      out.raster = raster::crop(out.raster, as(geo.input, 'Spatial'))
      if(load.mode == 'mask')
      {
        print('masking layer...')
        out.raster = raster::mask(out.raster, as(geo.input, 'Spatial'))
      }
    }
  }

  return(out.raster)

}