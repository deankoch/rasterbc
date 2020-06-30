#' Identify which data layers are available online, and (optionally) which have been downloaded already
#'
#' Prints a list of collection and variable names available through rasterbc, and (optionally) returns a nested list indicating
#' which of these exist on disk already
#'
#' The layers available through this package are organized into "collections", corresponding to their original online source.
#' Layers in a collection are further organized by variable name, and are uniquely identified by the character string "varname"
#' (and, if applicable, the year). To see the full list of variable names by collection, run
#'
#' When arguments collection and/or varname are provided, check only for those (sub)collections, returning
#' the corresponding (sub)list. This saves having to scan the entire data storage directory, which can be slow.
#'
#' @param collection character string, indicating the data collection to query
#' @param varname character string, indicating the layer to query (see Details, below)
#' @param year integer, indicating the year to query (see Details, below)
#' @param verbose integer (0, 1, 2), indicating how much information about the files to print to the console
#'
#' @return A (named) nested list of boolean values, one for each file. This list has the same structure and naming scheme as
#' 'rasterbc::metadata_bc', but with boolean entries instead of character strings. The entry indicates whether the file exists on
#' disk in the local data storage directory specified by 'rasterbc::datadir_bc'.
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
listdata_bc = function(collection=NULL, varname=NULL, year=NULL, verbose=1)
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

    # recursive call to query all collections when "collection" argument is not assigned
    return(lapply(setNames(nm=names(rasterbc::metadata_bc)), function(collection) listdata_bc(collection, varname, year, verbose)))

  } else {

    # check if the supplied collection argument has been misspelled before proceeding
    collections = names(rasterbc::metadata_bc)
    if(collection %in% collections)
    {
        # a valid collection string has been specified. Fetch all of its variable names
        varnames = setNames(nm=names(rasterbc::metadata_bc[[collection]]$metadata$varnames))

        # check if a varname argument has been supplied
        if(is.null(varname))
        {
          # printout to list variable names
          printout.prefix = 'available variable names: '
          printout.suffix = paste(rasterbc::metadata_bc[[collection]]$metadata$varnames, collapse=', ')
          if(verbose == 1)
          {
            print(paste(printout.prefix, printout.suffix))
          }

          # recursive call to query all variable names when "varname" argument is not assigned
          return(lapply(varnames, function(varname) listdata_bc(collection, varname, year, verbose)))

        } else {

          # check if the supplied varname argument has been misspelled before proceeding
          if(varname %in% varnames)
          {
            # check if this varname corresponds to a time-series
            if(varname == rasterbc::metadata_bc[[collection]]$metadata$varnames[varname])
            {
              # case: varname is a one-time layer (no time-series, year argument ignored)
              if(!is.null(year))
              {
                warning('year argument (', year, ') ignored for this layer')
              }

              # build list of filenames and boolean indicating whether they exist on disk
              fnames = rasterbc::metadata_bc[[collection]]$fname$block[[varname]]
              fnames.exist = setNames(file.exists(paste0(data.dir, collection, '/', fnames)), fnames)
              printout.prefix = paste0('[', collection, '] ', sum(fnames.exist), '/', length(fnames))
              printout.suffix = paste0(varname, ' blocks (storage: ', paste0(data.dir, collection), ')')
              if(verbose > 1)
              {
                # printout indicating fraction of blocks downloaded
                print(paste(printout.prefix, printout.suffix))
              }

              # return the booleans (with names indicating filepath)
              return(fnames.exist)

            } else {

              # case: varname has multiple years. Fetch the vector of years for this variable
              years.all = rasterbc::metadata_bc[[collection]]$source$years
              idx.years = sapply(names(years.all), function(year) varname %in% names(rasterbc::metadata_bc[[collection]]$fname$block[[year]]))
              years.lyr = years.all[idx.years]

              # check if a year argument has been supplied
              if(is.null(year))
              {
                # recursive call to query all years when "year" argument is not assigned
                return(lapply(years.lyr, function(year) listdata_bc(collection, varname, year, verbose)))

              } else {

                # check if the year is available
                if(year %in% years.lyr)
                {
                  # year argument is valid. Find its index among the other layers
                  year.string = years.lyr[years.lyr==year]
                  idx.year = names(rasterbc::metadata_bc[[collection]]$fname$block) == names(year.string)

                  # build list of filenames and existence boolean
                  fnames = rasterbc::metadata_bc[[collection]]$fname$block[[which(idx.year)]][[varname]]
                  fnames.exist = setNames(file.exists(paste0(data.dir, collection, '/', fnames)), fnames)
                  printout.prefix = paste0('[', year, ']:[', collection, ']: ', sum(fnames.exist), '/', length(fnames), ' ')
                  printout.suffix = paste0(varname, ' blocks (storage: ', paste0(data.dir, collection, '/', year), ')')
                  if(verbose > 1)
                  {
                    # printout indicating fraction of blocks downloaded
                    print(paste0(printout.prefix, printout.suffix))
                  }
                  return(fnames.exist)

                } else {

                  # warning when "year" argument is invalid
                  warning(paste0('variable name "', varname, '" not found in collection "', collection, '" for year ', year))
                  return(NULL)

                }

              }

            }

          } else {

            # error when "varname" argument is invalid
            error.msg = paste0('variable name "', varname, '" not found in collection "', collection, '"')
            suggestions.msg = paste('\nChoose one of:', paste(varnames, collapse=', '))
            stop(paste(error.msg, suggestions.msg))

          }
        }

    } else {

      # error when "collection" argument is invalid
      error.msg = paste0('collection "', collection, '" not found.')
      suggestions.msg = paste('\nChoose one of:', paste(collections, collapse=', '))
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
