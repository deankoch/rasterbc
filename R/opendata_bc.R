#' Load/merge data blocks and optionally clip/mask them
#'
#' Loads all mapsheets covering the geographical extent of input argument
#' \code{geo}. This can be a vector of (4-character) NTS/SNRC block codes, or a geometry of class
#' \code{sfc} having a defined coordinate reference system.
#'
#' Data for the layer specified by \code{collection}, \code{varname}, and (as needed) \code{year},
#' are fetched from the directory specified by \code{\link{datadir_bc}}, merged into a single
#' (mosaic) layer, cropped and masked as needed, and then loaded into memory and returned as a
#' \code{SpatRaster} object. If the files are not found, and \code{dl=TRUE}, they
#' will be automatically downloaded.
#'
#' When \code{geo} is a line or point type geometry (or when \code{type='all'}), the
#' function uses \code{terra::merge} to create a larger (mosaic) SpatRaster containing the data
#' from all mapsheets intersecting with the input extent.
#'
#' When \code{geo} is a polygon, \code{type} can be set to clip or mask the returned raster: 'all'
#' returns the mosaic, as above; 'clip' crops the mosaic and to the bounding box of \code{geo};
#' and 'mask' (the default) crops the mosaic then  sets all points not lying inside \code{geo} to NA.
#' Note that \code{type} is ignored when \code{geo} is a point geometry or a character string of
#' codes (these cases behave like \code{type='all'}).
#'
#' @param geo vector of character strings (NTS/SNRC codes) or a geometry of class \code{sfc}
#' @param collection character string, indicating the data collection to query
#' @param varname character string, indicating the layer to query
#' @param year integer, indicating the year to query
#' @param type character string, one of 'all', 'clip', 'mask'
#' @param quiet logical, suppresses console messages
#' @param dl logical, enables automatic downloading of missing files
#'
#' @return A \code{SpatRaster}
#' @importFrom methods as
#' @importFrom utils download.file
#' @importFrom utils setTxtProgressBar
#' @importFrom utils txtProgressBar
#' @export
#' @examples
#' # define a location of interest, and a circle of radius 10km around it
#' input.point = sf::st_point(c(x=-120.1, y=50.1)) |> sf::st_sfc(crs='EPSG:4326')
#'
#' if( requireNamespace('units', quietly = TRUE) ) {
#' input.polygon = input.point |> sf::st_buffer(units::set_units(10, km))
#'
#' \dontrun{
#' # the following downloads data from FRDR
#' # open the DEM mapsheets corresponding to the polygon and plot
#' opendata_bc(geo=input.polygon, 'dem') |> terra::plot()
#' }
#' }
opendata_bc = function(geo=NULL, collection=NULL, varname=NULL, year=NULL, type='mask', quiet=FALSE, dl=TRUE)
{
  # get the data storage directory or prompt to create one if it doesn't exist yet
  data.dir = datadir_bc(quiet=TRUE)
  if(is.null(data.dir)) data.dir = datadir_bc(NA)
  rasterbc::ntspoly_bc

  # reshape geo as a single sfc geometry
  geo = parsegeo_bc(geo)

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

  # check if any of these blocks haven't been downloaded already
  idx.exists = listdata_bc(collection, varname, year, verbose=0, simple=TRUE)[idx.geo]
  if( any(!idx.exists) )
  {
    # halt if some blocks are missing and user has not specified to download
    if( !dl )
    {
      msg.blocks = paste('files', paste(names(idx.exists)[!idx.exists], collapse=', '), 'not found!')
      stop(paste(msg.blocks, 'Set dl=TRUE or use getdata_bc to download them'))
    }

    # download the missing blocks
    getdata_bc(geo=geo.codes, collection=collection, varname=varname, year=year, quiet=quiet)
  }

  # load the required blocks
  fpath = file.path(data.dir, fnames)
  if( sum(idx.geo)==1 )
  {
    # when only a single block is requested, load it directly, assign min/max stats
    out.raster = terra::rast(fpath[idx.geo])

  } else {

    # ... otherwise, merge the blocks into a bigger geotiff
    if(!quiet) cat(paste('creating mosaic of', sum(idx.geo), 'block(s)\n'))
    out.raster = do.call(terra::merge, lapply(fpath[idx.geo], terra::rast))

  }

  # assign variable name
  names(out.raster) = paste(c(varname, year), collapse='_')

  # trim output raster (skip for point inputs to geo)
  is.point = inherits(geo, c('sfc_POINT', 'sfc_MULTIPOINT'))
  #is.point = any( class(geo) %in% c('sfc_POINT', 'sfc_MULTIPOINT') )
  if( ( type %in% c('clip', 'mask') ) & !is.point )
  {
    #if( 'sfc' %in% class(geo) )
    if( inherits(geo, 'sfc') )
    {
      if(!quiet) cat('clipping layer...')
      out.raster = terra::crop(out.raster, geo)
      if(type == 'mask')
      {
        if(!quiet) cat('masking layer...')
        out.raster = terra::mask(out.raster, as(geo, 'SpatVector'))
      }

    } else {

      if(!quiet) cat('loading block(s)...')
    }
  }

  # reshape bcgz output as factor with attribute table
  if(collection == 'bgcz')
  {
    # convert raster to factor type
    out.raster = terra::as.factor(out.raster)

    # copy the lookup table and reshape as dataframe
    lookup.list = rasterbc::metadata_bc$bgcz$metadata$coding[[varname]]
    rat = data.frame(seq_along(lookup.list), lookup.list)
    names(rat) = c('id', varname)

    # assign raster attribute table
    levels(out.raster) = rat
  }

  if(!quiet) cat('done\n')
  return(out.raster)

}
