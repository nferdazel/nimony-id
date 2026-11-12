#!/usr/bin/env bash
# Verify every book sample compiles and runs on the pinned Nimony toolchain.
#
# Toolchain install (fixed path, outside the system temp directory):
#   $HOME/.local/opt/nimony/4ba90a7
# Pinned commit: 4ba90a781b0b22d0821efaa153c129c37cef6143 (nimony 0.6.3)
# Host compiler used for the build: official Nim 2.4.0 at $HOME/.local/opt/nim-2.4.0
#
# Rebuild if the install is missing:
#   cd $HOME/.local/opt/nimony/4ba90a7
#   PATH=$HOME/.local/opt/nim-2.4.0/bin:$PATH nim c -r src/hastur/hastur build all
#
# Usage: tools/verify-samples.sh
# Exit: 0 all samples pass (or none exist), 1 a sample failed, 2 toolchain problem.

set -u
shopt -s nullglob

PIN="4ba90a781b0b22d0821efaa153c129c37cef6143"
PIN_VERSION="0.6.3"
NIMONY_HOME="${NIMONY_HOME:-$HOME/.local/opt/nimony/4ba90a7}"
NIMONY="$NIMONY_HOME/bin/nimony"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
LOG="$ROOT/tools/verify-samples.log"

if [ ! -x "$NIMONY" ]; then
  echo "FAIL toolchain missing: $NIMONY"
  echo "     rebuild: see the header of this script"
  exit 2
fi

version="$("$NIMONY" --version 2>&1 | head -n 1)"
case "$version" in
  "$PIN_VERSION "*|"$PIN_VERSION") ;;
  *)
    echo "FAIL toolchain version: expected $PIN_VERSION, got: $version"
    exit 2
    ;;
esac

if [ ! -d "$NIMONY_HOME/.git" ]; then
  echo "FAIL toolchain is not a git checkout: $NIMONY_HOME"
  exit 2
fi

head_commit="$(git -C "$NIMONY_HOME" rev-parse HEAD 2>/dev/null || true)"
if [ "$head_commit" != "$PIN" ]; then
  echo "FAIL toolchain commit: expected $PIN, got: ${head_commit:-unknown}"
  exit 2
fi

echo "toolchain $NIMONY $PIN_VERSION pin ${PIN:0:7}"

files=("$ROOT"/samples/*/*.nim)
if [ ${#files[@]} -eq 0 ]; then
  echo "SKIP no sample files under samples/*/*.nim"
  exit 0
fi

: > "$LOG"
pass=0
fail=0

for file in "${files[@]}"; do
  rel="${file#"$ROOT"/}"
  output="$(cd "$ROOT" && "$NIMONY" c -r "$rel" 2>&1)"
  code=$?

  {
    echo "===== $rel (exit $code) ====="
    printf '%s\n' "$output"
    echo
  } >> "$LOG"

  if [ $code -eq 0 ]; then
    echo "PASS $rel exit=$code"
    pass=$((pass + 1))
  else
    echo "FAIL $rel exit=$code"
    printf '%s\n' "$output" | tail -n 40 | sed 's/^/     /'
    echo "     full transcript: ${LOG#"$ROOT"/}"
    fail=$((fail + 1))
  fi
done

echo "SUMMARY $pass/${#files[@]} passed, $fail failed"
[ $fail -eq 0 ]
