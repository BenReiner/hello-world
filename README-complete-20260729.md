# Complete R 4.6 spatial/single-cell Singularity image

This project builds a self-contained, CPU-only, amd64
Singularity/Apptainer image for PMACS. It preserves the previously validated
Ubuntu 24.04, R 4.6.0, Seurat, Arrow, spatial, `glmGamPoi`, HTSlib, igraph,
`Rhtslib`, and `scDblFinder` stack and adds `scCustomize`, Cairo, and all hard
dependencies. Both `python3` and the compatibility command `python` invoke the
container's Python 3 interpreter.

The system HTSlib 1.24 installation is compiled from the checksum-verified
upstream source and provides `libhts.so.3`, headers, the static and unversioned
libraries, `htslib.pc`, `bgzip`, `htsfile`, and `tabix`. This preserves the
OpenSSL-flavored curl development stack required by Apache Arrow 24 on Ubuntu
24.04. R `Rhtslib` separately provides its private HTSlib 1.18 library.

The image's `%test` section checks exact package versions and functional
operation of the original analytical stack plus:

- system HTSlib and igraph compile/link/runtime tests;
- Cairo PNG generation;
- a `glmGamPoi` model fit;
- the `Rhtslib` private library and version;
- a deterministic `scDblFinder` run; and
- loading and exported-function checks for `scCustomize`.

## Download and validate

Download the SIF and its `.sha256` file from the matching GitHub Release, then:

```bash
sha256sum -c r460-spatial-singlecell-ubuntu24-complete-amd64.sif.sha256

module load singularity

singularity test --cleanenv \
  r460-spatial-singlecell-ubuntu24-complete-amd64.sif
```

Run an R script with:

```bash
singularity exec --cleanenv \
  r460-spatial-singlecell-ubuntu24-complete-amd64.sif \
  Rscript analysis.R
```

Only load the host Singularity module. Do not load host R, compiler, HDF5,
Python, or FFTW modules into this self-contained image.

If the release contains numbered `.part-*` files instead of one SIF, download
every part and reassemble them in lexical order before checking the full-image
SHA-256:

```bash
cat r460-spatial-singlecell-ubuntu24-complete-amd64.sif.part-* \
  > r460-spatial-singlecell-ubuntu24-complete-amd64.sif
sha256sum -c r460-spatial-singlecell-ubuntu24-complete-amd64.sif.sha256
```
