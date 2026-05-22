#!/usr/bin/env bash
#
# linter.sh - run linters declared in .liszt/liszt.toml
#
# Reads a TOML file with one table per linter:
#
#   [linters.<name>]
#   cmd = "shell command to run"
#   enabled = true   # optional, defaults to true
#
# Runs each enabled linter in file order. Fail-fast: the first linter that
# exits non-zero aborts the run with that exit code.
#
# Usage: linter.sh [path/to/liszt.toml]   (default: .liszt/liszt.toml)
#
# Note: pure-bash TOML parsing. Handles flat [linters.NAME] tables with
# `cmd` and `enabled` keys only. Not a general TOML parser.

set -u

TOML_PATH="${1:-.liszt/liszt.toml}"

if [[ ! -f "$TOML_PATH" ]]; then
  echo "error: config not found: $TOML_PATH" >&2
  exit 1
fi

# Trim surrounding whitespace and matching quotes from a value.
strip_value() {
  local v="$1"
  v="${v#"${v%%[![:space:]]*}"}"   # ltrim
  v="${v%"${v##*[![:space:]]}"}"   # rtrim
  if [[ "$v" == \"*\" ]]; then
    v="${v#\"}"; v="${v%\"}"
  elif [[ "$v" == \'*\' ]]; then
    v="${v#\'}"; v="${v%\'}"
  fi
  printf '%s' "$v"
}

names=()
cmds=()
enabled=()
current=""

while IFS= read -r line || [[ -n "$line" ]]; do
  trimmed="${line#"${line%%[![:space:]]*}"}"
  [[ -z "$trimmed" || "$trimmed" == \#* ]] && continue

  if [[ "$trimmed" =~ ^\[linters\.([A-Za-z0-9_-]+)\][[:space:]]*$ ]]; then
    current="${BASH_REMATCH[1]}"
    names+=("$current")
    cmds+=("")
    enabled+=("true")   # default enabled
    continue
  elif [[ "$trimmed" =~ ^\[ ]]; then
    current=""           # some other table, ignore its keys
    continue
  fi

  [[ -z "$current" ]] && continue
  idx=$(( ${#names[@]} - 1 ))

  if [[ "$trimmed" =~ ^cmd[[:space:]]*=(.*)$ ]]; then
    cmds[$idx]="$(strip_value "${BASH_REMATCH[1]}")"
  elif [[ "$trimmed" =~ ^enabled[[:space:]]*=[[:space:]]*(true|false) ]]; then
    enabled[$idx]="${BASH_REMATCH[1]}"
  fi
done < "$TOML_PATH"

if [[ ${#names[@]} -eq 0 ]]; then
  echo "no linters defined in $TOML_PATH"
  exit 0
fi

for i in "${!names[@]}"; do
  name="${names[$i]}"
  cmd="${cmds[$i]}"
  en="${enabled[$i]}"

  [[ "$en" != "true" ]] && continue

  if [[ -z "$cmd" ]]; then
    echo "warn: linter '$name' has no cmd, skipping" >&2
    continue
  fi

  echo "▶ $name: $cmd"
  bash -c "$cmd"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "✗ linter '$name' failed (exit $rc)" >&2
    exit "$rc"
  fi
done

echo "✓ all linters passed"
