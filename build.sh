#!/bin/bash

# Build and Install Script for PhotoScreensaver
# This script builds the screensaver and installs it to ~/Library/Screen Savers/
#
# Usage:
#   ./build.sh                  # Build and install (Release)
#   ./build.sh --debug          # Build and install (Debug)
#   ./build.sh --build-only     # Build only, don't install
#   ./build.sh --ci             # CI mode (non-interactive)

set -e  # Exit on error

# Default settings
CONFIGURATION="Release"
BUILD_ONLY=false
CI_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --debug)
            CONFIGURATION="Debug"
            shift
            ;;
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --ci)
            CI_MODE=true
            BUILD_ONLY=true
            shift
            ;;
        --help)
            echo "PhotoScreensaver Build Script"
            echo ""
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --debug       Build Debug configuration (default: Release)"
            echo "  --build-only  Build only, don't install"
            echo "  --ci          CI mode (build only, non-interactive)"
            echo "  --help        Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

echo "🖼️  PhotoScreensaver Build Script"
echo "=================================="
echo ""

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ Error: This script must be run on macOS"
    exit 1
fi

# Check if Xcode command line tools are installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode command line tools not found"
    echo "Please install Xcode and run: xcode-select --install"
    exit 1
fi

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="$PROJECT_DIR/PhotoScreensaver.xcodeproj"
SCHEME="PhotoScreensaver"
INSTALL_DIR="$HOME/Library/Screen Savers"
PRODUCT_NAME="PhotoScreensaver.saver"

echo "📂 Project: $PROJECT_FILE"
echo "🎯 Scheme: $SCHEME"
echo "⚙️  Configuration: $CONFIGURATION"
if [ "$BUILD_ONLY" = true ]; then
    echo "📌 Mode: Build only"
fi
echo ""

# Build the project
echo "🔨 Building PhotoScreensaver..."
echo ""

xcodebuild \
    -project "$PROJECT_FILE" \
    -scheme "$SCHEME" \
    -configuration "$CONFIGURATION" \
    clean build \
    CONFIGURATION_BUILD_DIR="$PROJECT_DIR/build"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Build failed!"
    exit 1
fi

echo ""
echo "✅ Build successful!"
echo ""

# Verify build artifacts
if [ ! -f "$PROJECT_DIR/build/$PRODUCT_NAME/Contents/MacOS/PhotoScreensaver" ]; then
    echo "❌ Build artifact not found at expected location!"
    echo "Expected: $PROJECT_DIR/build/$PRODUCT_NAME/Contents/MacOS/PhotoScreensaver"
    exit 1
fi

echo "📦 Build artifact: $PROJECT_DIR/build/$PRODUCT_NAME"
echo ""

# Exit if build-only mode
if [ "$BUILD_ONLY" = true ]; then
    echo "🏁 Build complete (build-only mode)"
    exit 0
fi

# Installation steps
echo "📥 Installing screensaver..."
echo ""

# Create install directory if it doesn't exist
mkdir -p "$INSTALL_DIR"

# Remove old version if it exists
if [ -d "$INSTALL_DIR/$PRODUCT_NAME" ]; then
    echo "🗑️  Removing old version..."
    rm -rf "$INSTALL_DIR/$PRODUCT_NAME"
fi

# Install the screensaver
echo "📦 Installing to $INSTALL_DIR/$PRODUCT_NAME..."
cp -R "$PROJECT_DIR/build/$PRODUCT_NAME" "$INSTALL_DIR/"

if [ $? -ne 0 ]; then
    echo ""
    echo "❌ Installation failed!"
    exit 1
fi

echo ""
echo "✅ Installation successful!"
echo ""
echo "🎉 PhotoScreensaver has been installed!"
echo ""
echo "Next steps:"
echo "1. Open System Settings (or System Preferences)"
echo "2. Go to Screen Saver"
echo "3. Select 'PhotoScreensaver' from the list"
echo "4. Grant Photos access when prompted"
echo ""
echo "💡 Tip: Click 'Preview' to test the screensaver immediately"
echo ""

# Ask if user wants to open System Settings (skip in CI mode)
if [ "$CI_MODE" = false ]; then
    read -p "Would you like to open System Settings now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        open "x-apple.systempreferences:com.apple.preference.screensaver"
    fi
fi
