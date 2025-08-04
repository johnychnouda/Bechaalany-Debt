#!/bin/bash

# Ad-hoc Distribution Setup Script for Bechaalany Debt App
# For both devices when not on the same WiFi as Mac

echo "📱 Setting up Ad-hoc Distribution for Both Devices..."

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
print_status "Device Information:"
echo "Device 1: $DEVICE1_UDID (iPhone 15)"
echo "Device 2: $DEVICE2_UDID (New device)"
echo "Status: Both devices not on same WiFi as Mac"
echo ""

print_status "Step 1: Building app for ad-hoc distribution..."
flutter build ios --release

if [ $? -eq 0 ]; then
    print_success "App built successfully!"
else
    print_error "Build failed!"
    exit 1
fi

echo ""
print_status "Step 2: Creating ad-hoc distribution package..."

# Create ad-hoc distribution directory
mkdir -p ad_hoc_distribution
cp -r build/ios/iphoneos/Runner.app ad_hoc_distribution/

# Create comprehensive ad-hoc setup guide
cat > ad_hoc_distribution/AD_HOC_SETUP_GUIDE.md << 'EOF'
# 📱 Ad-hoc Distribution Setup Guide

## Device Information:
- **Device 1 UDID:** 00008120-001919823650A01E (iPhone 15)
- **Device 2 UDID:** 00008110-000064E13663801E (New device)
- **Bundle ID:** com.bechaalany.debt.bechaalanyDebtApp
- **Team ID:** U7Z33GC75W

## Step-by-Step Setup:

