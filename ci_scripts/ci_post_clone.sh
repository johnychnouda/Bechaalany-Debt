#!/bin/bash

# Codemagic post-clone script
# This script runs after the repository is cloned
# It ensures Flutter dependencies and CocoaPods are installed

set -e

echo "🔧 Running post-clone script..."
echo "================================"

# Get Flutter dependencies (generates Generated.xcconfig)
echo ""
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
echo "✅ Post-clone script completed successfully!"
echo "Ready to proceed with build..."
