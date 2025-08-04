#!/bin/bash

# Multiple Device Management Script for Bechaalany Debt App
# This script helps you install the app on multiple devices

echo "📱 Managing Multiple Devices for Bechaalany Debt App..."

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

# Device UDIDs
DEVICE1_UDID="00008120-001919823650A01E"
DEVICE2_UDID="00008110-000064E13663801E"

echo ""
print_status "Registered Device UDIDs:"
echo "Device 1: $DEVICE1_UDID (iPhone 15)"
echo "Device 2: $DEVICE2_UDID (New device)"
echo ""

print_status "Step 1: Check current device connections..."
flutter devices

echo ""
print_status "Step 2: Build app for release..."
flutter build ios --release

if [ $? -eq 0 ]; then
    print_success "App built successfully!"
else
    print_error "Build failed!"
    exit 1
fi

echo ""
print_status "Step 3: Install on connected devices..."

# Check if devices are connected and install
if xcrun devicectl list devices | grep -q "$DEVICE1_UDID"; then
    print_status "Installing on Device 1 ($DEVICE1_UDID)..."
    xcrun devicectl device install app --device AF26F089-E506-52BA-909E-91485656F99E build/ios/iphoneos/Runner.app
    if [ $? -eq 0 ]; then
        print_success "Successfully installed on Device 1!"
    else
        print_error "Failed to install on Device 1"
    fi
else
    print_warning "Device 1 not currently connected"
fi

# For Device 2, we'll need to wait for it to connect
print_warning "Device 2 ($DEVICE2_UDID) needs to be connected first"
print_status "To connect Device 2:"
echo "1. Make sure Device 2 is on the same WiFi network"
echo "2. Go to Settings → Developer → Local Network on Device 2"
echo "3. Enable 'Local Network' for your Mac"
echo "4. Run this script again once connected"

echo ""
print_status "Step 4: Create distribution package for manual installation..."
mkdir -p multi_device_distribution
cp -r build/ios/iphoneos/Runner.app multi_device_distribution/

# Create installation guide for multiple devices
cat > multi_device_distribution/INSTALLATION_GUIDE.md << 'EOF'
# 📱 Multi-Device Installation Guide

## Registered Devices:
- Device 1: 00008120-001919823650A01E (iPhone 15)
- Device 2: 00008110-000064E13663801E (New device)

## Installation Methods:

### Method 1: Wireless Installation (Recommended)
```bash
# For Device 1 (if connected)
flutter run --release --device-id 00008120-001919823650A01E

# For Device 2 (once connected)
flutter run --release --device-id 00008110-000064E13663801E
```

### Method 2: Manual Installation
1. Connect device via USB
2. Use Xcode → Window → Devices and Simulators
3. Drag Runner.app to Applications section

### Method 3: Ad-hoc Distribution
1. Create ad-hoc provisioning profile with both UDIDs
2. Build IPA file
3. Distribute via TestFlight or web services

## Device Connection Status:
- Device 1: ✅ Connected wirelessly
- Device 2: ⏳ Waiting for connection

## Troubleshooting:
- Ensure both devices are on same WiFi network
- Enable Local Network in Developer settings
- Trust developer certificate on each device
EOF

print_success "Multi-device distribution package created!"
echo ""
print_status "Files created in multi_device_distribution/:"
ls -la multi_device_distribution/

echo ""
print_success "🎉 Multi-device setup completed!"
echo ""
print_status "Next steps:"
echo "1. Connect Device 2 to the same WiFi network"
echo "2. Enable Local Network in Developer settings on Device 2"
echo "3. Run this script again to install on Device 2"
echo "4. Or use the manual installation methods in the guide" 