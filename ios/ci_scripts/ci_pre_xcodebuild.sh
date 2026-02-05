#!/bin/bash

# Xcode Cloud pre-xcodebuild script for Flutter
# This script runs before xcodebuild archive
# Location: ios/ci_scripts/ci_pre_xcodebuild.sh

set -e

echo "🔧 Running Xcode Cloud pre-xcodebuild script..."
echo "=============================================="

# Navigate to project root (script runs from ios/ directory)
cd "$(dirname "$0")/../.."
pwd

# Ensure Flutter dependencies are installed
if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "⚠️  Generated.xcconfig missing, running flutter pub get..."
    if command -v flutter &> /dev/null; then
        flutter pub get
    else
        echo "❌ ERROR: Flutter not available and Generated.xcconfig missing!"
        exit 1
    fi
fi

# Ensure CocoaPods dependencies are installed
if [ ! -d "ios/Pods" ]; then
    echo "⚠️  Pods directory missing, running pod install..."
    cd ios
    if command -v pod &> /dev/null; then
        pod install
    else
        echo "❌ ERROR: CocoaPods not available and Pods directory missing!"
        exit 1
    fi
    cd ..
fi

echo "✅ Pre-xcodebuild script completed successfully!"
echo "Ready to proceed with xcodebuild archive..."
