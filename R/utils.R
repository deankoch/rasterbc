#' recursively crawl a nested list structure, converting all character strings according to a rule
#'
#' This function takes a list (possibly nested) of file paths or web url paths, and for those matching
#' the input prefix string (ie having the same leading characters), swaps the prefix for a different one.
#'
#' When transferring files from a local machine to the web hosting service for storage (or vice versa),
#' I preserve the directory structure for tidyness. This helper function makes it easier to convert a large nested list of file paths
#' to a list of file download URLs (and vice versa).
#'
#' @param input.list A list (possible nested), whose terminal elements are all character strings (or vectors of them)
#' @param input.prefix The character string to parse in the entries of input.list (ie. startsWith(xx, input.prefix)==TRUE)
#' @param output.prefix The character string to swap in for input.prefix
#'
#' @return A list with the same structure and element names as input.list, but with each terminal element (character string, or
#' vector of character strings) modified according to the prefix swap rule.
#' @noRd
#' @examples
#' example.element = setNames(paste0('C:/', 1:10), paste0('foo', 1:10))
#' example.list = list(a=example.element, b=list(c=example.element, d=example.element))
#' listswap_bc(example.list, 'C:/', 'https://somewhere/')
listswap_bc = function(input.list, input.prefix, output.prefix)
{
  if(!is.list(input.list))
  {
    # do the string swap when we encounter a vector of character strings
    return(sapply(input.list, function(path) {

      # handle non-character list entries
      if(!inherits(input.list, 'character'))
      {
        # non-character entries are not touched
        return(path)

      } else {

        # skip strings that don't have the specified input prefix
        if(startsWith(path, input.prefix)) {

          # swap in the string prefix
          return(paste0(output.prefix, strsplit(path, input.prefix)[[1]][2]))

        } else {

          # non-matching entries are not touched
          return(path)
        }

      }
    }))

  } else {
    # recursive call if list entry is itself a list
    lapply(input.list, function(list.entry) listswap_bc(list.entry, input.prefix, output.prefix))
  }
}

#' List filenames of all blocks corresponding to a collection request
#'
#' Helper function for listdata_bc, getdata_bc, opendata_bc.
#'
#' Handles some error checking for input arguments collection, varname, year, and
#' returns the relative filepaths for geoTIFFs in the specified dataset
#'
#' When varname is NULL it may be specified in argument collection. The function
#' checks for that and does the replacement (setting collection) as needed. It also
#' indicates whether the dataset belongs to a time series (ts)
#'
#' @param collection character string indicating the data collection to query
#' @param varname character string indicating the layer to query
#' @param year integer indicating the year to query (if applicable)
#' @param quiet logical, suppresses console messages
#'
#' @return a list with elements 'collection', 'varname', 'ts', 'filenames' (see details)
#' @noRd
listfiles_bc = function(collection=NULL, varname=NULL, year=NULL, quiet=FALSE)
{
  # handle empty collection argument
  if( is.null(collection) )
  {
    # collection will be determined from the variable name (below)
    if( !is.null(varname) )
    {
      collection = varname
      varname = NULL

    } else {

      # printout of collection and variables names
      names.collection = paste(names(listdata_bc()), collapse=', ')
      msg.collection = paste('Please specify one of the collections :', names.collection, '\n')
      if( !quiet ) cat(msg.collection)
      return(invisible(NULL))
    }
  }

  # handle empty varname argument
  if( is.null(varname) )
  {
    # check for varname specified in collection argument
    varname.list = lapply(listdata_bc(), rownames)
    is.matched = sapply(sapply(varname.list, \(nm) collection == nm), any)
    if( any(is.matched) )
    {
      # swap collection->varname then assign the correct collection name
      varname = collection
      collection = names(varname.list)[is.matched]

    } else {

      # print the available variable names
      names.varname = paste0(collection, ': ', paste(rownames(listdata_bc(collection)), collapse=', '))
      msg.varname = paste('Please specify one of the variables from', names.varname, '\n')
      if( !quiet ) cat(msg.varname)
      return(invisible(NULL))
    }
  }

  # copy block filenames
  is.timeseries = FALSE
  fnames = rasterbc::metadata_bc[[collection]]$fname$block[[varname]]

  # for times series data the filenames are located in a sub-list
  if( is.null(fnames) )
  {
    # data are from time-series so we need to have the year argument in this case
    is.timeseries = TRUE
    if(is.null(year))
    {
      err.msg.line1 = paste0('Variable \"', varname, '\" from collection \"', collection, '\" requires a year argument')
      err.msg.line2 = paste0('Please specify one of the years: ', rasterbc::metadata_bc[[collection]]$metadata$df[varname, 'year'])
      stop(paste(c(err.msg.line1, err.msg.line2), collapse='\n'))
    }

    # Grab file names for all blocks
    year.string = paste0('yr', year)
    fnames = rasterbc::metadata_bc[[collection]]$fname$block[[year.string]][[varname]]

  }

  # catch empty return (no matching files)
  if( is.null(fnames) )
  {
    # prompt an informative warning then stop with an error
    listdata_bc(collection=collection, varname=varname, year=year, simple=TRUE)
    stop('no files matching request. Check arguments and see ?listdata_bc')
  }

  # return as a list
  return(list(collection=collection, varname=varname, is.timeseries=is.timeseries, filenames=fnames))

}


#' Handle various inputs to argument geo
#'
#' Helper function for \code{findblocks_bc} and possibly others. Checks for valid input
#' and returns SNRC block centroid(s) when passed (one or more) code(s). Otherwise
#' returns the input geometry geo after transformation to the Albers projection
#' (the coordinate system used in the raster data)
#'
#' @param geo A point, line, or polygon object of class \code{sfc}, or a character vector of 4-character codes
#'
#' @return An sf polygon or other geometry of the same type as geo
#' @noRd
parsegeo_bc = function(geo)
{
  # handle character input
  if(is.character(geo))
  {
    # compare with list of BC codes and halt if any are misspelled
    idx.valid = geo %in% findblocks_bc()
    if(!all(idx.valid))
    {
      msg.invalid = 'found no match in BC for the following NTS/SNRC code(s):'
      stop(paste(msg.invalid, paste(geo[!idx.valid], collapse=', ')))
    }

    # replace character codes with centroid points
    geo = rasterbc::ntspoly_bc[match(geo, rasterbc::ntspoly_bc$NTS_SNRC),]
    geo = geo |> sf::st_geometry() |> sf::st_centroid()
  }

  # drop any feature columns and merge multiple polygons into one
  geo = sf::st_geometry(geo) |> sf::st_union()

  # transform to BC Albers projection
  if( is.na(sf::st_crs(geo)) ) stop('unknown coordinate reference system')
  geo = sf::st_transform(geo, crs='EPSG:3005')
  return(geo)
}
