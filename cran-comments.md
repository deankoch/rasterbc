## Comments for CRAN maintainers:

Please note that the vignette for this package takes around 1-2 minutes to build, as it downloads several geoTIFF files, totalling 22MB, into a temporary directory. If that is too resource-heavy, or if it's more appropriate for this kind of data-retrieval package to pre-build its vignette (or disable checking, etc) please let me know how proceed with that.

## R CMD check results

I have run check on my Windows 10 machine, as well as Winbuilder, and R-hub on the linux platform. There were no errors, warnings, or notes

## Downstream dependencies

There are currently no downstream dependencies for this package
