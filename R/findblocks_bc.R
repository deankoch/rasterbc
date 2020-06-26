#' Identify NTS/SNRC codes covering a given geometry
#'
#' Data layers for the province of BC are split into blocks, according to the mapsheet coding system used by Canada's NTS/SNRC.
#' This function identifies which blocks are needed to cover a given (user-supplied) geographical extent.
#'
#' Returns the 4-character NTS/SNRC codes corresponding to mapsheets that intersect with the geometry set(s) in input.sf. If input.sf
#' is NULL, returns the character vector of all codes, ordered according to the rows of 'ntspoly_bc'.
#'
#' @param input.sf A simple features object (class sfc), at least part of which intersects with the province of BC
#'
#' @return A vector of character strings, the 4-character NTS/SNRC codes of the mapsheets that overlap with input.sf
#' @export
#' @examples
#' findblocks_bc()
findblocks_bc = function(input.sf=NULL)
{
  # check for NULL input
  if(is.null(input.sf))
  {
    # returns the list of all mapsheet codes covering BC landmass
    return(rasterbc::ntspoly_bc$NTS_SNRC)

  } else {

    # input.sf should be of class 'sfc'

    # drop any feature columns and find the intersection with ntspoly_bc
    input.geometries = sf::st_geometry(input.sf)
    idx.intersects = sapply(sf::st_intersects(sf::st_geometry(rasterbc::ntspoly_bc), input.geometries), any)

    return(findblocks_bc()[idx.intersects])
  }
}
