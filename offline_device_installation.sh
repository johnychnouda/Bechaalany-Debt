#!/bin/bash

# Offline Device Installation Script
# For Device 2 when not on the same WiFi network

echo "📱 Setting up Offline Installation for Device 2..."

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
print_status "Device Status:"
echo "Device 1: $DEVICE1_UDID (iPhone 15) - ✅ Connected wirelessly"
echo "Device 2: $DEVICE2_UDID (New device) - ❌ Not on same WiFi"
echo ""

print_status "Step 1: Building app for offline distribution..."
flutter build ios --release

if [ $? -eq 0 ]; then
    print_success "App built successfully!"
else
    print_error "Build failed!"
    exit 1
fi

echo ""
print_status "Step 2: Creating offline distribution package..."

# Create offline distribution directory
mkdir -p offline_distribution
cp -r build/ios/iphoneos/Runner.app offline_distribution/

# Create comprehensive installation guide
cat > offline_distribution/INSTALLATION_GUIDE.md << 'EOF'
# 📱 Offline Installation Guide for Device 2

## Device Information:
- **Device 2 UDID:** 00008110-000064E13663801E
- **Status:** Not on same WiFi network
- **Installation Method:** Manual/Offline

## Installation Methods:

### Method 1: USB Connection (Recommended)
1. **Connect Device 2 to Mac via USB cable**
2. **Open Xcode**
3. **Go to Window → Devices and Simulators**
4. **Select Device 2 from the list**
5. **Drag Runner.app to the Applications section**
6. **Trust developer certificate on Device 2**

### Method 2: Apple Configurator 2
1. **Download Apple Configurator 2 from Mac App Store**
2. **Connect Device 2 via USB**
3. **Open Apple Configurator 2**
4. **Drag Runner.app to Device 2**

### Method 3: TestFlight (Best for Multiple Devices)
1. **Upload app to App Store Connect**
2. **Add Device 2 UDID to your Apple Developer account**
3. **Create ad-hoc provisioning profile with both UDIDs**
4. **Build IPA file**
5. **Upload to TestFlight**
6. **Invite Device 2 user via email**

### Method 4: Ad-hoc IPA Distribution
1. **Add Device 2 UDID to Apple Developer account**
2. **Create ad-hoc provisioning profile with both UDIDs**
3. **Update Xcode project with new profile**
4. **Build IPA file**
5. **Distribute via web services (Diawi, Firebase, etc.)**

## Troubleshooting:

### If Device 2 doesn't appear in Xcode:
- **Check USB cable connection**
- **Trust this computer on Device 2**
- **Unlock Device 2 screen**
- **Check if Device 2 is in recovery mode**

### If app doesn't install:
- **Check device registration in Apple Developer account**
- **Verify provisioning profile includes Device 2 UDID**
- **Trust developer certificate on Device 2**

### If app crashes:
- **Go to Settings → General → VPN & Device Management**
- **Trust your developer certificate**
- **Restart Device 2**

## Next Steps:
1. **Connect Device 2 via USB**
2. **Use Method 1 (USB Connection) for immediate installation**
3. **Or set up TestFlight for easier future updates**
4. **Consider moving Device 2 to same WiFi for wireless updates**

## Files Included:
- `Runner.app` - Ready for installation
- `INSTALLATION_GUIDE.md` - This guide
EOF

# Create quick setup script for when Device 2 is connected
cat > offline_distribution/install_device2.sh << 'EOF'
#!/bin/bash

echo "📱 Quick Installation for Device 2..."

# Check if Device 2 is connected via USB
if xcrun devicectl list devices | grep -q "00008110-000064E13663801E"; then
    echo "✅ Device 2 detected via USB!"
    echo "Installing app..."
    xcrun devicectl device install app --device [DEVICE_ID] Runner.app
    echo "✅ Installation completed!"
else
    echo "❌ Device 2 not detected"
    echo "Please connect Device 2 via USB and try again"
fi
EOF

chmod +x offline_distribution/install_device2.sh

print_success "Offline distribution package created!"
echo ""
print_status "Files created in offline_distribution/:"
ls -la offline_distribution/

echo ""
print_status "Step 3: Creating TestFlight-ready setup..."

# Create TestFlight setup guide
cat > offline_distribution/TESTFLIGHT_SETUP.md << 'EOF'
# 🚀 TestFlight Setup for Multiple Devices

## Why TestFlight?
- **Easier distribution** to multiple devices
- **No WiFi requirement** for updates
- **Automatic updates** via App Store
- **Better for production** use

## Setup Steps:

### Step 1: Prepare App Store Connect
1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Create new app: "Bechaalany Debt App"
3. Set bundle ID: `com.bechaalany.debt.bechaalanyDebtApp`

### Step 2: Add Device UDIDs
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to Certificates, Identifiers & Profiles
3. Go to Devices section
4. Add both UDIDs:
   - Device 1: 00008120-001919823650A01E
   - Device 2: 00008110-000064E13663801E

### Step 3: Create Ad-hoc Provisioning Profile
1. In Apple Developer Portal, go to Profiles
2. Create new Ad Hoc profile
3. Select your App ID
4. Select both devices
5. Download and install profile

### Step 4: Build for TestFlight
```bash
# Update Xcode project with new profile
# Then build for TestFlight
flutter build ios --release
cd ios
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath ../testflight_distribution -exportOptionsPlist ExportOptions.plist
```

### Step 5: Upload to TestFlight
1. Open Xcode
2. Product → Archive
3. Distribute App
4. Upload to App Store Connect
5. Add testers via email

## Benefits:
- ✅ No WiFi requirement
- ✅ Automatic updates
- ✅ Easy distribution
- ✅ Professional solution
EOF

echo ""
print_success "🎉 Offline installation setup completed!"
echo ""
print_warning "Current Status:"
echo "✅ Device 1: Connected and app installed"
echo "❌ Device 2: Not on same WiFi - use offline methods"
echo ""
print_status "Recommended next steps:"
echo "1. Connect Device 2 via USB for immediate installation"
echo "2. Or set up TestFlight for easier future distribution"
echo "3. Consider moving Device 2 to same WiFi network"
echo ""
print_status "Files ready in offline_distribution/ folder" 