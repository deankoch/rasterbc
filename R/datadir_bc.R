#' Set local directory for storage of raster data files
#'
#' All files downloaded/created by the rasterbc package are written to the directory assigned
#' by this function. The path to this directory is stored in the global options list for R under
#' 'rasterbc.data.dir'. To set this path, call `datadir_bc` with the path string in argument
#' `data.dir`. To check the current setting, call `datadir_bc()` without arguments.
#'
#' If `data.dir=NA`, the data storage directory is set to the a subdirectory of `base::tempdir()`,
#' a per-session temporary directory (cleared after each R session). This happens automatically if
#' `opendata_bc` or `getdata_bc` are called before `datadir_bc`, ensuring that `rasterbc` won't
#' unexpectedly overwrite things or leave garbage in the user's file system.
#'
#' However, users are strongly encouraged to set the data directory manually to a non-temporary
#' location. This allows copies of downloaded data to persist between sessions, so that
#' `rasterbc::opendata_bc` can load the local copies in future R sessions. This is both much faster
#' than downloading mapsheets repeatedly, and it reduces the strain on FRDR's data hosting service.
#'
#' The directory `data.dir` will be created if it doesn't already exist.
#'
#' @param data.dir character string, the absolute path to the desired storage directory
#' @param quiet logical indicating to skip confirmation prompt and warnings about existing directories
#'
#' @return character string, the absolute path to the data storage directory
#'
#' @importFrom utils menu
#' @export
#'
#' @examples
#' datadir_bc()
#' datadir_bc(NA, quiet=TRUE)
datadir_bc = function(data.dir=NULL, quiet=FALSE)
{
  # print the old data directory (if it was set already)
  data.dir.existing = getOption('rasterbc.data.dir')

  # return/print the existing data directory
  initial.msg = 'data storage path has not been set. Please provide a path using datadir_bc(data.dir)'
  if( is.null(data.dir) )
  {
    if( is.null(data.dir.existing) ) { cat(initial.msg) } else {

      if(!quiet) cat(paste('current data storage path:', data.dir.existing, '\n'))
      if( !dir.exists(data.dir.existing) ) stop('data storage path not found on disk')
    }

    return(invisible(data.dir.existing))
  }

  # storage directory set to temporary directory when data.dir is NA
  data.dir.temp = normalizePath(file.path(tempdir(), 'rasterbc_data'), winslash='/', mustWork=FALSE)
  if( is.na(data.dir) ) { data.dir = data.dir.temp } else {

    # standardize the slashes for cleaner display
    data.dir = normalizePath(data.dir, winslash='/', mustWork=FALSE)

    # when selecting the directory manually, the function prompts the user to confirm
    if(!quiet)
    {
      # confirmation from user
      msg.request = paste('rasterbc will store downloaded mapsheet tiffs in directory:', data.dir)
      msg.interactive = paste0(msg.request, '. Is this okay?')
      user.selection = utils::menu(c('Yes', 'No'), title=msg.interactive)
      if(user.selection %in% c(0,2)) stop('user must confirm directory selection when quiet=FALSE')
    }

  }

  # print/create the data directory as needed
  if(!dir.exists(data.dir))
  {
    dir.create(data.dir, recursive=TRUE)
    dir.state = 'created new'

  } else {

    dir.state = 'using existing'
    warn.msg = 'warning: this directory appears to be non-empty. Contents may be overwritten!'
    if(length(dir(data.dir, all.files=TRUE)) > 2 & !quiet) warning(warn.msg)
  }
  if(!quiet) cat(paste(dir.state, 'directory for data storage:', data.dir, '\n'))

  # set the option and finish
  options('rasterbc.data.dir'=data.dir)
  return(invisible(data.dir))
}
