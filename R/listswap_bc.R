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
#' @export
#' @keywords internal
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
      if(class(input.list) != 'character')
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


