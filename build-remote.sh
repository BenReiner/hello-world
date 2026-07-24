#!/usr/bin/env bash
set -euo pipefail

definition="${1:-r460-spatial-singlecell-htslib-igraph-scdblfinder-ubuntu24.def}"
image="${2:-r460-spatial-singlecell-htslib-igraph-scdblfinder-ubuntu24-amd64.sif}"

command -v singularity >/dev/null 2>&1 || {
  printf 'ERROR: singularity is not on PATH. Load the PMACS Singularity module first.\n' >&2
  exit 1
}

singularity build --remote "$image" "$definition"
singularity test --cleanenv "$image"
sha256sum "$image" > "$image.sha256"

printf 'Built and validated %s\n' "$image"
