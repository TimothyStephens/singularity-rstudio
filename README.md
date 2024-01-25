# Singularity RStudio Server

Forked from https://github.com/j-andrews7/singularity-rstudio on 2024/01/25

This repo contains Singularity files that contains specific R versions and RStudio. Each also has several additional linux dependencies installed that are required for common bioinformatics packages (openssl, libproj, libbz2, etc).
This was mostly configured to run on HPCs in interactive jobs where users likely don't have the appropriate permissions for RStudio server to work properly.

In general, you can launch a script similar to those provided (`rstudio_v3.6.3`) from within an interactive job on your respective HPC to get it running, and it will print the IP address and port the server is running on that you can pop into your browser. The provided launch scripts will install/look for R packages in `${PWD}/rstudio-x.x.x/packages`, where `x.x.x` corresponds to the R version. Keeping installed packages in the working directory (rather then your /home) allows for projects to be kept independent and prevents package version conflicts.

## License

This repo is distributed under the GNU-GPL3 license. See the LICENSE file for more details.
