#!/bin/bash

# Export DefaultCurrentExpansion addon as a distributable zip file
# Usage: ./export.sh [destination]
# Example: ./export.sh ~/Desktop

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDON_NAME="DefaultCurrentExpansion"

# Get destination from argument or use current directory
DEST="${1:-.}"
DEST="$(cd "$DEST" 2>/dev/null && pwd)" || { echo "Error: Invalid destination '$1'"; exit 1; }

# Extract version from TOC file
VERSION=$(grep -E "^## Version:" "$SCRIPT_DIR/$ADDON_NAME.toc" | sed 's/## Version: //')
if [ -z "$VERSION" ]; then
    echo "Error: Could not extract version from TOC file"
    exit 1
fi

ZIP_NAME="$ADDON_NAME.$VERSION.zip"
TEMP_DIR=$(mktemp -d)

# Create addon directory structure
mkdir -p "$TEMP_DIR/$ADDON_NAME"
cp "$SCRIPT_DIR/$ADDON_NAME.lua" "$TEMP_DIR/$ADDON_NAME/"
cp "$SCRIPT_DIR/$ADDON_NAME.toc" "$TEMP_DIR/$ADDON_NAME/"

# Create zip file
cd "$TEMP_DIR"
zip -r "$DEST/$ZIP_NAME" "$ADDON_NAME"

# Cleanup
rm -rf "$TEMP_DIR"

echo "Created: $DEST/$ZIP_NAME"
