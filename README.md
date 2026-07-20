# R 4.6 spatial/single-cell Singularity image

This project builds one self-contained, CPU-only, amd64 Singularity/Apptainer
image for PMACS. The definition file is standalone: it can be built in GitHub
Actions, with the Sylabs Remote Builder, or by an administrator on a Linux
machine with Apptainer/Singularity.

## Included top-level software

| Component | Version / source |
|---|---|
| Ubuntu | 24.04 LTS, OCI base pinned by digest |
| R | 4.6.0, compiled from the verified CRAN source tarball |
| CRAN snapshot | Posit Package Manager, 2026-06-01 |
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

All required R dependencies are installed from the same dated source-package
snapshot. The build fails unless every top-level R version matches exactly.
The image also records complete Debian and R package manifests under
`/opt/container-metadata`.

## Resolution of the original package list

- `tidyverse`, `future`, `hdf5r`, `arrow`, and `sf` are R packages, not Debian
  packages. They are installed through R.
- Ubuntu's own repositories do not publish the requested
  `libarrow*`/`libparquet-dev` packages. The image adds Apache Arrow's official
  Ubuntu 24.04 repository and pins all five requested development packages to
  `24.0.0-1`. R `arrow` 24.0.0 is then compiled against that exact matching
  Arrow C++ installation, including the requested Flight development package.
- PMACS modules describe software on the host. They must not be loaded into this
  self-contained image. Ubuntu 24.04 supplies GCC 12.4, GFortran 13.3, HDF5
  1.10.10, Python 3.12, and FFTW 3.3.10. These satisfy the stated R stack; only
  FFTW is the exact PMACS module version.
- `libicu74`, `gcc-12`, `g++-12`, `gfortran-13`,
  `libgfortran-13-dev`, and the remaining compatible development packages from
  the request are installed from Ubuntu 24.04. The obsolete
  `libfreetype6-dev` name is replaced by its current package name,
  `libfreetype-dev`.

## Build

### GitHub Actions

The included workflow builds with Apptainer 1.5.2, runs the image's functional
test suite as an ordinary user, and publishes the SIF plus logs and checksums in
a GitHub Release. If the SIF exceeds GitHub's per-file release limit, the
workflow publishes 1,900 MiB parts.

For a split image, reassemble and validate it with:

```bash
cat r460-spatial-singlecell-ubuntu24-amd64.sif.part-* \
  > r460-spatial-singlecell-ubuntu24-amd64.sif
sha256sum -c r460-spatial-singlecell-ubuntu24-amd64.sif.sha256
```

### Sylabs Remote Builder

From this directory on PMACS:

```bash
module load singularity
./build-remote.sh
```

This requires a configured Sylabs remote endpoint. The definition file contains
its own install and validation scripts, so it can also be pasted directly into
the Sylabs Remote Builder interface.

### Local administrator build

```bash
sudo apptainer build \
  r460-spatial-singlecell-ubuntu24-amd64.sif \
  r460-spatial-singlecell-ubuntu24.def
apptainer test --cleanenv r460-spatial-singlecell-ubuntu24-amd64.sif
```

The build compiles R, its R package dependencies, and the R Arrow bindings from
source. Allow several hours, at least two CPU cores, and substantial temporary
disk.

## Use on PMACS

Only load the Singularity module on the host:

```bash
module load singularity
singularity test --cleanenv r460-spatial-singlecell-ubuntu24-amd64.sif
singularity exec --cleanenv \
  r460-spatial-singlecell-ubuntu24-amd64.sif \
  Rscript analysis.R
```

The helper applies a clean environment, binds the current directory, and gives
the container a writable temporary directory:

```bash
./run-pmacs.sh r460-spatial-singlecell-ubuntu24-amd64.sif analysis.R
```

For an LSF job, request the intended CPU count in the normal way. The `future`
and `parallelly` packages recognize LSF limits. An explicit R setup is:

```r
workers <- as.integer(Sys.getenv("LSB_DJOB_NUMPROC", "1"))
future::plan(future::multisession, workers = workers)
```

Bind project and scratch paths explicitly when they are not visible by default,
for example `--bind /project/path,/scratch/path`.

## Validation performed by the image

`singularity test` checks the exact OS, R, and R package versions, then runs:

- an `sf` coordinate-reference-system transformation;
- Arrow Parquet write/read and Dataset/dplyr aggregation;
- HDF5 write/read through `hdf5r`;
- PNG output through `ggplot2`;
- a small Seurat normalize/variable-feature/scale/PCA pipeline; and
- a `future` computation.

The definition deliberately avoids CPU-specific compiler flags such as
`-march=native`, making the result portable across x86_64 PMACS compute nodes.

## Primary upstream references

- [R 4 source archive](https://cran.r-project.org/src/base/R-4/)
- [Apache Arrow R installation guide](https://arrow.apache.org/docs/r/articles/install.html)
- [Apache Arrow C++ package repository instructions](https://arrow.apache.org/install/)
- [Apptainer installation guide](https://apptainer.org/docs/admin/main/installation.html)
- [SingularityCE quick start and remote builds](https://docs.sylabs.io/guides/latest/user-guide/quick_start.html)
