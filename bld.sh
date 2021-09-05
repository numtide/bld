#!/usr/bin/env bash
#
# Usage: bld [<target>...]
set -euo pipefail

prj_root=${PRJ_ROOT:-$(git rev-parse --show-toplevel)}

target_to_attr() {
  local path label attr

  # Use the : notation to select an attribute in a folder
  if [[ $1 == *:* ]]; then
    path=${1%:*}
    label=.${1#*:}
  else
    path=$1
    label=
  fi

  if [[ $path == //* ]]; then
    # Select a path relative to the project root using the // notation
    path=${prj_root}${path}
  elif [[ -z $path ]]; then
    # Use the current directory by default
    path=$PWD
  else
    # Make sure the path is absolute
    path=$(readlink -f "$path")
  fi

  # TODO: check that the path is in the project

  # Convert the path to an Nix attribute
  attr=${path#$prj_root}
  # Replace / with .
  attr=${attr//\//.}
  # Add the label
  attr="${attr}${label}"
  # HACK: remove multiple dots
  attr=${attr//../.}
  attr=${attr//../.}
  attr=${attr//../.}
  attr=${attr#.}
  echo "$attr"
  echo "target=$1 attr=$attr" >&2
}

nix_system=$HOSTTYPE-${OSTYPE//-gnu/}

build_opts=(
  "<prj_root>"
  --argstr system "$nix_system"
  --include "prj_root=$prj_root"
  --no-out-link
  --option allow-import-from-derivation false
  --option allowed-uris "https://"
  # --option pure-eval true
  --option restrict-eval true
)

# Options parsing
echo "prj_root=$prj_root" >&2

while [[ $# -gt 0 ]]; do
  case "$1" in
  -*)
    echo "ERROR: Unknown option $1"
    exit 1
    ;;
  *)
    attr=$(target_to_attr "$1")
    build_opts+=(
      "-A" "${attr}"
    )
    shift
    ;;

  esac
done

export NIX_PATH=
set -x
nix-build "${build_opts[@]}"
