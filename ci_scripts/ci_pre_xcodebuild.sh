#!/bin/bash

# Xcode Cloud pre-xcodebuild script
# This script runs before xcodebuild archive
# It ensures Flutter dependencies and CocoaPods are installed

set -e

echo "🔧 Running pre-xcodebuild script..."
echo "===================================="

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter is not available in PATH"
    echo "Attempting to find Flutter..."
    
    # Try common Flutter locations
    if [ -d "$HOME/flutter" ]; then
        export PATH="$HOME/flutter/bin:$PATH"
    elif [ -d "/usr/local/flutter" ]; then
        export PATH="/usr/local/flutter/bin:$PATH"
    else
        echo "❌ ERROR: Flutter not found. Xcode Cloud may need Flutter installed."
        exit 1
    fi
fi

# Verify Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter command still not available"
    exit 1
fi

echo "✅ Flutter found: $(which flutter)"
echo "   Version: $(flutter --version | head -1)"

# Get Flutter dependencies (generates Generated.xcconfig)
echo ""
echo "📦 Step 1: Getting Flutter dependencies..."
flutter pub get

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "❌ ERROR: Generated.xcconfig was not created!"
    echo "Checking Flutter configuration..."
    flutter doctor -v
    exit 1
fi
echo "✅ Generated.xcconfig created successfully"

# Install CocoaPods dependencies
echo ""
echo "📦 Step 2: Installing CocoaPods dependencies..."

# Check if CocoaPods is available
if ! command -v pod &> /dev/null; then
    echo "⚠️  WARNING: CocoaPods not found, attempting to install..."
    sudo gem install cocoapods || {
        echo "❌ ERROR: Failed to install CocoaPods"
        exit 1
    }
fi

cd ios
pod install
cd ..

if [ ! -d "ios/Pods" ]; then
    echo "❌ ERROR: Pods directory was not created!"
    exit 1
fi
echo "✅ CocoaPods dependencies installed successfully"

echo ""
echo "✅ Pre-xcodebuild script completed successfully!"
echo "Ready to proceed with xcodebuild archive..."
