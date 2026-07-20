#!/usr/bin/env bash
set -euo pipefail

if (( $# < 2 )); then
  printf 'Usage: %s IMAGE.sif SCRIPT.R [script arguments ...]\n' "$0" >&2
  exit 2
fi

image="$1"
script="$2"
shift 2

if command -v module >/dev/null 2>&1; then
  module load singularity
fi

scratch_root="${TMPDIR:-${TMP:-/tmp}}"
job_id="${LSB_JOBID:-interactive}"
container_tmp="$scratch_root/r460-singularity-$job_id"
mkdir -p "$container_tmp"

export SINGULARITYENV_TMPDIR="$container_tmp"
export SINGULARITYENV_TEMP="$container_tmp"
export SINGULARITYENV_TMP="$container_tmp"

singularity exec \
  --cleanenv \
  --bind "$PWD:$PWD" \
  --pwd "$PWD" \
  "$image" \
  Rscript "$script" "$@"
