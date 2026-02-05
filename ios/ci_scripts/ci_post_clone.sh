#!/bin/sh

# Xcode Cloud post-clone script for Flutter
# This script runs after the repository is cloned
# Location: ios/ci_scripts/ci_post_clone.sh (required for Xcode Cloud)

set -e

echo "🔧 Running Xcode Cloud post-clone script..."
echo "==========================================="
echo "CI_WORKSPACE: ${CI_WORKSPACE:-not set}"
echo "PWD: $(pwd)"

# Use CI_WORKSPACE if available, otherwise navigate from script location
if [ -n "$CI_WORKSPACE" ]; then
    REPO_ROOT="$CI_WORKSPACE"
else
    # Script runs from ios/ directory, go up to project root
    REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fi

cd "$REPO_ROOT"
echo "Working directory: $(pwd)"

# Find Flutter - check common locations
FLUTTER_PATH=""
if command -v flutter &> /dev/null; then
    FLUTTER_PATH=$(which flutter)
elif [ -d "$HOME/flutter/bin" ]; then
    FLUTTER_PATH="$HOME/flutter/bin/flutter"
    export PATH="$HOME/flutter/bin:$PATH"
elif [ -d "/usr/local/flutter/bin" ]; then
    FLUTTER_PATH="/usr/local/flutter/bin/flutter"
    export PATH="/usr/local/flutter/bin:$PATH"
fi

if [ -z "$FLUTTER_PATH" ] || [ ! -f "$FLUTTER_PATH" ]; then
    echo "⚠️  WARNING: Flutter not found in standard locations"
    echo "Xcode Cloud may need Flutter configured in workflow settings"
    echo "Attempting to continue - Flutter dependencies will be handled in pre-xcodebuild script"
    exit 0
fi

echo "✅ Flutter found: $FLUTTER_PATH"
"$FLUTTER_PATH" --version | head -1

# Install CocoaPods if not available
if ! command -v pod &> /dev/null; then
    echo "📦 Installing CocoaPods..."
    if command -v brew &> /dev/null; then
        brew install cocoapods || gem install cocoapods
    else
        gem install cocoapods
    fi
fi

# Get Flutter dependencies (generates Generated.xcconfig)
echo ""
echo "📦 Step 1: Getting Flutter dependencies..."
"$FLUTTER_PATH" pub get

IOS_FLUTTER_DIR="$REPO_ROOT/ios/Flutter"
if [ ! -f "$IOS_FLUTTER_DIR/Generated.xcconfig" ]; then
    echo "❌ ERROR: Generated.xcconfig was not created!"
    echo "Flutter pub get output:"
    "$FLUTTER_PATH" pub get --verbose || true
    exit 1
fi
echo "✅ Generated.xcconfig created successfully at: $IOS_FLUTTER_DIR/Generated.xcconfig"

# Install CocoaPods dependencies
echo ""
echo "📦 Step 2: Installing CocoaPods dependencies..."
cd "$REPO_ROOT/ios"
pod install
cd "$REPO_ROOT"

if [ ! -d "$REPO_ROOT/ios/Pods" ]; then
    echo "❌ ERROR: Pods directory was not created!"
    exit 1
fi
echo "✅ CocoaPods dependencies installed successfully"

echo ""
echo "✅ Post-clone script completed successfully!"
echo "Ready to proceed with build..."
