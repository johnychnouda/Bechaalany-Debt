#!/bin/sh

# Xcode Cloud pre-xcodebuild script for Flutter
# This script runs before xcodebuild archive
# Location: ios/ci_scripts/ci_pre_xcodebuild.sh

set -e

echo "🔧 Running Xcode Cloud pre-xcodebuild script..."
echo "=============================================="
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

# Find Flutter
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

IOS_FLUTTER_DIR="$REPO_ROOT/ios/Flutter"
IOS_PODS_DIR="$REPO_ROOT/ios/Pods"

# Ensure Flutter dependencies are installed
if [ ! -f "$IOS_FLUTTER_DIR/Generated.xcconfig" ]; then
    echo "⚠️  Generated.xcconfig missing, running flutter pub get..."
    if [ -n "$FLUTTER_PATH" ] && [ -f "$FLUTTER_PATH" ]; then
        "$FLUTTER_PATH" pub get
        if [ ! -f "$IOS_FLUTTER_DIR/Generated.xcconfig" ]; then
            echo "❌ ERROR: Generated.xcconfig still not created after flutter pub get!"
            exit 1
        fi
        echo "✅ Generated.xcconfig created"
    else
        echo "❌ ERROR: Flutter not available and Generated.xcconfig missing!"
        echo "Please configure Flutter in Xcode Cloud workflow settings"
        exit 1
    fi
else
    echo "✅ Generated.xcconfig exists"
fi

# Ensure SwiftPM plugin package matches iOS 15 deployment target (Firebase auth/functions).
SPM_PACKAGE="$IOS_FLUTTER_DIR/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"
if [ ! -f "$SPM_PACKAGE" ] || ! grep -q '.iOS("15.0")' "$SPM_PACKAGE"; then
    echo "⚠️  Regenerating iOS Swift Package config..."
    if [ -n "$FLUTTER_PATH" ] && [ -f "$FLUTTER_PATH" ]; then
        "$FLUTTER_PATH" build ios --config-only
    elif command -v flutter &> /dev/null; then
        flutter build ios --config-only
    else
        echo "❌ ERROR: Flutter not available to regenerate Package.swift"
        exit 1
    fi
fi
if [ -f "$SPM_PACKAGE" ] && grep -q '.iOS("15.0")' "$SPM_PACKAGE"; then
    echo "✅ FlutterGeneratedPluginSwiftPackage targets iOS 15.0"
else
    echo "❌ ERROR: Package.swift missing or still below iOS 15.0"
    exit 1
fi

# Ensure CocoaPods dependencies are installed
if [ ! -d "$IOS_PODS_DIR" ]; then
    echo "⚠️  Pods directory missing, running pod install..."
    cd "$REPO_ROOT/ios"
    if command -v pod &> /dev/null; then
        pod install
        if [ ! -d "$IOS_PODS_DIR" ]; then
            echo "❌ ERROR: Pods directory still not created after pod install!"
            exit 1
        fi
        echo "✅ Pods directory created"
    else
        echo "❌ ERROR: CocoaPods not available and Pods directory missing!"
        exit 1
    fi
    cd "$REPO_ROOT"
else
    echo "✅ Pods directory exists"
fi

echo ""
echo "✅ Pre-xcodebuild script completed successfully!"
echo "Ready to proceed with xcodebuild archive..."
