#' List all available layers, or their associated filepaths and download status
#'
#' Returns a list of dataframes (one per collection) describing the variables available through rasterbc, or a subset (as
#' specified by `collection`, `varname`, `year`). Alternatively, if `return.boolean==TRUE`, returns a nested list indicating
#' the filepaths associated with these layers, and which of them exist in the local data storage directory already.
#'
#' The layers available through this package are organized into "collections", corresponding to their original online sources.
#' Layers in a collection are further organized by variable name, and are uniquely identified by the character string `varname`
#' (and, if applicable, `year`). The optional arguments `collection`, `varname`, `year` prompt this function to return only the
#' applicable subsets.
#'
#' @param collection (Optional) character string, indicating the data collection to query
#' @param varname (Optional) character string, indicating the layer to query (see Details, below)
#' @param year (Optional) integer, indicating the year to query (see Details, below)
#' @param verbose An integer (0, 1, 2), indicating how much information about the files to print to the console
#' @param return.boolean A boolean, indicating whether to return a dataframe or a nested list of booleans
#'
#' @return Either a (list of) dataframe(s) containing information about each raster layer, or (when `return.boolean==TRUE`) a
#' nested list of boolean values (named according to filepath), with entries for each data file in the specified subset.
#' @importFrom stats setNames
#' @export
#' @examples
#' x = listdata_bc()
#' x = listdata_bc(collection='bgcz', verbose=1)
#' x = listdata_bc(collection='dem', verbose=2)
#' x = listdata_bc(collection='dem', varname='aspect', verbose=2)
#' x = listdata_bc(collection='fids', varname='IBM_trace', year=2005, verbose=2)
#' print(x)
#'
listdata_bc = function(collection=NULL, varname=NULL, year=NULL, verbose=1, return.boolean=FALSE)
{
  # get the data storage directory...
  data.dir = getOption('rasterbc.data.dir')
  if(is.null(data.dir))
  {
    # ... or prompt to create one if it doesn't exist yet
    stop('Data directory undefined. Set it using raster::datadir_bc()')
  }

  # check if a collection was specified
  if(is.null(collection))
  {
    # build vector of (all) collections to query when "collection" argument is not assigned
    collections = setNames(nm=names(rasterbc::metadata_bc))
    return(lapply(collections, function(collection) listdata_bc(collection, varname, year, verbose, return.boolean)))

  } else {

    # check if the supplied collection argument has been misspelled before proceeding
    collections = names(rasterbc::metadata_bc)
    if(collection %in% collections)
    {
        # a valid collection string was specified. Fetch all of its variable names
        varnames = setNames(nm=rownames(rasterbc::metadata_bc[[collection]]$metadata$df))

        # check if a varname argument has not been supplied
        if(is.null(varname))
        {
          # construct return values and finish
          if(return.boolean)
          {
            # recursive call to query all variable names
            return(lapply(varnames, function(varname) listdata_bc(collection, varname, year, verbose)))

          } else {

            # pull the metadata dataframe for this collection
            out.df = rasterbc::metadata_bc[[collection]]$metadata$df

            # prune or augment the dataframe, depending on level of verbose
            if(verbose == 0)
            {
              # keep only the year column
              out.df = out.df[, 'year', drop=FALSE]

            } else if(verbose == 2) {

              # append a column indicating the number of blocks downloaded
              booleans.list = lapply(varnames, function(varname) listdata_bc(collection, varname, year, return.boolean=TRUE))
              out.df$blocks.downloaded = sapply(booleans.list, function(lyr) paste(c(sum(unlist(lyr)), length(unlist(lyr))), collapse='/'))

            }

            return(out.df)
          }


        } else {

          # check if the supplied varname argument has been misspelled before proceeding
          if(varname %in% varnames)
          {
            # check if this varname is a one time layer, or a time-series
            if(all(is.na(rasterbc::metadata_bc[[collection]]$metadata$year[varname])))
            {
              # case: varname is a one-time layer (no time-series, year argument ignored)
              if(!is.null(year))
              {
                # print a warning if a year was specified
                warning('the supplied year argument (', year, ') ignored for this (non-time-series) layer')
              }

              # build vectors of filenames and booleans indicating whether they exist on disk
              fnames = rasterbc::metadata_bc[[collection]]$fname$block[[varname]]
              fnames.exist = setNames(file.exists(file.path(data.dir, fnames)), fnames)

              if(return.boolean)
              {
                # return the booleans (with names indicating filepath)
                return(fnames.exist)

              } else {

                # pull the metadata dataframe for this collection
                out.df = rasterbc::metadata_bc[[collection]]$metadata$df
                return(out.df[rownames(out.df)==varname,])


              }




            } else {

              # case: varname has multiple years. Fetch the vector of years for this variable
              years = rasterbc::metadata_bc[[collection]]$metadata$year[[varname]]

              # check if a year argument has been supplied
              if(is.null(year))
              {
                # no year supplied. Construct return values with all years and finish
                if(return.boolean)
                {
                  # recursive call to query all variable names
                  return(lapply(years, function(year) listdata_bc(collection, varname, year, verbose, return.boolean)))

                } else {

                  # pull the metadata dataframe for this collection
                  out.df = rasterbc::metadata_bc[[collection]]$metadata$df

                  # prune or augment the dataframe, depending on level of verbose
                  if(verbose == 0)
                  {
                    # keep only the year column
                    out.df = out.df[, 'year', drop=FALSE]

                  } else if(verbose == 2) {

                    # append a column indicating the number of blocks downloaded
                    booleans.list = lapply(varnames, function(lyr) listdata_bc(collection, lyr, year, return.boolean=TRUE))
                    out.df$blocks.downloaded = sapply(booleans.list, function(lyr) paste(c(sum(unlist(lyr)), length(unlist(lyr))), collapse='/'))
                  }

                  return(out.df)
                }

              } else {

                # check if the year is available
                if(year %in% years)
                {
                  # only scan for files on disk (slow) if needed
                  if(return.boolean | verbose==2)
                  {
                    # year argument is valid. Find its index among the other years
                    idx.year = names(rasterbc::metadata_bc[[collection]]$fname$block) == names(years[years==year])

                    # build list of filenames and existence boolean
                    fnames = rasterbc::metadata_bc[[collection]]$fname$block[[which(idx.year)]][[varname]]
                    fnames.exist = setNames(file.exists(file.path(data.dir, fnames)), fnames)

                    if(return.boolean)
                    {
                      # return the booleans (with names indicating filepath)
                      return(fnames.exist)
                    }

                  }

                  # pull the metadata dataframe for this collection/varname and adjust year entry to match the user input
                  out.df = rasterbc::metadata_bc[[collection]]$metadata$df[varname,]
                  out.df$year = as.character(year)

                  # prune or augment the dataframe, depending on level of verbose
                  if(verbose == 0)
                  {
                    # keep only the year column
                    out.df = out.df[, 'year', drop=FALSE]

                  } else if(verbose == 2) {

                    # append a column indicating the number of blocks downloaded for this one year
                    booleans.vector = listdata_bc(collection, varname, year, return.boolean=TRUE)
                    out.df$blocks.downloaded = paste(c(sum(booleans.vector), length(booleans.vector)), collapse='/')
                  }

                  return(out.df)

                } else {

                  # warning when "year" argument is invalid
                  warning(paste0('variable name "', varname, '" not found in collection "', collection, '" for year ', year))
                  return(NULL)

                }
              }

            }

          } else {

            # error when "varname" argument is invalid
            error.msg = paste0('variable name \"', varname, '\" not found in collection \"', collection, '\"')
            suggestions.msg = paste('\nChoose one of the following variable names:', paste0('\"', paste(varnames, collapse='\", \"')), '\"')
            stop(paste(error.msg, suggestions.msg))

          }
        }

    } else {

      # error when "collection" argument is invalid
      error.msg = paste0('collection "', collection, '" not found.')
      suggestions.msg = paste('\nChoose one of the following collections:', paste0('\"', paste(collections, collapse='\", \"')), '\"')
      stop(paste(error.msg, suggestions.msg))
    }


  }




  # collection = ifelse(is.null(collection), '', collection)
  # year
  # file.path(data.dir, collection)
  #
  #
  # # check for NULL input
  # rasterbc::metadata_bc$dem$fname
  # list.files('H:\\git-MPB\\rasterbc_src', recursive=TRUE)

}
