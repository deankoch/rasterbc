#' Set local directory for storage of raster data files
#'
#' All files downloaded/created by the rasterbc package are written to the directory assigned by this function. The path to
#' this directory is stored in the global options list for R under 'rasterbc.data.dir'
#'
#' By default this is the path returned by \code{rappdirs::user_data_dir}. With argument \code{select==TRUE}, a different
#' directory can be specified: If this is not specified in \code{data.dir}, the user is prompted to choose it via an interactive
#' file dialog.
#'
#'
#' @param select A boolean indicating whether the directory should be automatically selected (default) or user-selected
#' @param data.dir An (optional) character string, providing the absolute path to the desired storage directory
#'
#' @return character string, the absolute path to the selected storage directory
#'
#' @importFrom utils choose.dir
#' @export
#' @examples
#' datadir_bc(TRUE, 'H:/')
datadir_bc = function(select=FALSE, data.dir=NULL)
{
  # storage directory set automatically by rappdirs unless user sets select=TRUE
  if(!select)
  {
    # rappdirs picks a sensible (platform-dependent) directory
    data.dir = rappdirs::user_data_dir('rasterbc')

  } else if (is.null(data.dir)) {

    # if no data.dir supplied, prompt for one with GUI
    # this is a snippet from stackexchange (https://tinyurl.com/y7mmsaw7)
    caption = 'Select rasterbc data storage directory'
    if (exists('utils::choose.dir')) {

      # this function only available for Windows
      utils::choose.dir(caption=caption)

    } else {
      # alternative for non-Windows users
      tcltk::tk_choose.dir(caption=caption)
    }

  }

  # create the directory as needed
  print(paste('data storage path set to:', data.dir))
  if(!dir.exists(data.dir))
  {
    dir.create(data.dir, recursive=TRUE)
    print(paste('directory created'))

  } else {

    print(paste('directory exists'))
    if(length(dir(data.dir, all.files=TRUE)) > 2)
    {
      warning('warning: this directory appears to be non-empty. Contents may be overwritten!')

    }
  }
  options('rasterbc.data.dir'=data.dir)
  return(data.dir)
}
