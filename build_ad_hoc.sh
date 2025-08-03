#!/bin/bash

# Bechaalany Debt App - Ad Hoc Build Script
# This script builds and prepares your app for Ad Hoc distribution

echo "🚀 Starting Ad Hoc build for Bechaalany Debt App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    print_error "Please run this script from the root of your Flutter project"
    exit 1
fi

# Clean previous builds
print_status "Cleaning previous builds..."
flutter clean

# Get dependencies
print_status "Getting Flutter dependencies..."
flutter pub get

# Build for iOS Ad Hoc
print_status "Building iOS Ad Hoc version..."
flutter build ios --release --flavor AdHoc

if [ $? -eq 0 ]; then
    print_success "iOS build completed successfully!"
else
    print_error "iOS build failed!"
    exit 1
fi

# Create distribution directory
DIST_DIR="ad_hoc_distribution"
mkdir -p "$DIST_DIR"

# Copy the built app
print_status "Preparing distribution files..."
cp -r "build/ios/iphoneos/Runner.app" "$DIST_DIR/"

# Create a simple installation guide
cat > "$DIST_DIR/INSTALLATION_GUIDE.txt" << EOF
Bechaalany Debt App - Ad Hoc Installation Guide

📱 Installation Instructions:

1. Transfer this folder to the target device
2. Install the app using one of these methods:

Method 1 - Using Xcode:
- Open Xcode
- Window → Devices and Simulators
- Select your device
- Drag Runner.app to the Applications section

Method 2 - Using Apple Configurator 2:
- Download Apple Configurator 2 from Mac App Store
- Connect device via USB
- Drag Runner.app to the device

Method 3 - Using iTunes (if available):
- Connect device via USB
- Open iTunes
- Go to Apps section
- Drag Runner.app to install

⚠️ Important Notes:
- Device must be registered in your Apple Developer account
- Device must trust your developer certificate
- Go to Settings → General → VPN & Device Management
- Trust your developer certificate

🔧 Troubleshooting:
- If app doesn't install, check device registration
- If app crashes, check certificate trust settings
- Make sure device is running iOS 18.0 or later

📞 Support:
For issues, contact your app administrator.

Built on: $(date)
Version: $(grep 'version:' pubspec.yaml | cut -d' ' -f2)
EOF

print_success "Ad Hoc distribution prepared in: $DIST_DIR"
print_status "Files created:"
ls -la "$DIST_DIR"

echo ""
print_success "🎉 Ad Hoc build completed successfully!"
echo ""
print_status "Next steps:"
echo "1. Transfer the '$DIST_DIR' folder to your test devices"
echo "2. Install the app using the methods described in INSTALLATION_GUIDE.txt"
echo "3. Make sure devices trust your developer certificate"
echo ""
print_warning "Remember: Each device must be registered in your Apple Developer account!" 