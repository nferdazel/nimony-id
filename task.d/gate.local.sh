#!/usr/bin/env sh
# nimony-id static checks for `./task gate`: every python tool parses, and the sample tree is not
# empty (an empty one would make `verify` green about nothing). No Quarto, no Nimony build: those
# stay in `book`, which gate-full drives.
set -eu
cd "$(dirname "$0")/.."

command -v python3 >/dev/null 2>&1 || {
  printf '   python3 not on PATH: lint skipped here (CI runs it)\n'
  exit 0
}
PYTHONDONTWRITEBYTECODE=1 python3 -m py_compile tools/*.py

found=$(find samples -mindepth 2 -maxdepth 2 -name '*.nim' -print -quit)
[ -n "$found" ] || { echo "   no sample files under samples/*/*.nim" >&2; exit 1; }
printf '   python tools parse, samples present\n'
