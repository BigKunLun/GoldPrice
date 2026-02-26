#!/bin/bash

# GoldPrice Build Script

set -e

APP_NAME="GoldPrice"

echo "🔨 Building $APP_NAME..."

# Create app bundle structure
mkdir -p $APP_NAME.app/Contents/MacOS
mkdir -p $APP_NAME.app/Contents/Resources

# Compile
swiftc -O \
    -o $APP_NAME.app/Contents/MacOS/$APP_NAME \
    $(find Sources -name "*.swift") \
    -framework Cocoa \
    2>&1

# Copy Info.plist
cp Info.plist $APP_NAME.app/Contents/Info.plist

# Copy icon
cp Resources/AppIcon.icns $APP_NAME.app/Contents/Resources/AppIcon.icns

# Create PkgInfo
echo -n "APPL????" > $APP_NAME.app/Contents/PkgInfo

echo "✅ Build complete: $APP_NAME.app"
echo ""
echo "To run:"
echo "  open $APP_NAME.app"
echo ""
echo "To install:"
echo "  cp -r $APP_NAME.app /Applications/"
