# R 4.6 spatial/single-cell + HTSlib + igraph + scDblFinder image

This project builds a self-contained, CPU-only, amd64
Singularity/Apptainer image for PMACS. It preserves the complete validated
Ubuntu 24.04, R 4.6.0, Seurat, Arrow, spatial, and `glmGamPoi` analytical
stack from the prior image and adds:

- system igraph 0.10.10 with runtime and development files;
- system HTSlib 1.19 with runtime and development files;
- Bioconductor `Rhtslib` 3.8.0 and its required dependencies; and
- Bioconductor `scDblFinder` 1.26.7 and its complete hard dependency graph.

Optional R `Suggests` packages used only for examples, vignettes, or
benchmark datasets are not installed automatically. All `Depends`, `Imports`,
and `LinkingTo` dependencies required for normal package operation are
included.

## Included top-level software

| Component | Version / source |
|---|---|
| Ubuntu | 24.04 LTS, OCI base pinned by digest |
| R | 4.6.0, compiled from verified CRAN source |
| CRAN snapshot | Posit Package Manager, 2026-06-01 |
| Bioconductor | 3.23, the release for R 4.6 |
| System igraph | 0.10.10 (`libigraph-dev` and `libigraph3t64`) |
| System HTSlib | 1.19 (`libhts-dev` local compatible repack and official `libhts3t64`) |
| HTS codecs development library | 1.6.0 (`libhtscodecs-dev`) |
| Rhtslib | 3.8.0, source tarball pinned by SHA-256 |
| Rhtslib private HTSlib | 1.18 |
| scDblFinder | 1.26.7, source tarball pinned by SHA-256 |
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
| R igraph | 2.3.2 |

The build fails unless every named version and every functional validation
gate passes. Complete Debian and R package manifests are stored under
`/opt/container-metadata`.

## Ubuntu 24.04 package names

Ubuntu 24.04 uses time64-transition names for the two runtime packages:

- `libigraph3t64` provides the requested `libigraph3` ABI and
  `libigraph.so.3`;
- `libhts3t64` provides the requested `libhts3` ABI and `libhts.so.3`.

The corresponding development packages retain their expected names:
`libigraph-dev` and `libhts-dev`.

Ubuntu's official `libhts-dev` package hard-depends on
`libcurl4-gnutls-dev`, while Apache Arrow 24's `libarrow-dev` package
hard-depends on the mutually exclusive `libcurl4-openssl-dev`. To retain
every package from the prior image, this recipe downloads Noble's exact
`libhts-dev` 1.19 binary package, verifies its SHA-256, and creates a
transparent local Debian repack named
`1.19+ds-1.1build3+codex1`. The headers, static library, linker symlink,
and `pkg-config` data are unchanged; only the development-package
dependency is changed to `libcurl4-openssl-dev`.

The official `libhts3t64` runtime package remains unmodified. Its
GnuTLS-flavored libcurl runtime can coexist with Arrow's OpenSSL-flavored
runtime. `libhtscodecs-dev` is included so the HTSlib static archive has a
complete development link path. `dpkg --audit`, dynamic and static
compilation/link tests, R's libcurl capability, and every prior analytical
package are all retested.

## Two intentional HTSlib installations

The image contains two distinct HTSlib builds:

1. System HTSlib 1.19 is installed by Ubuntu and exposed through
   `libhts.so.3`, headers, the static archive, and `htslib.pc`.
2. R `Rhtslib` 3.8.0 carries a private HTSlib 1.18 build used by
   Bioconductor packages such as `Rsamtools`.

The validation suite tests both independently. System C code compiles and
links dynamically against HTSlib 1.19. `Rsamtools` performs a SAM-to-BAM
round trip through the private `Rhtslib` HTSlib 1.18 build.

## Reproducibility

- The Ubuntu base image is pinned by digest.
- R 4.6.0, `glmGamPoi` 1.24.0, `Rhtslib` 3.8.0, and
  `scDblFinder` 1.26.7 source downloads are pinned by SHA-256.
- Original CRAN packages continue to come from the dated 2026-06-01
  snapshot.
- Bioconductor packages are resolved only from release 3.23.
- `update = FALSE` prevents the Bioconductor installation from upgrading the
  original pinned CRAN stack.
