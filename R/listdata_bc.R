#' List all available layers, or their associated filepaths and download status
#'
#' Returns a list of dataframes (one per collection) describing the variables available through rasterbc, or a subset (as
#' specified by `collection`, `varname`, `year`). Alternatively, if `simple==TRUE`, returns a nested list indicating
#' the filepaths associated with these layers, and which of them exist in the local data storage directory already.
#'
#' The layers available through this package are organized into "collections", corresponding to their original online sources.
#' Layers in a collection are further organized by variable name, and are uniquely identified by the character string `varname`
#' (and, if applicable, `year`). The optional arguments `collection`, `varname`, `year` prompt this function to return only the
#' applicable subsets.
#'
#' @param collection (Optional) character string, indicating the data collection to query
#' @param varname (Optional) character string, indicating the layer to query (see Details, below)
#' @param year (Optional) integer or character string, indicating the year to query (see Details, below)
#' @param verbose An integer (0, 1, 2), indicating how much information about the files to print to the console
#' @param simple logical indicating to return a (list of) logical vector(s) indicating existence on disk of specific filenames
#'
#' @return Either a (list of) dataframe(s) containing information about each raster layer, or (when `simple==TRUE`) a
#' nested list of logical values (named according to filepath), with entries for each data file in the specified subset.
#' @importFrom stats setNames
#' @export
#' @examples
#' # print available collections
#' listdata_bc() |> names()
#'
#' # print info about a specific collection
#' listdata_bc('bgcz')
#' listdata_bc('bgcz', verbose=2)
#'
#' # example with a year field
#' listdata_bc('fids', varname='IBM_mid', year=2005, verbose=2)
#' listdata_bc('fids', varname='IBM_mid', verbose=2)
#'
#' # "simple=TRUE" mode returns logical vector indicating which mapsheets are downloaded
#' listdata_bc(collection='dem', varname='aspect', verbose=2, simple=TRUE)
listdata_bc = function(collection=NULL, varname=NULL, year=NULL, verbose=1, simple=FALSE)
{
  # get the data storage directory.
  data.dir = datadir_bc(quiet=TRUE)
  if(is.null(data.dir)) data.dir = datadir_bc(NA)

  # check if a collection was specified
  if(is.null(collection))
  {
    # build vector of (all) collections to query and submit them in recursive calls
    collections = setNames(nm=names(rasterbc::metadata_bc))
    return(lapply(collections, function(collection) listdata_bc(collection, varname, year, verbose, simple)))
  }

  # check if the supplied collection argument has been misspelled before proceeding
  collections = names(rasterbc::metadata_bc)
  if( !(collection %in% collections) )
  {
    # error when "collection" argument is invalid
    error.msg = paste0('unknown collection \"', collection, '\"')
    collections.msg = paste0('\"', paste(collections, collapse='\", \"'))
    suggestions.msg = paste('\nThe valid collection strings are:', collections.msg, '\"')
    stop(paste(error.msg, suggestions.msg))
  }

  # fetch all variable names associated with the collection and handle missing varname argument
  varnames = setNames(nm=rownames(rasterbc::metadata_bc[[collection]]$metadata$df))
  if(is.null(varname))
  {
    # simple mode: recursive call to query all variable names and finish, returning output as list
    if(simple) return(lapply(varnames, function(varname) listdata_bc(collection, varname, year, verbose, simple)))

    # copy the metadata dataframe for this collection and trim/append, depending on level of verbose
    out.df = rasterbc::metadata_bc[[collection]]$metadata$df
    if(verbose == 0) out.df = out.df[, 'year', drop=FALSE]
    if(verbose == 2)
    {
      # append a column indicating the number of blocks downloaded
      booleans.list = lapply(varnames, function(varname) listdata_bc(collection, varname, year, simple=TRUE))
      out.df$tiles = sapply(booleans.list, function(lyr) paste(c(sum(unlist(lyr)), length(unlist(lyr))), collapse='/'))
    }

    return(out.df)
  }

  # check if the supplied varname argument has been misspelled before proceeding
  if( !(varname %in% varnames) )
  {
    # error when "varname" argument is invalid
    error.msg = paste0('variable name \"', varname, '\" not found in collection \"', collection, '\"')
    varnames.msg =paste0('\"', paste(varnames, collapse='\", \"'))
    suggestions.msg = paste('\nChoose one of the following variable names:', varnames.msg, '\"')
    stop(paste(error.msg, suggestions.msg))
  }

  # handle "varname" associated with a one-time layer (not a time series)
  if( all(is.na(rasterbc::metadata_bc[[collection]]$metadata$year[varname])) )
  {
    # print a warning if a year was specified
    warn.year = paste0('the supplied year argument (', year, ') ignored for this (non-time-series) layer')
    if(!is.null(year)) warning(warn.year)

    # build vectors of filenames and booleans indicating whether they exist on disk
    fnames = rasterbc::metadata_bc[[collection]]$fname$block[[varname]]
    fnames.exist = setNames(file.exists(file.path(data.dir, fnames)), fnames)

    # simple mode: return the booleans (with names indicating filepath)
    if(simple) return(fnames.exist)

    # pull the metadata dataframe for this collection, append block info as needed
    out.df = rasterbc::metadata_bc[[collection]]$metadata$df
    out.df = out.df[rownames(out.df)==varname,]
    if(verbose == 2)
    {
      # append a column indicating the number of blocks downloaded
      existence = listdata_bc(collection, varname, year, simple=TRUE)
      out.df$tiles = paste(c(sum(unlist(existence)), length(unlist(existence))), collapse='/')
    }
    return(out.df)
  }

  # copy the years associated with this varname and handle requests where year was not supplied
  years = rasterbc::metadata_bc[[collection]]$metadata$year[[varname]]
  if(is.null(year))
  {
    # simple case: recursive call to query all variable names and return logical vectors as list
    if(simple) return(lapply(years, function(year) listdata_bc(collection, varname, year, verbose, simple)))

    # copy the metadata dataframe for this collection and trim/append, depending on level of verbose
    out.df = rasterbc::metadata_bc[[collection]]$metadata$df[varname,]
    if(verbose == 0) out.df = out.df[, 'year', drop=FALSE]
    if(verbose == 2)
    {
      # append a column indicating the number of blocks downloaded
      existence = listdata_bc(collection, varname, year, simple=TRUE)
      out.df$tiles = paste(c(sum(unlist(existence)), length(unlist(existence))), collapse='/')
    }
    return(out.df)
  }

  # handle requests for unavailable years
  if( !(year %in% years) )
  {
    # warning when "year" argument is invalid
    warning(paste0('variable name "', varname, '" not found in collection "', collection, '" for year ', year))
    return(NULL)
  }

  # only scan for files on disk (slow) if needed
  if(simple | verbose==2)
  {
    # find index of the requested year, build list of filenames, check for file on disk
    idx.year = names(rasterbc::metadata_bc[[collection]]$fname$block) == names(years[years==year])
    fnames = rasterbc::metadata_bc[[collection]]$fname$block[[which(idx.year)]][[varname]]
    fnames.exist = setNames(file.exists(file.path(data.dir, fnames)), fnames)

    # simple mode: return the logical vector
    if(simple) return(fnames.exist)
  }

  # copy the metadata dataframe for this collection and trim/append, depending on level of verbose
  out.df = rasterbc::metadata_bc[[collection]]$metadata$df[varname,]
  out.df$year = as.character(year)
  if(verbose == 0) out.df = out.df[, 'year', drop=FALSE]
  if(verbose == 2)
  {
    # append a column indicating the number of blocks downloaded
    existence = listdata_bc(collection, varname, year, simple=TRUE)
    out.df$tiles = paste(c(sum(unlist(existence)), length(unlist(existence))), collapse='/')
  }
  return(out.df)
}
