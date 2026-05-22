#!/bin/sh

# Xcode Cloud post-clone script for Flutter
# Based on working examples from Flutter community
# Location: ios/ci_scripts/ci_post_clone.sh (required for Xcode Cloud)

set -e

echo "🔧 Running Xcode Cloud post-clone script..."
echo "==========================================="
echo "CI_WORKSPACE: ${CI_WORKSPACE:-not set}"
echo "PWD: $(pwd)"

# Determine repository root
if [ -n "$CI_WORKSPACE" ]; then
    REPO_ROOT="$CI_WORKSPACE"
else
    # Script runs from ios/ directory in Xcode Cloud
    REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
fi

cd "$REPO_ROOT"
echo "Working directory: $(pwd)"
echo "Repository root: $REPO_ROOT"

# Install Flutter if not available
FLUTTER_PATH=""
if command -v flutter &> /dev/null; then
    FLUTTER_PATH=$(which flutter)
    echo "✅ Flutter found in PATH: $FLUTTER_PATH"
else
    echo "📦 Installing Flutter..."
    
    # Try Homebrew first
    if command -v brew &> /dev/null; then
        echo "Installing Flutter via Homebrew..."
        brew install --cask flutter || {
            echo "Homebrew installation failed, trying git clone..."
            if [ ! -d "$HOME/flutter" ]; then
                git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter" --depth 1
            fi
            export PATH="$HOME/flutter/bin:$PATH"
            FLUTTER_PATH="$HOME/flutter/bin/flutter"
        }
    else
        # Clone Flutter directly
        echo "Installing Flutter via git clone..."
        if [ ! -d "$HOME/flutter" ]; then
            git clone https://github.com/flutter/flutter.git -b stable "$HOME/flutter" --depth 1
        fi
        export PATH="$HOME/flutter/bin:$PATH"
        FLUTTER_PATH="$HOME/flutter/bin/flutter"
    fi
    
    # Verify Flutter installation
    if [ ! -f "$FLUTTER_PATH" ]; then
        echo "❌ ERROR: Flutter installation failed"
        echo "Please configure Flutter in Xcode Cloud workflow settings"
        exit 1
    fi
fi

# Verify Flutter is accessible
if ! command -v flutter &> /dev/null; then
    echo "❌ ERROR: Flutter command not found after installation"
    exit 1
fi

FLUTTER_PATH=$(which flutter)
echo "✅ Flutter found: $FLUTTER_PATH"
flutter --version | head -1

# Precache iOS artifacts
echo ""
echo "📦 Precaching Flutter iOS artifacts..."
flutter precache --ios || {
    echo "⚠️  Warning: flutter precache failed, continuing..."
}

# Install CocoaPods if not available
if ! command -v pod &> /dev/null; then
    echo ""
    echo "📦 Installing CocoaPods..."
    if command -v brew &> /dev/null; then
        brew install cocoapods || {
            echo "Trying gem install..."
            sudo gem install cocoapods
        }
    else
        sudo gem install cocoapods
    fi
fi

# Verify CocoaPods
if ! command -v pod &> /dev/null; then
    echo "❌ ERROR: CocoaPods installation failed"
    exit 1
fi
echo "✅ CocoaPods found: $(which pod)"

# Get Flutter dependencies (generates Generated.xcconfig)
echo ""
echo "📦 Step 1: Getting Flutter dependencies..."
cd "$REPO_ROOT"
flutter pub get

IOS_FLUTTER_DIR="$REPO_ROOT/ios/Flutter"
if [ ! -f "$IOS_FLUTTER_DIR/Generated.xcconfig" ]; then
    echo "❌ ERROR: Generated.xcconfig was not created!"
    echo "Checking Flutter configuration..."
    flutter doctor -v
    exit 1
fi
echo "✅ Generated.xcconfig created successfully at: $IOS_FLUTTER_DIR/Generated.xcconfig"

# Regenerate SwiftPM Package.swift with the app's iOS 15 deployment target.
# Without this, FlutterGeneratedPluginSwiftPackage stays at iOS 13.0 and Firebase SPM fails.
echo ""
echo "📦 Regenerating iOS Swift Package config (deployment target 15.0)..."
cd "$REPO_ROOT"
flutter build ios --config-only
SPM_PACKAGE="$IOS_FLUTTER_DIR/ephemeral/Packages/FlutterGeneratedPluginSwiftPackage/Package.swift"
if [ ! -f "$SPM_PACKAGE" ]; then
    echo "❌ ERROR: FlutterGeneratedPluginSwiftPackage/Package.swift was not created!"
    exit 1
fi
if ! grep -q '.iOS("15.0")' "$SPM_PACKAGE"; then
    echo "❌ ERROR: Package.swift does not declare iOS 15.0 (Firebase requires 15.0+)"
    grep -A2 'platforms' "$SPM_PACKAGE" || true
    exit 1
fi
echo "✅ FlutterGeneratedPluginSwiftPackage targets iOS 15.0"

# Install CocoaPods dependencies
echo ""
echo "📦 Step 2: Installing CocoaPods dependencies..."
cd "$REPO_ROOT/ios"
pod install --repo-update

if [ ! -d "$REPO_ROOT/ios/Pods" ]; then
    echo "❌ ERROR: Pods directory was not created!"
    echo "Pod install output:"
    pod install --verbose || true
    exit 1
fi
echo "✅ CocoaPods dependencies installed successfully"

# Xcode Cloud requires Package.resolved under Runner.xcworkspace (not only xcodeproj).
echo ""
echo "📦 Syncing Swift Package Manager lockfile for Xcode Cloud..."
SPM_SRC="$REPO_ROOT/ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
SPM_DST_DIR="$REPO_ROOT/ios/Runner.xcworkspace/xcshareddata/swiftpm"
mkdir -p "$SPM_DST_DIR"
if [ -f "$SPM_SRC" ]; then
    cp "$SPM_SRC" "$SPM_DST_DIR/Package.resolved"
    echo "✅ Package.resolved synced to Runner.xcworkspace"
elif [ ! -f "$SPM_DST_DIR/Package.resolved" ]; then
    echo "❌ ERROR: Package.resolved missing for Xcode Cloud SPM resolution"
    exit 1
fi

# Verify critical files exist
echo ""
echo "📋 Verifying build requirements..."
if [ ! -f "$IOS_FLUTTER_DIR/Generated.xcconfig" ]; then
    echo "❌ ERROR: Generated.xcconfig missing!"
    exit 1
fi

if [ ! -d "$REPO_ROOT/ios/Pods/Target Support Files/Pods-Runner" ]; then
    echo "❌ ERROR: Pods-Runner target support files missing!"
    exit 1
fi

echo "✅ All build requirements verified"
echo ""
echo "✅ Post-clone script completed successfully!"
echo "Ready to proceed with build..."
