#!/bin/bash

# Create Wireless IPA Script
# Run this after updating the provisioning profile with device UDIDs

echo "🚀 Creating Wireless IPA for Bechaalany Debt App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

print_status "Step 1: Building iOS app..."
flutter build ios --release

if [ $? -eq 0 ]; then
    print_success "iOS build completed successfully!"
else
    print_error "iOS build failed! Check your provisioning profile."
    exit 1
fi

print_status "Step 2: Creating archive..."
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive

if [ $? -eq 0 ]; then
    print_success "Archive created successfully!"
else
    print_error "Archive creation failed! Check your provisioning profile."
    exit 1
fi

print_status "Step 3: Creating IPA file..."
mkdir -p ../wireless_distribution
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath ../wireless_distribution -exportOptionsPlist ExportOptions.plist

if [ $? -eq 0 ]; then
    print_success "IPA created successfully!"
    cd ..
    
    print_status "Step 4: Preparing wireless distribution..."
    echo ""
    print_success "🎉 Wireless IPA created successfully!"
    echo ""
    print_status "Files created in wireless_distribution/:"
    ls -la wireless_distribution/
    echo ""
    print_status "Next steps for wireless distribution:"
    echo "1. Upload IPA to TestFlight (recommended)"
    echo "2. Upload to Diawi.com for web distribution"
    echo "3. Host on your own HTTPS server"
    echo "4. Use Firebase App Distribution"
    echo ""
    print_warning "Remember to add device UDIDs to your provisioning profile!"
    
else
    print_error "IPA creation failed! Check your ExportOptions.plist and provisioning profile."
    exit 1
fi 