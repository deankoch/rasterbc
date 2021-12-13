#' Load/merge data blocks and optionally clip/mask them
#'
#' Loads all mapsheets covering the geographical extent of input argument
#' `geo`. This can be a vector of (4-character) NTS/SNRC block codes, or a geometry of class
#' `sfc` having a defined coordinate reference system.
#'
#' Data for the layer specified by `collection`, `varname`, and (as needed) `year`,
#' are fetched from the directory specified by \code{\link{datadir_bc}}, merged into a single
#' (mosaic) layer, cropped and masked as needed, and then loaded into memory and returned as a
#' \code{\link{RasterLayer-class}} object.
#'
#' When `geo` is a line or point type geometry (or when `type` is set to 'all'), the
#' function uses `raster::merge` to create a larger (mosaic) RasterLayer containing the data
#' from all mapsheets intersecting with the input extent.
#'
#' When `geo` is a polygon, `type` can be set to clip or mask the returned raster: 'all'
#' returns the mosaic, as above; 'clip' crops the mosaic and to the bounding box of `geo`;
#' and 'mask' (the default) crops the mosaic then  sets all points not lying inside `geo` to NA.
#'
#' @param geo vector of character strings (NTS/SNRC codes) or a geometry of class `sfc`
#' @param collection character string, indicating the data collection to query
#' @param varname character string, indicating the layer to query
#' @param year integer, indicating the year to query
#' @param type character string, one of 'all', 'clip', 'mask'
#' @param quiet logical, suppresses console messages
#'
#' @return A `rasterLayer` (or list of them)
#' @importFrom methods as
#' @importFrom utils download.file
#' @importFrom utils setTxtProgressBar
#' @importFrom utils txtProgressBar
#' @export
#' @examples
#' # define a location of interest, and a polygon around it
#' input.point = sf::st_point(c(x=-120.1, y=50.1)) |> sf::st_sfc(crs='EPSG:4326')
#' input.polygon = input.point |> sf::st_buffer(units::set_units(10, km))
#'
#' # download the DEM mapsheets corresponding to the point
#' opendata_bc(geo=input.polygon, varname='harvest', year=2005) |> raster::plot()
#'
#' # load the DEM mapsheet for the point of interest
#' getdata_bc(input.point, 'dem', 'dem') |> raster::plot()
#' findblocks_bc(input.point, type='sfc') |> sf::st_geometry() |> plot(add=TRUE)
#' input.point |> sf::st_transform(input.point, crs='EPSG:3005')|> plot(add=TRUE)
#'
#'
#' opendata_bc(input.line, 'dem', 'dem') |> plot()
#'
#' # make a polygon (circle) from the point and repeat
#' input.polygon = input.point |> sf::st_buffer(units::set_units(10, km))
#' blocks |> sf::st_geometry() |> plot()
#' sf::st_transform(input.polygon, crs='EPSG:3005') |> plot(add=TRUE, pch=16)
#' blocks |> sf::st_geometry() |> sf::st_centroid() |> sf::st_coordinates() |> text(labels=blocks$NTS_SNRC)
#' findblocks_bc(input.polygon)
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
    out.raster = raster::setMinMax(raster::raster(fpath[idx.geo]))

  } else {

    # ... otherwise, merge the blocks into a bigger geotiff
    if(!quiet) cat(paste('creating mosaic of', sum(idx.geo), 'block(s)\n'))
    out.raster = do.call(raster::merge, lapply(fpath[idx.geo], raster::raster))

  }

  # assign variable name
  names(out.raster) = paste(c(varname, year), collapse='_')

  # trim output raster (skip for point inputs to geo)
  is.point = any( class(geo) %in% c('sfc_POINT', 'sfc_MULTIPOINT') )
  if( ( type %in% c('clip', 'mask') ) & !is.point )
  {
    if( 'sfc' %in% class(geo) )
    {
      if(!quiet) cat('clipping layer...')
      out.raster = raster::crop(out.raster, as(geo, 'Spatial'))
      if(type == 'mask')
      {
        if(!quiet) cat('masking layer...')
        out.raster = raster::mask(out.raster, as(geo, 'Spatial'))
      }

    } else {

      if(!quiet) cat('loading block(s)...')
    }
  }

  # reshape bcgz output as factor with attribute table
  if(collection == 'bgcz')
  {
    # convert raster to factor type
    out.raster = raster::ratify(out.raster)

    # copy the lookup tables
    lookup.list = rasterbc::metadata_bc$bgcz$metadata$coding

    # copy levels dataframe, append code column, copy back to rasterlayer
    bgcz.levels = raster::levels(out.raster)[[1]]
    bgcz.levels$code = lookup.list[[varname]][bgcz.levels[['ID']]]
    levels(out.raster) = list(bgcz.levels)
  }

  if(!quiet) cat('done\n')
  return(out.raster)

}
