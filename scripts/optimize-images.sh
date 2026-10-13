#!/bin/bash
# Optimize blog images: resize to a maximum edge length, recompress, and
# generate small thumbnails for post listings.
#
# Usage:
#   scripts/optimize-images.sh [path ...]
#
#   path         Files or directories to resize. Directories are searched
#                recursively. Defaults to assets/images/posts.
#
# Environment overrides:
#   MAX_EDGE      Longest edge for full-size images (default 1600)
#   THUMB_EDGE    Longest edge for listing thumbnails (default 720)
#   JPG_QUALITY   JPEG quality 1-100 (default 80)
#   PNG_QUALITY   PNG compression 1-100 (default 90)
#
# Thumbnails are written as "<name>-thumb.<ext>" next to every image used as a
# post cover (the `image:` front matter) or the site logo, and are referenced
# by _includes/post-thumbnail.html. Full-size images already within MAX_EDGE
# are left untouched, so re-running is a no-op.
#
# Run this after adding a new post image, before committing.

set -euo pipefail

BLOG_DIR="$(cd "$(dirname "$0")/.." && pwd)"

MAX_EDGE="${MAX_EDGE:-1600}"
THUMB_EDGE="${THUMB_EDGE:-720}"
JPG_QUALITY="${JPG_QUALITY:-80}"
PNG_QUALITY="${PNG_QUALITY:-90}"

# ImageMagick 7 ships `magick`, ImageMagick 6 ships `convert`.
if command -v magick >/dev/null 2>&1; then
  IM="magick"
elif command -v convert >/dev/null 2>&1; then
  IM="convert"
else
  echo "Error: ImageMagick (magick or convert) is required." >&2
  exit 1
fi

size_of() { stat -c %s "$1" 2>/dev/null || stat -f %z "$1"; }

# Longest edge of an image (0 if it cannot be read).
long_edge_of() {
  identify -format '%[fx:max(w,h)]' "$1" 2>/dev/null \
    || magick identify -format '%[fx:max(w,h)]' "$1" 2>/dev/null \
    || echo 0
}

# "jpg" | "png" | "" for a file path.
format_of() {
  case "$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')" in
    *.jpg|*.jpeg) echo jpg ;;
    *.png) echo png ;;
    *) echo "" ;;
  esac
}

# resize_and_recompress <src> <dst> <fmt> <edge>
resize_and_recompress() {
  if [ "$3" = "jpg" ]; then
    $IM "$1" -auto-orient -strip -sampling-factor 4:2:0 -interlace Plane \
      -resize "${4}x${4}>" -quality "$JPG_QUALITY" "$2"
  else
    $IM "$1" -auto-orient -strip \
      -resize "${4}x${4}>" -quality "$PNG_QUALITY" "$2"
  fi
}

# ── Resize oversized images in the requested paths ──

paths=("$@")
if [ ${#paths[@]} -eq 0 ]; then
  paths=("$BLOG_DIR/assets/images/posts")
fi

files=()
for p in "${paths[@]}"; do
  if [ -d "$p" ]; then
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find "$p" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) \
               -not -name '*-thumb.*' -print0)
  elif [ -f "$p" ]; then
    files+=("$p")
  else
    echo "Skipping (not found): $p" >&2
  fi
done

before_total=0
after_total=0
changed=0

for f in "${files[@]}"; do
  before=$(size_of "$f")
  before_total=$((before_total + before))

  long_edge=$(long_edge_of "$f")
  if [ "${long_edge%.*}" -le "$MAX_EDGE" ] 2>/dev/null; then
    after_total=$((after_total + before))
    continue
  fi

  fmt="$(format_of "$f")"
  [ -n "$fmt" ] || { after_total=$((after_total + before)); continue; }

  out="$(mktemp).$fmt"
  if ! resize_and_recompress "$f" "$out" "$fmt" "$MAX_EDGE" 2>/dev/null; then
    rm -f "$out"
    echo "  skipped (decode failed): $f" >&2
    after_total=$((after_total + before))
    continue
  fi

  after=$(size_of "$out")
  if [ "$after" -lt "$before" ]; then
    mv "$out" "$f"
    printf '  %-52s %5d KB -> %5d KB (-%d KB)\n' \
      "${f#"$BLOG_DIR"/}" "$((before / 1024))" "$((after / 1024))" "$(((before - after) / 1024))"
    after_total=$((after_total + after))
    changed=$((changed + 1))
  else
    rm -f "$out"
    after_total=$((after_total + before))
  fi
done

echo
echo "$changed of ${#files[@]} image(s) resized."
echo "Total: $((before_total / 1024 / 1024)) MB -> $((after_total / 1024 / 1024)) MB"

# ── Generate listing thumbnails for post covers + site logo ──

covers() {
  {
    grep -h '^image:' "$BLOG_DIR"/_posts/*.md 2>/dev/null | sed 's/^image:[[:space:]]*//'
    sed -n 's/^logo:[[:space:]]*//p' "$BLOG_DIR/_config.yml" 2>/dev/null
  } | tr -d '"' | sed 's/[[:space:]]*$//' | grep '^/' | sort -u
}

echo
echo "Thumbnails (${THUMB_EDGE}px):"
thumb_count=0

while IFS= read -r ref; do
  src="$BLOG_DIR$ref"
  [ -f "$src" ] || { echo "  missing: $ref" >&2; continue; }

  fmt="$(format_of "$src")"
  [ -n "$fmt" ] || continue

  dir="$(dirname "$src")"
  stem="$(basename "${src%.*}")"
  thumb="$dir/${stem}-thumb.${fmt}"

  out="$(mktemp).$fmt"
  if ! resize_and_recompress "$src" "$out" "$fmt" "$THUMB_EDGE" 2>/dev/null; then
    rm -f "$out"
    echo "  skipped (decode failed): $ref" >&2
    continue
  fi

  if [ -f "$thumb" ] && [ "$(size_of "$out")" -ge "$(size_of "$thumb")" ]; then
    rm -f "$out"
    continue
  fi

  mv "$out" "$thumb"
  printf '  %-52s %5d KB\n' "${thumb#"$BLOG_DIR"/}" "$(($(size_of "$thumb") / 1024))"
  thumb_count=$((thumb_count + 1))
done < <(covers)

echo "$thumb_count thumbnail(s) written."
