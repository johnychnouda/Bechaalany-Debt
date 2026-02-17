#!/bin/bash

# Xcode Cloud post-clone script
# This script runs after the repository is cloned
# It ensures Flutter dependencies and CocoaPods are installed

set -e

echo "🔧 Running post-clone script..."
echo "================================"

# Check if Flutter is available
if ! command -v flutter &> /dev/null; then
    echo "⚠️  WARNING: Flutter is not available in PATH"
    echo "This is normal for Xcode Cloud - Flutter will be handled in pre-xcodebuild script"
    echo "Skipping Flutter pub get in post-clone..."
    exit 0
fi

echo "✅ Flutter found: $(which flutter)"

# Get Flutter dependencies (generates Generated.xcconfig)
echo ""
echo "📦 Step 1: Getting Flutter dependencies..."
flutter pub get

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "⚠️  WARNING: Generated.xcconfig was not created in post-clone"
    echo "This will be handled in pre-xcodebuild script"
    exit 0
fi
echo "✅ Generated.xcconfig created successfully"

# Install CocoaPods dependencies
echo ""
echo "📦 Step 2: Installing CocoaPods dependencies..."

# Check if CocoaPods is available
if ! command -v pod &> /dev/null; then
    echo "⚠️  WARNING: CocoaPods not found"
    echo "This will be handled in pre-xcodebuild script"
    exit 0
fi

cd ios
pod install
cd ..

if [ ! -d "ios/Pods" ]; then
    echo "⚠️  WARNING: Pods directory was not created in post-clone"
    echo "This will be handled in pre-xcodebuild script"
    exit 0
fi
echo "✅ CocoaPods dependencies installed successfully"

echo ""
echo "✅ Post-clone script completed successfully!"
