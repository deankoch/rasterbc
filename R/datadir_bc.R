#' Set local directory for storage of raster data files
#'
#' All files downloaded/created by the rasterbc package are written to the directory assigned by this function. The path to
#' this directory is stored in the global options list for R under 'rasterbc.data.dir'
#'
#' By default this is the path returned by \code{rappdirs::user_data_dir}. The optional argument \code{data.dir} specifies
#' an alternative directory manually as a character string (absolute file path). The directory will be created if it doesn't already
#' exist. Its path is stored as an R option: to check the current setting for data.dir, run \code{getOption('rasterbc.data.dir')}
#'
#' @param data.dir A character string, providing the absolute path to the desired storage directory
#' @param suppress.warning A boolean indicating whether to warn if selecting directory that already contains files
#'
#' @return character string, the absolute path to the selected storage directory
#'
#' @importFrom utils choose.dir
#' @export
#' @examples
#' datadir_bc()
datadir_bc = function(data.dir=NULL, suppress.warning=FALSE)
{
  # storage directory set automatically by rappdirs unless user sets select=TRUE
  if(is.null(data.dir))
  {
    # rappdirs picks a sensible (platform-dependent) directory
    data.dir = rappdirs::user_data_dir('rasterbc')

  }

  # if the last character is a forward-slash, remove it
  last.char = substr(data.dir, nchar(data.dir), nchar(data.dir))
  if(last.char=='/')
  {
    data.dir = substr(data.dir, 1, nchar(data.dir)-1)
  }

  # create the directory as needed
  print(paste('data storage path set to:', data.dir))
  if(!dir.exists(data.dir))
  {
    dir.create(data.dir, recursive=TRUE)
    print(paste('directory created'))

  } else {

    print(paste('directory exists'))
    if(length(dir(data.dir, all.files=TRUE)) > 2 & !suppress.warning)
    {
      warning('warning: this directory appears to be non-empty. Contents may be overwritten!')

    }
  }

  # set the option and finish
  options('rasterbc.data.dir'=data.dir)
  return(data.dir)
}
