## Comments for CRAN maintainers:

Version 1.0.2 fixes raster download URLs that were broken by a recent change to endpoint domains at the Globus server. The updated package now uses permanent links that redirect to the correct location. This should prevent the problem from happening again in the future.

## Check results

The package passed check with 0 ERRORS, WARNINGS, or NOTES in the following test environments:

* with devtools::check()
    * Windows 10 64 bit, R-release version 4.3.1 (2023-06-16 ucrt)
    
* with devtools::check_win_devel()
    * Windows Server 2022 64bit (build 20348), R-devel (2023-11-08 r85496 ucrt)
    
* with rhub::check_for_cran()
    * Ubuntu Linux 20.04.1 LTS, R-release 4.3.2 (2023-10-31)
    * Windows Server 2022 x64 (build 20348), R-devel (2023-10-14 r85331 ucrt)
    * Fedora Linux 36, R-devel (2023-11-07 r85491)
    
## Downstream dependencies

There are currently no downstream dependencies for this package
