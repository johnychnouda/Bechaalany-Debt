#!/bin/bash

# Pre-build script for CI/CD platforms
# This script ensures all required dependencies are installed before building
# Use this script in your CI/CD platform's pre-build step

set -e

echo "🔧 CI/CD Pre-Build Script"
echo "========================"
echo ""

# Get Flutter dependencies (generates Generated.xcconfig)
echo "📦 Step 1: Getting Flutter dependencies..."
flutter pub get

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "❌ ERROR: Generated.xcconfig was not created!"
    exit 1
fi
echo "✅ Generated.xcconfig created successfully"

# Install CocoaPods dependencies
echo ""
echo "📦 Step 2: Installing CocoaPods dependencies..."
cd ios
pod install
cd ..

if [ ! -d "ios/Pods" ]; then
    echo "❌ ERROR: Pods directory was not created!"
    exit 1
fi
echo "✅ CocoaPods dependencies installed successfully"

echo ""
echo "✅ Pre-build steps completed successfully!"
echo "Ready to proceed with xcodebuild archive..."