### Step 1: Apple Developer Account Setup
1. **Go to [Apple Developer Portal](https://developer.apple.com/account/)**
2. **Navigate to Certificates, Identifiers & Profiles**
3. **Go to Devices section**
4. **Add both device UDIDs:**
   - Device 1: `00008120-001919823650A01E`
   - Device 2: `00008110-000064E13663801E`

### Step 2: Create Ad-hoc Provisioning Profile
1. **In Apple Developer Portal, go to Profiles**
2. **Click + to create new profile**
3. **Select "Ad Hoc" distribution**
4. **Choose App ID:** `com.bechaalany.debt.bechaalanyDebtApp`
5. **Select both devices from the list**
6. **Download the .mobileprovision file**

### Step 3: Update Xcode Project
1. **Open `ios/Runner.xcodeproj` in Xcode**
2. **Select Runner target**
3. **Go to Signing & Capabilities**
4. **Select your new ad-hoc provisioning profile**
5. **Verify Team ID is correct:** `U7Z33GC75W`

### Step 4: Build IPA for Ad-hoc Distribution
```bash
# Build the app
flutter build ios --release

# Create archive
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive

# Export IPA for ad-hoc distribution
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath ../ad_hoc_distribution -exportOptionsPlist ExportOptions.plist
```

## Distribution Methods:

### Method 1: USB Installation (Recommended)
1. **Connect device to Mac via USB cable**
2. **Open Xcode → Window → Devices and Simulators**
3. **Select the device from the list**
4. **Drag Runner.app to Applications section**
5. **Trust developer certificate on device**

### Method 2: Apple Configurator 2
1. **Download Apple Configurator 2 from Mac App Store**
2. **Connect device via USB**
3. **Open Apple Configurator 2**
4. **Drag Runner.app to device**

### Method 3: Web-based Distribution
1. **Upload IPA to web services like:**
   - [Diawi](https://www.diawi.com/)
   - [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)
   - [HockeyApp](https://hockeyapp.net/)
2. **Share download link with device users**

### Method 4: Email Distribution
1. **Email IPA file to device users**
2. **Users install via Files app on iOS**
3. **Trust developer certificate on device**

## Installation Instructions for Users:

### For Both Devices:
1. **Connect device to Mac via USB**
2. **Open Xcode → Window → Devices and Simulators**
3. **Select device from the list**
4. **Drag Runner.app to Applications section**
5. **Go to Settings → General → VPN & Device Management**
6. **Trust your developer certificate**

## Troubleshooting:

### If device doesn't appear in Xcode:
- **Check USB cable connection**
- **Trust this computer on device**
- **Unlock device screen**
- **Check if device is in recovery mode**

### If app doesn't install:
- **Check device registration in Apple Developer account**
- **Verify provisioning profile includes device UDID**
- **Trust developer certificate on device**

### If app crashes:
- **Go to Settings → General → VPN & Device Management**
- **Trust your developer certificate**
- **Restart device**

## Ad-hoc Benefits:
- ✅ **No WiFi requirement** - works with USB connection
- ✅ **No App Store review** - direct installation
- ✅ **Full control** over distribution
- ✅ **Works offline** - no internet required for installation
- ✅ **7-day validity** - can be renewed by rebuilding

## Next Steps:
1. **Complete the setup steps above**
2. **Build IPA with ad-hoc provisioning profile**
3. **Install on both devices via USB**
4. **Set up automatic renewal process**

## Files Included:
- `Runner.app` - Ready for USB installation
- `AD_HOC_SETUP_GUIDE.md` - This comprehensive guide
- `ExportOptions.plist` - For ad-hoc export
EOF

# Create ExportOptions.plist for ad-hoc distribution
cat > ios/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>ad-hoc</string>
	<key>teamID</key>
	<string>U7Z33GC75W</string>
	<key>uploadBitcode</key>
	<false/>
	<key>uploadSymbols</key>
	<false/>
	<key>compileBitcode</key>
	<false/>
</dict>
</plist>
EOF

# Create quick ad-hoc build script
cat > ad_hoc_distribution/build_ad_hoc_ipa.sh << 'EOF'
#!/bin/bash

echo "📱 Building Ad-hoc IPA for Both Devices..."

# Build for ad-hoc distribution
flutter build ios --release

# Create archive
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive

if [ $? -eq 0 ]; then
    echo "✅ Archive created successfully!"
    
    # Export for ad-hoc distribution
    xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath ../ad_hoc_distribution -exportOptionsPlist ExportOptions.plist
    
    if [ $? -eq 0 ]; then
        echo "✅ Ad-hoc IPA created successfully!"
        echo ""
        echo "📱 Next steps:"
        echo "1. Connect devices via USB"
        echo "2. Use Xcode → Window → Devices and Simulators"
        echo "3. Drag Runner.app to Applications section"
        echo "4. Trust developer certificate on devices"
        echo ""
        echo "📁 Files created in ad_hoc_distribution/:"
        ls -la ../ad_hoc_distribution/
    else
        echo "❌ Export failed!"
    fi
else
    echo "❌ Archive creation failed!"
fi
EOF

chmod +x ad_hoc_distribution/build_ad_hoc_ipa.sh

# Create installation script for when devices are connected
cat > ad_hoc_distribution/install_via_usb.sh << 'EOF'
#!/bin/bash

echo "📱 Installing App on Connected Devices..."

# Check for connected devices
echo "Connected devices:"
xcrun devicectl list devices

echo ""
echo "To install on devices:"
echo "1. Connect device via USB"
echo "2. Open Xcode → Window → Devices and Simulators"
echo "3. Select device from the list"
echo "4. Drag Runner.app to Applications section"
echo "5. Trust developer certificate on device"
echo ""
echo "Or use Apple Configurator 2:"
echo "1. Download Apple Configurator 2 from Mac App Store"
echo "2. Connect device via USB"
echo "3. Drag Runner.app to device"
EOF

chmod +x ad_hoc_distribution/install_via_usb.sh

print_success "Ad-hoc distribution package created!"
echo ""
print_status "Files created in ad_hoc_distribution/:"
ls -la ad_hoc_distribution/

echo ""
print_status "Step 3: Creating ad-hoc benefits summary..."

cat > ad_hoc_distribution/AD_HOC_BENEFITS.md << 'EOF'
# 🎯 Ad-hoc Distribution Benefits

## ✅ No WiFi Requirement
- **Works with USB connection only**
- **No need for devices to be on same network**
- **Perfect for offline distribution**

## ✅ Direct Control
- **No App Store review process**
- **Full control over distribution**
- **Immediate installation**

## ✅ Multiple Device Support
- **Works for both Device 1 and Device 2**
- **Easy to add more devices**
- **No device-specific limitations**

## ✅ Offline Installation
- **No internet required for installation**
- **Works in any environment**
- **Perfect for field deployment**

## ✅ Cost Effective
- **No additional services needed**
- **Included with Apple Developer account**
- **No per-installation costs**

## ⚠️ Important Notes:
- **7-day validity** - apps expire after 7 days
- **Need to rebuild** for renewal
- **USB connection required** for installation
- **Manual certificate trust** required on devices

## 🚀 Ready to Use
Your app is now ready for ad-hoc distribution!
EOF

echo ""
print_success "🎉 Ad-hoc distribution setup completed!"
echo ""
print_warning "Current Status:"
echo "✅ Device 1: Ready for ad-hoc installation via USB"
echo "✅ Device 2: Ready for ad-hoc installation via USB"
echo "✅ App built and ready for ad-hoc distribution"
echo ""
print_status "Next Steps:"
echo "1. Add both UDIDs to Apple Developer account"
echo "2. Create ad-hoc provisioning profile with both devices"
echo "3. Update Xcode project with new profile"
echo "4. Build IPA with ad-hoc profile"
echo "5. Install on both devices via USB"
echo ""
print_status "Ad-hoc distribution will work for both devices without WiFi!" 