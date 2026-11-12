#!/usr/bin/env bash
# Render kedua edisi dan susun satu direktori siap-deploy, mengikuti nim-id:
#   public/         → Indonesia (akar situs)
#   public/en/      → English
#
# Sumber bab tetap di chapters/NN-slug/{en,id}.md (deviation 4). Frontmatter
# editorial di sana bukan YAML Quarto yang sah (tech_review memuat titik dua
# tanpa kutip), jadi tiap bahasa di-stage ke .build/<lang> tanpa mengubah
# sumbernya.
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"

QUARTO=${QUARTO:-quarto}
versi="$(tr -d '[:space:]' < VERSION)"
pin_quarto="1.10.19"

die() { echo "$*" >&2; exit 1; }

# Satu versi Quarto untuk laptop, CI dan VPS: nama PDF dan hasil render harus
# sama untuk satu commit, jadi versi lain ditolak alih-alih menghasilkan beda
# yang tidak kelihatan.
ada="$(command -v "$QUARTO" 2>/dev/null || true)"
[ -n "$ada" ] || die "requires '$QUARTO' on PATH, or set QUARTO=/path/to/quarto"
versi_quarto="$("$QUARTO" --version 2>/dev/null | head -n 1)"
[ "$versi_quarto" = "$pin_quarto" ] || \
  die "Quarto $pin_quarto diperlukan, yang ada: ${versi_quarto:-tidak terbaca} ($ada)"

awk_strip_frontmatter() {
  awk 'NR == 1 && $0 == "---" { front = 1; next }
       front == 1 && $0 == "---" { front = 0; next }
       front != 1 { print }' "$1"
}

# Footer, sidebar dan judul TOC mengikuti bahasa edisi; bab tetap satu daftar.
stage_book() {
  lang=$1
  stage="$root/.build/$lang"
  rm -rf "$stage"
  mkdir -p "$stage/chapters" "$stage/assets/typst"

  preface="$root/index.$lang.qmd"
  [ -f "$preface" ] || preface="$root/index.qmd"
  cp "$preface" "$stage/index.qmd"

  sed -e "s|/en\.md\$|/$lang.md|" \
      -e "s|^lang: en\$|lang: $lang|" \
      -e "s|^  language: en\$|  language: $lang|" \
      -e "s|^    lang: en\$|    lang: $lang|" \
      "$root/_quarto.yml" > "$stage/_quarto.yml"

  if [ "$lang" = "id" ]; then
    sed -e 's|^    toc-title: "On this page"$|    toc-title: "Di halaman ini"|' \
        -e 's|^    left: "CC BY-SA 4.0 · code samples MIT"$|    left: "CC BY-SA 4.0 · kode contoh MIT"|' \
        -e 's|^    right: "\[PDF\](https://nimony.qouver.com/en/Nimony-A-Pinned-Guide.pdf) · \[Bahasa Indonesia\](https://nimony.qouver.com/)"$|    right: "[PDF](https://nimony.qouver.com/Nimony-A-Pinned-Guide.pdf) · [English](https://nimony.qouver.com/en/)"|' \
        -e 's|^      - text: "Bahasa Indonesia"$|      - text: "English"|' \
        -e 's|^        href: "https://nimony.qouver.com/"$|        href: "https://nimony.qouver.com/en/"|' \
        "$stage/_quarto.yml" > "$stage/_quarto.yml.tmp"
    mv "$stage/_quarto.yml.tmp" "$stage/_quarto.yml"
    cp "$root/assets/skip-link.html" "$stage/assets/skip-link.html"
  else
    cp "$root/assets/skip-link-en.html" "$stage/assets/skip-link.html"
  fi

  cp "$root/assets/ku.css" "$stage/assets/ku.css"
  cp "$root/assets/typst/typst-show.typ" "$stage/assets/typst/typst-show.typ"
  printf 'version: "%s"\n' "$versi" > "$stage/_variables.yml"

  for src in "$root"/chapters/*/"$lang".md; do
    [ -f "$src" ] || continue
    slug=$(basename -- "$(dirname -- "$src")")
    mkdir -p "$stage/chapters/$slug"
    awk_strip_frontmatter "$src" > "$stage/chapters/$slug/$lang.md"
  done
}

require_pairs() {
  missing=0
  pairs=0
  for dir in "$root"/chapters/*/; do
    [ -d "$dir" ] || continue
    slug=$(basename -- "$dir")
    if [ -f "$dir/en.md" ] && [ ! -f "$dir/id.md" ]; then
      echo "chapters/$slug has en.md but no id.md; the book is bilingual, both are required" >&2
      missing=1
    elif [ -f "$dir/id.md" ] && [ ! -f "$dir/en.md" ]; then
      echo "chapters/$slug has id.md but no en.md; the book is bilingual, both are required" >&2
      missing=1
    elif [ -f "$dir/en.md" ]; then
      pairs=$((pairs + 1))
    fi
  done
  if [ "$pairs" -eq 0 ]; then
    echo "no chapter pairs under chapters/*/; refusing to render an empty book" >&2
    missing=1
  fi
  [ "$missing" -eq 0 ] || exit 1
}

