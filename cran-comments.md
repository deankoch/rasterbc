## Comments for CRAN maintainers:

This update is to switch to a precompiled vignette.

Previously, the vignette would download geoTIFF data from a web resource (at frdr.ca) to use in examples. Since this web
service is occasionally down for maintenance, there are times when the vignette cannot be re-built. This recently led to
a WARN result on CRAN's check.

The updated package fixes this problem by replacing the Rmd vignette file with one in which all images and output have been
pre-computed, so the web resource is no longer accessed. My thanks to the CRAN team for pointing out the issue

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
