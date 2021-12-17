######################################################################
# precompute_vignette.R
# Build a copy of the rasterbc vignette_intro.Rmd file ahead of time
# based on: https://www.kloppenborg.ca/2021/06/long-running-vignettes/

# ####################################################################
#
# DESCRIPTION:
#
# This is to avoid problems with CRAN CMD check re-running the lengthy
# vignette code, which downloads several files from FRDR.
#
# Before this workaround, I would get WARNINGs from devtools::check_win_release()
# that I can't reproduce on my computer. I suspect this is a problem with write
# permissions on the servers running the checks. In any case we probably don't
# want to hammer the FRDR server with download requests whenever someone builds
# the vignette.
#
# Source this script to run the vignette and save the results to a
# new Rmd file in which there is no R code to execute, and all images
# and output have been pre-computed. The code will also render a markdown
# (md) file to publish on github
#
# ####################################################################
#
# INPUT:
#
# the source Rmd vignette file with filename extension orig
# located at <projdir>/<fname>.Rmd.orig
#
# OUTPUT:
#
# <projdir>/<fname>.Rmd, the new pre-built vignette Rmd file for CRAN
# <projdir>/<fname>.R, copy of the R code executed in the Rmd
# <projdir>/<fname>.md, a github-friendly markdown file
#
# ####################################################################
#
# INSTRUCTIONS:
#
# The workflow here is:
#
# (1) develop an .Rmd vignette file as usual in subdirectory vignettes/
# (2) rename it to have file extension .Rmd.orig
# (3) run this script to generate the .Rmd, .R, and .md files.
#
# This should be repeated after any edits to the vignette and/or after any
# update to the package (both to test the new code and to stamp the vignette
# with a fresh date). Remember it is the .Rmd.orig file that you want to
# edit when making changes to the vignette (not the Rmd file created by
# this script!)
#
# Remember also to check that the .R, .md, and .Rmd.orig files are listed
# in your .Rbuildignore file, so they don't get caught up in the package build.
#
# Once the Rmd file is created, you can preview it in RStudio with the
# "knit" button (which builds a temporary md for viewing). For some reason,
# opening the md file created in (3) and clicking the "preview" button
# produces an error about missing image files. However the relative file
# paths in the md file are correct, so the document will display properly
# on github.
#
# ####################################################################

# define the filename to work on (must be found in vignettes/)
vignettes.dir = 'I:/MPB_ARCHIVE/git-MPB/rasterbc/vignettes'
fname = 'vignette_intro'

# define paths of files to create
path.orig = file.path(vignettes.dir, paste0(fname, '.Rmd.orig'))
path.rmd = file.path(vignettes.dir, paste0(fname, '.Rmd'))
path.temp.rmd = file.path(vignettes.dir, paste0(fname, '_TEMPORARY.Rmd'))
path.r = file.path(vignettes.dir, paste0(fname, '.R'))
path.md = file.path(vignettes.dir, paste0(fname, '.md'))

# run the vignette and save result to the Rmd file (and save code to R file)
originalwd = getwd()
setwd(vignettes.dir)
knitr::knit(path.orig, output=path.rmd)
knitr::purl(path.orig, output=path.r)
setwd(originalwd)

# copy and modify the Rmd file (via tempfile) in order to generate the md output
file.copy(path.rmd, path.temp.rmd)
temp.rmd.contents = readLines(path.temp.rmd)
new.rmd.contents = gsub('output: rmarkdown::html_vignette', 'output: github_document', temp.rmd.contents)
writeLines(new.rmd.contents, path.temp.rmd)

# render the md file then delete the temporary source
originalwd = getwd()
knitr::knit(path.temp.rmd, output=path.md)
setwd(originalwd)
unlink(path.temp.rmd)
