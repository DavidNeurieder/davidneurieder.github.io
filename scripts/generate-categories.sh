#!/bin/bash
# Generate category pages for any categories used in posts
# that don't already have a category page.

BLOG_DIR="$(cd "$(dirname "$0")/.." && pwd)"
POSTS_DIR="$BLOG_DIR/_posts"
CATEGORIES_DIR="$BLOG_DIR/categories"

# Extract all unique categories from posts
# Handle both formats:
#   categories: android opensource privacy
#   categories: [android, opensource, offline currency converter]
tmpfile=$(mktemp)
for f in "$POSTS_DIR"/*.md; do
  line=$(grep '^categories:' "$f")
  value=$(echo "$line" | sed 's/^categories: *//')

  if echo "$value" | grep -q '^\['; then
    # Bracket format: strip brackets, split by comma
    echo "$value" | sed 's/\[//;s/\]//' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$'
  else
    # Space format: each word is a category
    echo "$value" | tr ' ' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$'
  fi
done | sort -u > "$tmpfile"

# Create category pages for missing ones
while IFS= read -r cat; do
  slug=$(echo "$cat" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
  file="$CATEGORIES_DIR/$slug.md"

  if [ ! -f "$file" ]; then
    cat > "$file" << EOF
---
layout: category
category: $cat
permalink: /categories/$slug/
---
EOF
    echo "Created: $slug.md"
  fi
done < "$tmpfile"

rm -f "$tmpfile"
echo "Done. All category pages exist."
