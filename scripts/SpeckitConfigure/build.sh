#!/usr/bin/env bash
#
# Build script for SpeckitConfigure
# Creates the lib/ directory and compiles bash scripts
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$SCRIPT_DIR/src"
BUILD_DIR="$SCRIPT_DIR/../lib/SpeckitConfigure"

echo "Building SpeckitConfigure..."

# Create build directory
mkdir -p "$BUILD_DIR"

# Copy all source files
cp "$SRC_DIR"/*.sh "$BUILD_DIR/"

echo "Build complete: $BUILD_DIR"