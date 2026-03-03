#!/bin/bash
set -euo pipefail

# Upload an image to GitHub as a release asset and return a markdown image reference.
# Uses a dedicated "_pr-assets" release tag to store images.
#
# Usage: upload-screenshot.sh <image-path> [alt-text]
# Output: ![alt-text](https://github.com/owner/repo/releases/download/_pr-assets/unique-name.png)

FILE="${1:?Usage: upload-screenshot.sh <image-path> [alt-text]}"
ALT_TEXT="${2:-Screenshot}"
TAG="_pr-assets"

if [[ ! -f "$FILE" ]]; then
  echo "Error: File not found: $FILE" >&2
  exit 1
fi

MIME=$(file -b --mime-type "$FILE")
case "$MIME" in
  image/png|image/jpeg|image/gif|image/webp|image/svg+xml) ;;
  *)
    echo "Error: Unsupported file type: $MIME (expected an image)" >&2
    exit 1
    ;;
esac

REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner')

if ! gh release view "$TAG" &>/dev/null; then
  gh release create "$TAG" \
    --title "PR Assets" \
    --notes "Auto-uploaded images for pull requests. Old assets can be safely deleted." \
    --latest=false
fi

EXT="${FILE##*.}"
BASE=$(basename "$FILE" ".$EXT" | tr ' ' '-')
UNIQUE="${BASE}-$(date +%Y%m%d-%H%M%S)-$$.$EXT"

TMPDIR=$(mktemp -d)
TMPFILE="$TMPDIR/$UNIQUE"
cp "$FILE" "$TMPFILE"

gh release upload "$TAG" "$TMPFILE" --clobber >/dev/null 2>&1

rm -rf "$TMPDIR"

URL="https://github.com/${REPO}/releases/download/${TAG}/${UNIQUE}"
echo "![${ALT_TEXT}](${URL})"