- Ubuntu igraph and HTSlib packages are version-gated during the build;
  the original `libhts-dev` Debian payload is pinned by SHA-256 before
  its documented dependency-only repack.
- Apache Arrow C++ and R `arrow` remain pinned to 24.0.0.
- Compilation does not use `-march=native`, preserving portability across
  x86_64 PMACS compute nodes.

## Download and use on PMACS

Download the SIF and matching `.sha256` file from the release and place them
in the same directory:

```bash
sha256sum -c \
  r460-spatial-singlecell-htslib-igraph-scdblfinder-ubuntu24-amd64.sif.sha256

module load singularity

singularity test --cleanenv \
  r460-spatial-singlecell-htslib-igraph-scdblfinder-ubuntu24-amd64.sif

singularity exec --cleanenv \
  r460-spatial-singlecell-htslib-igraph-scdblfinder-ubuntu24-amd64.sif \
  Rscript analysis.R
```

Only load the host's Singularity module. Do not load PMACS R, GCC, HDF5,
Python, or FFTW modules into this self-contained image.

For paths not visible by default, add explicit bind mounts:

```bash
singularity exec --cleanenv \
  --bind /project/path,/scratch/path \
  r460-spatial-singlecell-htslib-igraph-scdblfinder-ubuntu24-amd64.sif \
  Rscript analysis.R
```

For an LSF job, request the intended CPU count normally. In R:

```r
workers <- as.integer(Sys.getenv("LSB_DJOB_NUMPROC", "1"))
future::plan(future::multisession, workers = workers)
```

## Build

The GitHub Actions workflow compiles the image with Apptainer 1.5.2, tests
it as an ordinary user, and publishes the SIF, SHA-256, definition,
manifests, inspection output, and validation logs in an immutable release.

For a local privileged build:

```bash
sudo apptainer build \
  r460-spatial-singlecell-htslib-igraph-scdblfinder-ubuntu24-amd64.sif \
  r460-spatial-singlecell-htslib-igraph-scdblfinder-ubuntu24.def

apptainer test --cleanenv \
  r460-spatial-singlecell-htslib-igraph-scdblfinder-ubuntu24-amd64.sif
```

The remote-build helper uses the new filenames by default:

```bash
./build-remote.sh
```

## Validation

`singularity test` repeats every validation from the prior image:

- `sf` coordinate transformation;
- Arrow/Parquet/Dataset round trip and aggregation;
- HDF5 write/read;
- `ggplot2` PNG output;
- Seurat normalization, feature selection, scaling, and PCA;
- a `future` computation;
- dense, sparse, and HDF5-backed `glmGamPoi` fits; and
- `sctransform` with the `glmGamPoi` backend.

It additionally validates:

- exact system igraph and HTSlib Debian package versions;
- requested `libigraph3` and `libhts3` ABI providers;
- igraph and HTSlib headers and `pkg-config` metadata;
- compilation, linkage, and execution of small C programs against
  `libigraph.so.3`, `libhts.so.3`, and the static `libhts.a`;
- absence of unresolved shared-library dependencies;
- R `igraph` graph construction and connectivity;
- `Rhtslib` 3.8.0 and private HTSlib 1.18 files/version;
- an `Rsamtools` SAM-to-BAM round trip;
- `scDblFinder` clustering, artificial-doublet generation, xgboost scoring,
  thresholding, and output fields on deterministic mock data; and
- R's libcurl capability with the preserved OpenSSL development backend.

## Primary upstream references

- [Ubuntu libigraph-dev](https://packages.ubuntu.com/noble/amd64/libigraph-dev)
- [Ubuntu libhts-dev](https://packages.ubuntu.com/noble/amd64/libhts-dev)
- [Bioconductor Rhtslib](https://bioconductor.org/packages/release/bioc/html/Rhtslib.html)
- [Bioconductor scDblFinder](https://bioconductor.org/packages/release/bioc/html/scDblFinder.html)
- [Bioconductor 3.23 installation](https://www.bioconductor.org/install/)
- [Apache Arrow R installation](https://arrow.apache.org/docs/r/articles/install.html)
- [Apptainer installation](https://apptainer.org/docs/admin/main/installation.html)
