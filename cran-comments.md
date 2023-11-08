## Comments for CRAN maintainers:

This v1.0.2 update fixes raster download URLs that were broken by a recent change to endpoint domains at Globus.ca

The updated package now uses permanent links that redirect to the correct location. This should prevent the problem from happening again in the future.

## Check results

The package passed check with no ERRORS, WARNINGS, or NOTES in the following test environments:

* my workstation
    * Windows 10 (x86_64-w64-mingw32 64-bit), R version 4.3.1 (2023-06-16 ucrt)
* Winbuilder with
    * Windows Server 2008 (64-bit), R-release 4.1.2 (2021-11-01)
    * Windows Server 2022, R-devel (2022-01-16 r81507 ucrt)
* R-hub
    * macOS 10.13.6 High Sierra, R-release, CRAN's setup 
    * Debian Linux, R-devel, GCC

## Downstream dependencies

There are currently no downstream dependencies for this package
