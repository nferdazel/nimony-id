#!/usr/bin/env bash
# Attach the PDFs in public/ to a GitHub release, creating it if needed.
#
# Both PDFs share one file name and a release cannot hold two assets with the
# same name, so each copy gets a unique file name and the label the release
# lists. Re-running against an existing release replaces the assets instead of
# failing, so the tag build and the main-push parity step can both publish the
# same commit without racing.
#
#   tools/publish-release.sh <tag> [<target-commit>]
set -euo pipefail

tag="${1:?usage: publish-release.sh <tag> [<target-commit>]}"
target="${2:-}"

cd "$(dirname "$0")/.."

[ -f public/Nimony-A-Pinned-Guide.pdf ] || {
  echo "public/Nimony-A-Pinned-Guide.pdf is missing; run ./task build first" >&2
  exit 1
}
[ -f public/en/Nimony-A-Pinned-Guide.pdf ] || {
  echo "public/en/Nimony-A-Pinned-Guide.pdf is missing; run ./task build first" >&2
  exit 1
}

cp public/Nimony-A-Pinned-Guide.pdf public/Nimony-A-Pinned-Guide-ID.pdf
cp public/en/Nimony-A-Pinned-Guide.pdf public/Nimony-A-Pinned-Guide-EN.pdf

set -- \
  "public/Nimony-A-Pinned-Guide-ID.pdf#Nimony - A Pinned Guide (ID).pdf" \
  "public/Nimony-A-Pinned-Guide-EN.pdf#Nimony - A Pinned Guide (EN).pdf"

if gh release view "$tag" >/dev/null 2>&1; then
  gh release upload "$tag" "$@" --clobber
elif [ -n "$target" ]; then
  gh release create "$tag" "$@" --target "$target" --title "$tag" --generate-notes ||
    gh release upload "$tag" "$@" --clobber
else
  gh release create "$tag" "$@" --title "$tag" --generate-notes ||
    gh release upload "$tag" "$@" --clobber
fi

gh release view "$tag" --json tagName,assets \
  --jq '"release \(.tagName): " + ([.assets[] | "\(.name) (\(.size) B)"] | join(", "))'
