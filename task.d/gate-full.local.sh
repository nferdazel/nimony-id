#!/usr/bin/env sh
# nimony-id test hook for `./task gate-full`: verify the samples at the pinned toolchain and render
# the book, which is what the `book` CI job proves. Needs Quarto and the Nimony build; a missing
# toolchain fails the gate rather than claiming the book was built.
set -eu
cd "$(dirname "$0")/.."

command -v "${QUARTO:-quarto}" >/dev/null 2>&1 || {
  printf '   quarto not installed: cannot build the book here\n' >&2
  exit 1
}
sh ./task verify
sh ./task build
