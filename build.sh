#!/bin/bash

# Build and Install Script for PhotoScreensaver
# This script builds the screensaver and installs it to ~/Library/Screen Savers/

set -e  # Exit on error

echo "🖼️  PhotoScreensaver Build and Install Script"
echo "=============================================="
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
CONFIGURATION="Release"
INSTALL_DIR="$HOME/Library/Screen Savers"
PRODUCT_NAME="PhotoScreensaver.saver"

echo "📂 Project: $PROJECT_FILE"
echo "🎯 Scheme: $SCHEME"
echo "⚙️  Configuration: $CONFIGURATION"
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

# Ask if user wants to open System Settings
read -p "Would you like to open System Settings now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    open "x-apple.systempreferences:com.apple.preference.screensaver"
fi
