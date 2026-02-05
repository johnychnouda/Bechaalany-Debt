#!/bin/bash

# Xcode Cloud post-clone script for Flutter
# This script runs after the repository is cloned
# Location: ios/ci_scripts/ci_post_clone.sh (required for Xcode Cloud)

set -e

echo "🔧 Running Xcode Cloud post-clone script..."
echo "==========================================="

# Navigate to project root (script runs from ios/ directory)
cd "$(dirname "$0")/../.."
pwd

# Install Flutter if not available
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter..."
    brew install --cask flutter || {
        echo "⚠️  Flutter installation via Homebrew failed, trying alternative..."
        # Alternative: download Flutter
        if [ ! -d "$HOME/flutter" ]; then
            git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter"
        fi
        export PATH="$HOME/flutter/bin:$PATH"
    }
fi

# Verify Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter is not available"
    exit 1
fi

echo "✅ Flutter found: $(which flutter)"
flutter --version | head -1

# Install CocoaPods if not available
if ! command -v pod &> /dev/null; then
    echo "📦 Installing CocoaPods..."
    brew install cocoapods || {
        echo "⚠️  CocoaPods installation via Homebrew failed, trying gem..."
        sudo gem install cocoapods
    }
fi

# Get Flutter dependencies (generates Generated.xcconfig)
echo ""
echo "📦 Step 1: Getting Flutter dependencies..."
flutter pub get

if [ ! -f "ios/Flutter/Generated.xcconfig" ]; then
    echo "❌ ERROR: Generated.xcconfig was not created!"
    flutter doctor -v
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
