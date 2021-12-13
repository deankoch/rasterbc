#' Identify NTS/SNRC codes covering a given geometry
#'
#' Data layers for the province of BC are split according to the mapsheet coding system
#' used by Canada's NTS/SNRC. This function identifies mapsheets intersecting with
#' the geographical extent of \code{geo}.
#'
#' When \code{type='character'}, the function returns the 4-character NTS/SNRC codes corresponding
#' to mapsheets that intersect with the input geometry. When \code{type='sfc'}, the function returns
#' the mapsheet polygons themselves.
#'
#' \code{geo=NULL} (the default) indicates to return all mapsheet codes/polygons. Non-NULL \code{geo}
#' must either be a character vector of codes, or else an sfc class object having a coordinate
#' reference system ('crs' attribute) defined. If \code{geo} intersects with none of the BC mapsheets,
#' (or contains unknown NTS/SNRC codes) the function returns \code{NULL}.
#'
#' @param geo A point, line, or polygon object of class \code{sfc}, or a character vector of 4-character codes
#' @param type character, the object type to return, either 'character' or 'sfc'
#'
#' @return either a character vector or an sfc object (see details)
#' @importFrom utils choose.dir
#' @export
#' @examples
#' # list all mapsheet codes then print the corresponding sfc object
#' findblocks_bc()
#' findblocks_bc(type='sfc')
#'
#' # define an example point by specifying latitude and longitude (in WGS84 reference system)
#' input.point = sf::st_point(c(x=-120, y=50)) |> sf::st_sfc(crs='EPSG:4326')
#'
#' # this point lies at the intersection of four mapsheets, which are in Albers projection
#' blocks = findblocks_bc(input.point, type='sfc')
#' blocks |> sf::st_geometry() |> plot()
#' sf::st_transform(input.point, crs='EPSG:3005') |> plot(add=TRUE)
#' blocks |> sf::st_geometry() |> sf::st_centroid() |> sf::st_coordinates() |> text(labels=blocks$NTS_SNRC)
#'
#' # nudge the point slightly so it intersects with only one mapsheet
#' input.point = sf::st_point(c(x=-120.1, y=50.1)) |> sf::st_sfc(crs='EPSG:4326')
#' blocks |> sf::st_geometry() |> plot()
#' sf::st_transform(input.point, crs='EPSG:3005') |> plot(add=TRUE)
#' blocks |> sf::st_geometry() |> sf::st_centroid() |> sf::st_coordinates() |> text(labels=blocks$NTS_SNRC)
#' findblocks_bc(input.point)
#'
#' # make a polygon (circle) from the point and repeat
#' input.polygon = input.point |> sf::st_buffer(units::set_units(10, km))
#' blocks |> sf::st_geometry() |> plot()
#' sf::st_transform(input.polygon, crs='EPSG:3005') |> plot(add=TRUE)
#' blocks |> sf::st_geometry() |> sf::st_centroid() |> sf::st_coordinates() |> text(labels=blocks$NTS_SNRC)
#' findblocks_bc(input.polygon)
#'
#' # geo can be a character vector of codes
#' input.codes = c('093A', '093I', '104O')
#' findblocks_bc(input.codes, type='sfc')
#'
findblocks_bc = function(geo=NULL, type='character')
{
  # return the list of all mapsheet codes covering BC when input is NULL
  if( is.null(geo) )
  {
    # return sfc object when requested, otherwise return character codes
    if(type=='sfc') return(rasterbc::ntspoly_bc)
    return(rasterbc::ntspoly_bc$NTS_SNRC)
  }

  # coerce various input types to a single geometry of sfc class in EPSG:3005 coordinates
  geo = parsegeo_bc(geo)

  # find the intersection with ntspoly_bc
  input.geometries = sf::st_geometry(geo)
  idx.intersects = sapply(sf::st_intersects(sf::st_geometry(rasterbc::ntspoly_bc), input.geometries), any)

  # return the sfc object if requested
  if(type=='sfc') return(rasterbc::ntspoly_bc[idx.intersects,])

  # otherwise return the codes
  return(findblocks_bc()[idx.intersects])
}