require_pairs

stage_book en
stage_book id

( cd "$root/.build/en" && "$QUARTO" render )
( cd "$root/.build/id" && "$QUARTO" render )

# Tiap edisi menghasilkan tepat satu PDF. Nama bawaan Quarto mengikuti judul
# buku dan menabrak titik dua menjadi "Nimony--A-Pinned-Guide.pdf"; satu tanda
# hubung lebih enak dibaca, jadi berkasnya diganti nama di sini.
for lang in en id; do
  count=$(find "$root/.build/$lang/_book" -maxdepth 1 -name '*.pdf' | wc -l | tr -d ' ')
  [ "$count" = "1" ] || die "edisi $lang menghasilkan $count PDF, harus tepat 1"
  pdf=$(find "$root/.build/$lang/_book" -maxdepth 1 -name '*.pdf' -print -quit)
  tujuan="$root/.build/$lang/_book/Nimony-A-Pinned-Guide.pdf"
  [ "$pdf" = "$tujuan" ] || mv "$pdf" "$tujuan"
done

rm -rf "$root/public"
mkdir -p "$root/public/en"
cp -R "$root/.build/id/_book/." "$root/public/"
cp -R "$root/.build/en/_book/." "$root/public/en/"

for pdf in "$root/public/Nimony-A-Pinned-Guide.pdf" \
           "$root/public/en/Nimony-A-Pinned-Guide.pdf"; do
  [ -f "$pdf" ] || die "PDF tidak ada: ${pdf#"$root/"}"
done

[ -f "$root/public/index.html" ] || die "render Indonesia tidak menghasilkan index.html"
[ -f "$root/public/en/index.html" ] || die "render English tidak menghasilkan en/index.html"

# Cache busting: nama berkas CSS tetap (Quarto tidak memberi hash), sedangkan
# Cloudflare menyimpan aset berhari-hari. Sematkan versi di URL supaya rilis baru
# tidak memakai CSS lama.
find "$root/public" -name '*.html' -exec perl -pi -e \
  "s|assets/ku\.css|assets/ku.css?v=${versi}|g; s|\.pdf\"|.pdf?v=${versi}\"|g" {} +

# Skip-link: Quarto menaruhnya di dalam <main>, setelah sidebar. Pindahkan ke awal <body>.
( cd "$root" && python3 tools/fix-skip-link.py )

# Teks halaman tidak boleh menipu: akar situs adalah edisi Indonesia.
grep -q 'lang="id"' "$root/public/index.html" || die "akar situs bukan edisi Indonesia"
grep -q 'lang="en"' "$root/public/en/index.html" || die "public/en bukan edisi English"

# Tiap halaman membawa CSS berversi dan skip-link. Satu halaman yang lolos akan
# mematahkan paritas tanpa kelihatan di beranda.
if find "$root/public" -name '*.html' ! -exec grep -q "assets/ku.css?v=${versi}" {} \; -print | grep -q .; then
  die "ada halaman tanpa assets/ku.css?v=${versi}"
fi
if find "$root/public" -name '*.html' ! -exec grep -q 'class="quarto-skip-link"' {} \; -print | grep -q .; then
  die "ada halaman tanpa skip link"
fi

printf 'public/: %s berkas\n' "$(find "$root/public" -type f | wc -l | tr -d ' ')"
find "$root/public" -maxdepth 2 -name '*.pdf' | sed "s|^$root/|  |"
