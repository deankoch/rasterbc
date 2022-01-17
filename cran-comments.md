## Comments for CRAN maintainers:

This v1.0.1 update introduces a pre-compiled vignette.

Previously, the vignette would download geoTIFF data from a web resource (globus.ca) to use in examples. Since this web
service is occasionally unavailable, there are times when the vignette cannot be re-built. This recently led to WARN results
on CRAN's package check results.

This update fixes this problem by replacing the vignette file with one in which all images and output have been
pre-computed, so the web resource is no longer required. My thanks to the CRAN team for pointing out the issue.


## Check results

The package passed check with no ERRORS, WARNINGS, or NOTES in the following test environments:

* my workstation
    * Windows 10 (64-bit), R-release 4.1.2 (2021-11-01)
* Winbuilder with
    * Windows Server 2008 (64-bit), R-release 4.1.2 (2021-11-01)
    * Windows Server 2022, R-devel (2022-01-16 r81507 ucrt)
* R-hub
    * macOS 10.13.6 High Sierra, R-release, CRAN's setup 
    * Debian Linux, R-devel, GCC


## Downstream dependencies

There are currently no downstream dependencies for this package
