#!/bin/bash
# Optimize blog images: resize to a maximum edge length and recompress.
# Images already within the size limit are left untouched, so re-running is a
# no-op (and avoids re-encoding/quality loss). A file is only overwritten when
# the optimized version is actually smaller.

set -euo pipefail

BLOG_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Longest allowed edge, in pixels, and encoder quality. Override via env:
#   MAX_EDGE=720 JPG_QUALITY=75 ./scripts/optimize-images.sh assets/images/posts/screens
MAX_EDGE="${MAX_EDGE:-1600}"
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

# Default to the post images directory when no paths are given.
paths=("$@")
if [ ${#paths[@]} -eq 0 ]; then
  paths=("$BLOG_DIR/assets/images/posts")
fi

# Expand directories to the image files they contain (recursively).
files=()
for p in "${paths[@]}"; do
  if [ -d "$p" ]; then
    while IFS= read -r -d '' f; do
      files+=("$f")
    done < <(find "$p" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \) -print0)
  elif [ -f "$p" ]; then
    files+=("$p")
  else
    echo "Skipping (not found): $p" >&2
  fi
done

if [ ${#files[@]} -eq 0 ]; then
  echo "No images found."
  exit 0
fi

size_of() {
  stat -c %s "$1" 2>/dev/null || stat -f %z "$1"
}

before_total=0
after_total=0
changed=0

for f in "${files[@]}"; do
  before=$(size_of "$f")
  before_total=$((before_total + before))

  # Longest edge of the image (0 if it can't be read).
  long_edge=$(identify -format '%[fx:max(w,h)]' "$f" 2>/dev/null \
    || magick identify -format '%[fx:max(w,h)]' "$f" 2>/dev/null \
    || echo 0)

  # Already within the limit -> nothing to do (keeps re-runs harmless).
  if [ "${long_edge%.*}" -le "$MAX_EDGE" ] 2>/dev/null; then
    after_total=$((after_total + before))
    continue
  fi

  ext="png"
  case "$(printf '%s' "$f" | tr '[:upper:]' '[:lower:]')" in
    *.jpg|*.jpeg) ext="jpg" ;;
  esac

  tmp="$(mktemp)"
  out="$tmp.$ext"

  if [ "$ext" = "jpg" ]; then
    if ! $IM "$f" -auto-orient -strip -sampling-factor 4:2:0 -interlace Plane \
        -resize "${MAX_EDGE}x${MAX_EDGE}>" -quality "$JPG_QUALITY" "$out" 2>/dev/null; then
      rm -f "$tmp" "$out"
      echo "  skipped (decode failed): $f" >&2
      after_total=$((after_total + before))
      continue
    fi
  else
    if ! $IM "$f" -auto-orient -strip \
        -resize "${MAX_EDGE}x${MAX_EDGE}>" -quality "$PNG_QUALITY" "$out" 2>/dev/null; then
      rm -f "$tmp" "$out"
      echo "  skipped (decode failed): $f" >&2
      after_total=$((after_total + before))
      continue
    fi
  fi

  after=$(size_of "$out")
  if [ "$after" -lt "$before" ]; then
    mv "$out" "$f"
    printf '  %-40s %5d KB -> %5d KB (-%d KB)\n' \
      "${f#"$BLOG_DIR"/}" "$((before / 1024))" "$((after / 1024))" "$(((before - after) / 1024))"
    after_total=$((after_total + after))
    changed=$((changed + 1))
  else
    after_total=$((after_total + before))
  fi
  rm -f "$tmp"
done

echo
echo "$changed of ${#files[@]} image(s) optimized."
echo "Total: $((before_total / 1024 / 1024)) MB -> $((after_total / 1024 / 1024)) MB"
