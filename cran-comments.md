## Comments for CRAN maintainers:

This is my first submission to CRAN.

Please note that the vignette for this package took around 20-40 seconds to build, as it downloads several geoTIFF files, totalling 22MB, into a temporary directory. If that is too resource-heavy, or if it's more appropriate for this kind of data-retrieval package to pre-build its vignette (or disable checking, etc) please let me know how proceed with that.

## R CMD check results

I have run check on my Windows 10 machine with R version 4.1.2 and on R-hub with the development version of R in the Debian Linux environment. There were no ERRORs, WARNINGs, or NOTEs.

On Winbuilder with the development version of R, I get 0 ERRORs, 0 WARNINGs, and 1 NOTE about misspelled words:

* Possibly misspelled words in DESCRIPTION:
  Albers (7:55)
  Beaudoin (9:59)
  FIDS (10:39)
  FRDR (7:124, 12:15)
  al (9:15, 9:71)
  biogeoclimatic (8:71)
  cutblocks (8:102)
  et (9:12, 9:68)
  rasterized (9:116)
  
These are proper names, abbreviations and technical terminology. All are spelled correctly.

## Downstream dependencies

There are currently no downstream dependencies for this package
