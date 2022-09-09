#!/usr/bin/env bash
#
# Usage: bld [--run|--help] [<target>...]
set -euo pipefail

prj_root=${PRJ_ROOT:-$(git rev-parse --show-toplevel)}
cache_dir=$prj_root/.cache/bld

log() {
  echo "bld: $*" >&2
}

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
  attr=${path#"$prj_root"}
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
}

cmd_build() {
  local args=(
    "-f" "<prj_root>"
    --extra-experimental-features nix-command
    -L --out-link "${cache_dir}/result-$1"
    --builders ''
    --print-out-paths
    "${nix_opts[@]}"
  )
  for attr in "$@"; do
    args+=("${attr}")
  done
  nix build "${args[@]}"
}

nix_system=$HOSTTYPE-${OSTYPE//-gnu/}
# don't use NIX_PATH
export NIX_PATH=
nix_opts=(
  --argstr system "$nix_system"
  --include "prj_root=$prj_root"
  --option allow-import-from-derivation false
  --option allowed-uris "https://"
  # --option pure-eval true
  --option restrict-eval true
)
attrs=()
cmd=build

# Options parsing
while [[ $# -gt 0 ]]; do
  case "$1" in
  --help)
    head -n 4 "${BASH_SOURCE[0]}" | tail -n 1
    exit
    ;;
  --run)
    cmd=run
    shift
    ;;
  --list)
    cmd=list
    shift
    ;;
  --interactive)
    cmd=interactive
    shift
    ;;
  --)
    break
    ;;
  -*)
    echo "ERROR: Unknown option $1"
    exit 1
    ;;
  :)
    cmd=list
    ;;
  :*)
    cmd=run
    attr=$(target_to_attr "${1#:}")
    attrs+=("${attr}")
    shift
    ;;
  *)
    attr=$(target_to_attr "$1")
    attrs+=("${attr}")
    shift
    ;;
  esac
done

# TODO: fix unbound on empty array
if [[ ${#attrs[@]} == 0 ]]; then
  attrs=("$(target_to_attr .)")
fi

log "prj_root=$prj_root cmd=$cmd attrs=${attrs[*]}"

case "$cmd" in
build)
  cmd_build "${attrs[@]}"
  ;;
list | interactive)
  args=(
    "${nix_opts[@]}" --impure --expr "(import <prj_root> {})._list \"$PWD\""
  )
  targets="$(nix eval "${args[@]}" | xargs)"
  if [[ $cmd == "list" ]]; then
	  echo -e "$targets"
  else
	  target="$(echo -e "$targets" | fzf)"
	  bld "$target"
  fi
  ;;
run)
  if [[ ${#attrs[@]} != 1 ]]; then
    log "too many attrs: ${#attrs}"
    exit 1
  fi
  cmd_build "${attrs[@]}"
  args=(
    "${nix_opts[@]}" --eval --expr " (import <prj_root> {})._run \"${attrs[0]}\""
  )
  log "running: ${args[*]@Q}"
  exe_path=$(nix-instantiate "${args[@]}" | xargs)
  exec "$exe_path" "$@"
  ;;
*)
  log "command $cmd not supported"
  exit 1
  ;;
esac
