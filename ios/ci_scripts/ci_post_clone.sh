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
