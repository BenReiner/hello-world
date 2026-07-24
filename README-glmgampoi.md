# R 4.6 spatial/single-cell + glmGamPoi Singularity image

This project builds a self-contained, CPU-only, amd64
Singularity/Apptainer image for PMACS. It preserves the complete validated
Ubuntu 24.04 and R 4.6.0 spatial/single-cell stack from the prior image and
adds the released Bioconductor 3.23 build of `glmGamPoi` 1.24.0 plus every
required `Depends`, `Imports`, and `LinkingTo` package.

Optional `Suggests` packages are not installed merely because they are listed
for examples, benchmarking, or vignette generation. The required runtime and
compilation dependency graph is complete.

## Included top-level software

| Component | Version / source |
|---|---|
| Ubuntu | 24.04 LTS, OCI base pinned by digest |
| R | 4.6.0, compiled from the verified CRAN source tarball |
| CRAN snapshot | Posit Package Manager, 2026-06-01 |
| Bioconductor | 3.23, the release for R 4.6 |
| glmGamPoi | 1.24.0, source tarball pinned by SHA-256 |
| tidyverse | 2.0.0 |
| sf | 1.1-1 |
| arrow | 24.0.0 |
| hdf5r | 1.3.12 |
| ggplot2 | 4.0.3 |
| Seurat | 5.5.0 |
| SeuratObject | 5.4.0 |
| sp | 2.2-1 |
| dplyr | 1.2.1 |
| future | 1.70.0 |

The build fails unless R, Bioconductor, `glmGamPoi`, and every original
top-level R package match the requested versions. Complete Debian and R
package manifests are stored under `/opt/container-metadata`.

## Reproducibility decisions

- The definition starts from the exact Ubuntu 24.04 digest used by the
  validated prior image.
- R 4.6.0 and `glmGamPoi` 1.24.0 source downloads are checked before use.
  The `glmGamPoi` SHA-256 is
  `faf17f91e8e84a6cb455c7588df352f24da2f5a07e7d4ab8a3b654889a1e7492`.
- The original CRAN packages continue to come from the dated 2026-06-01
  snapshot.
- Bioconductor packages are resolved exclusively from release 3.23.
  `update = FALSE` prevents Bioconductor installation from replacing the
  prior pinned CRAN stack.
- Apache Arrow C++ and R `arrow` remain pinned to 24.0.0.
- The image is compiled without `-march=native`, so it remains portable across
  x86_64 PMACS compute nodes.

## Download and use on PMACS

Download the SIF and its `.sha256` file from the matching GitHub Release, then
place them in the same directory:

```bash
sha256sum -c \
  r460-spatial-singlecell-glmgampoi-ubuntu24-amd64.sif.sha256

module load singularity

singularity test --cleanenv \
  r460-spatial-singlecell-glmgampoi-ubuntu24-amd64.sif

singularity exec --cleanenv \
  r460-spatial-singlecell-glmgampoi-ubuntu24-amd64.sif \
  Rscript analysis.R
```

Only load the host's Singularity module. Do not load PMACS R, GCC, HDF5,
Python, or FFTW modules into this self-contained image.

For paths not visible by default, add explicit bind mounts:

```bash
singularity exec --cleanenv \
  --bind /project/path,/scratch/path \
  r460-spatial-singlecell-glmgampoi-ubuntu24-amd64.sif \
  Rscript analysis.R
```

For an LSF job, request the intended CPU count normally. In R:

```r
workers <- as.integer(Sys.getenv("LSB_DJOB_NUMPROC", "1"))
future::plan(future::multisession, workers = workers)
```

## Build

The GitHub Actions workflow compiles the image with Apptainer 1.5.2, tests it
as an ordinary user, and publishes the SIF, SHA-256, definition, manifests,
inspection output, and validation log in an immutable release.

For a local privileged build:

```bash
sudo apptainer build \
  r460-spatial-singlecell-glmgampoi-ubuntu24-amd64.sif \
  r460-spatial-singlecell-glmgampoi-ubuntu24.def

apptainer test --cleanenv \
  r460-spatial-singlecell-glmgampoi-ubuntu24-amd64.sif
```

The generic prior `build-remote.sh` can also be given the two new filenames:

```bash
./build-remote.sh \
  r460-spatial-singlecell-glmgampoi-ubuntu24.def \
  r460-spatial-singlecell-glmgampoi-ubuntu24-amd64.sif
```

## Validation

`singularity test` first repeats every validation from the prior image:

- `sf` coordinate transformation;
- Arrow/Parquet/Dataset round-trip and aggregation;
- HDF5 write/read;
- `ggplot2` PNG output;
- Seurat normalization, feature selection, scaling, and PCA; and
- a `future` computation.

It then validates:

- R 4.6.0, Bioconductor 3.23, and `glmGamPoi` 1.24.0;
- dense and sparse Gamma-Poisson model fits;
- an HDF5-backed, on-disk Gamma-Poisson model fit;
- agreement of dense, sparse, and on-disk coefficient estimates; and
- `sctransform` use of the `glmGamPoi` backend.

## Primary upstream references

- [Bioconductor 3.23 installation](https://www.bioconductor.org/install/)
- [glmGamPoi 1.24.0](https://www.bioconductor.org/packages/3.23/bioc/html/glmGamPoi.html)
- [R 4 source archive](https://cran.r-project.org/src/base/R-4/)
- [Apache Arrow R installation](https://arrow.apache.org/docs/r/articles/install.html)
- [Apptainer installation](https://apptainer.org/docs/admin/main/installation.html)
