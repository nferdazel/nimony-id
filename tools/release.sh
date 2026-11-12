#!/usr/bin/env sh
# Bump the version from the commit history, then commit and tag.
#
#   ./task release               bump level derived from commit messages
#   ./task release --patch       force PATCH
#   ./task release --minor       force MINOR
#   ./task release --major       force MAJOR
#   ./task release --skip-check  skip ./task check (not recommended)
#
# Conventional Commits mapping:
#   BREAKING CHANGE / type!:   MAJOR
#   feat:                      MINOR
#   anything else              PATCH
#
# Same shape as nim-id's release, without the PDF step: this book publishes HTML.
# POSIX sh plus git, no dependency. CI checks that a pushed tag matches VERSION.
set -eu

root="$(CDPATH= cd -- "$(dirname "$0")/.." && pwd)"
cd "$root"

forced=""
skip_check=""
for a in "$@"; do
  case "$a" in
    --major | --minor | --patch) forced="${a#--}" ;;
    --skip-check) skip_check=1 ;;
    *)
      echo "unknown argument: $a" >&2
      exit 2
      ;;
  esac
done

git rev-parse --git-dir >/dev/null 2>&1 || { echo "not a git repository" >&2; exit 1; }

if [ -n "$(git status --porcelain)" ]; then
  echo "work tree is not clean. commit or stash first:" >&2
  git status --short >&2
  exit 1
fi

old=$(tr -d '[:space:]' < VERSION)
last_tag=$(git describe --tags --abbrev=0 --match 'v[0-9]*' 2>/dev/null || true)

if [ -n "$last_tag" ]; then
  range="$last_tag..HEAD"
  count=$(git rev-list --count "$range")
else
  range="HEAD"
  count=$(git rev-list --count HEAD)
fi

if [ "$count" = 0 ]; then
  echo "no commits since ${last_tag:-the first commit}; nothing to release" >&2
  exit 1
fi

subjects=$(git log "$range" --pretty='%s')
bodies=$(git log "$range" --pretty='%b')

major=0
minor=0
if printf '%s\n' "$subjects" | grep -Eq '^[A-Za-z]+(\([^)]*\))?!: ' || \
   printf '%s\n' "$bodies" | grep -Eq '^BREAKING[ -]CHANGE:'; then
  major=1
elif printf '%s\n' "$subjects" | grep -Eq '^feat(\([^)]*\))?: '; then
  minor=1
fi

if [ -n "$forced" ]; then
  bump="$forced"
elif [ "$major" = 1 ]; then
  bump=major
elif [ "$minor" = 1 ]; then
  bump=minor
else
  bump=patch
fi

n_major=${old%%.*}
rest=${old#*.}
n_minor=${rest%%.*}
n_patch=${rest#*.}

for n in "$n_major" "$n_minor" "$n_patch"; do
  case "$n" in
    '' | *[!0-9]*)
      echo "VERSION is not valid: '$old' (expected MAJOR.MINOR.PATCH)" >&2
      exit 1
      ;;
  esac
done

new_major=$n_major
new_minor=$n_minor
new_patch=$n_patch
case "$bump" in
  major)
    new_major=$((n_major + 1))
    new_minor=0
    new_patch=0
    ;;
  minor)
    new_minor=$((n_minor + 1))
    new_patch=0
    ;;
  patch) new_patch=$((n_patch + 1)) ;;
esac

new="$new_major.$new_minor.$new_patch"
tag="v$new"

if git rev-parse -q --verify "refs/tags/$tag" >/dev/null; then
  echo "tag $tag already exists; check VERSION and the tags" >&2
  exit 1
fi

echo "commits since ${last_tag:-the first commit}: $count"
echo "bump: $bump  ->  $old -> $new"
printf '%s\n' "$subjects" | grep -E '^(feat|fix|docs|chore|refactor|test|style|perf)[^ ]*: |!:' | sed 's/^/  /' || true

# VERSION is written before the gate: if the gate fails, the bump is already on
# disk and the dirty tree is the honest signal that the release did not finish.
printf '%s\n' "$new" > VERSION

if [ -z "$skip_check" ]; then
  echo "running the ./task check gate ..."
  sh ./task check
fi

git add VERSION
git commit -m "chore: release $new" >/dev/null
git tag -a "$tag" -m "nimony-id $new"

echo
echo "done: commit and tag $tag created (not pushed)."
echo "push in one go:  git push origin main --follow-tags"
