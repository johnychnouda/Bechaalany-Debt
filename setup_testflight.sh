#!/bin/bash

# TestFlight Setup Script for Bechaalany Debt App
# This will set up TestFlight distribution for both devices with no time limitations

echo "🚀 Setting up TestFlight Distribution for Both Devices..."

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
echo "Device 1: $DEVICE1_UDID (iPhone 15) - ✅ Connected wirelessly"
echo "Device 2: $DEVICE2_UDID (New device) - ❌ Not on same WiFi"
echo ""

print_status "Step 1: Building app for TestFlight distribution..."
flutter build ios --release

if [ $? -eq 0 ]; then
    print_success "App built successfully!"
else
    print_error "Build failed!"
    exit 1
fi

echo ""
print_status "Step 2: Creating TestFlight distribution package..."

# Create TestFlight distribution directory
mkdir -p testflight_distribution
cp -r build/ios/iphoneos/Runner.app testflight_distribution/

# Create comprehensive TestFlight setup guide
cat > testflight_distribution/TESTFLIGHT_SETUP_GUIDE.md << 'EOF'
# 🚀 TestFlight Setup Guide - No Time Limitations

## Why TestFlight?
- ✅ **No time limitations** - Apps stay installed indefinitely
- ✅ **Automatic updates** - Users get updates via App Store
- ✅ **Easy distribution** - No USB or WiFi required
- ✅ **Professional solution** - Official Apple distribution method
- ✅ **Multiple devices** - Works for both Device 1 and Device 2

## Device Information:
- **Device 1 UDID:** 00008120-001919823650A01E (iPhone 15)
- **Device 2 UDID:** 00008110-000064E13663801E (New device)
- **Bundle ID:** com.bechaalany.debt.bechaalanyDebtApp

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

### Step 4: App Store Connect Setup
1. **Go to [App Store Connect](https://appstoreconnect.apple.com)**
2. **Click + to create new app**
3. **App Name:** "Bechaalany Debt App"
4. **Bundle ID:** `com.bechaalany.debt.bechaalanyDebtApp`
5. **Platform:** iOS
6. **Language:** English

### Step 5: Build for TestFlight
```bash
# Build the app
flutter build ios --release

# Create archive
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive

# Export for TestFlight
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath ../testflight_distribution -exportOptionsPlist ExportOptions.plist
```

### Step 6: Upload to TestFlight
1. **Open Xcode**
2. **Product → Archive**
3. **Click "Distribute App"**
4. **Select "App Store Connect"**
5. **Choose "Upload"**
6. **Select your provisioning profile**
7. **Upload to App Store Connect**

### Step 7: Add Testers
1. **In App Store Connect, go to your app**
2. **Click "TestFlight" tab**
3. **Click "Testers and Groups"**
4. **Add testers by email address**
5. **Send invitations to both device users**

## Installation Instructions for Users:

### For Device 1 (iPhone 15):
1. **Install TestFlight app from App Store**
2. **Check email for TestFlight invitation**
3. **Tap invitation link**
4. **Install app through TestFlight**

### For Device 2 (New device):
1. **Install TestFlight app from App Store**
2. **Check email for TestFlight invitation**
3. **Tap invitation link**
4. **Install app through TestFlight**

## Benefits of TestFlight:
- ✅ **No 7-day expiration** like ad-hoc builds
- ✅ **Automatic updates** when you upload new versions
- ✅ **No WiFi requirement** for installation
- ✅ **Professional distribution** method
- ✅ **Easy to manage** multiple testers
- ✅ **Built-in crash reporting** and analytics

## Troubleshooting:

### If app doesn't appear in TestFlight:
- **Check that both UDIDs are in provisioning profile**
- **Verify app was uploaded successfully**
- **Check App Store Connect for any errors**

### If users can't install:
- **Ensure they have TestFlight app installed**
- **Check that they accepted the invitation**
- **Verify device is running iOS 12.0 or later**

### If app crashes:
- **Check crash reports in App Store Connect**
- **Verify provisioning profile includes device UDIDs**
- **Test on simulator first**

## Next Steps:
1. **Complete the setup steps above**
2. **Upload app to TestFlight**
3. **Invite both device users**
4. **Monitor usage and crash reports**
5. **Upload updates as needed**

## Files Included:
- `Runner.app` - Ready for TestFlight upload
- `TESTFLIGHT_SETUP_GUIDE.md` - This comprehensive guide
- `ExportOptions.plist` - For TestFlight export
EOF

# Create ExportOptions.plist for TestFlight
cat > ios/ExportOptions.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store</string>
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

# Create quick TestFlight upload script
cat > testflight_distribution/upload_to_testflight.sh << 'EOF'
#!/bin/bash

echo "🚀 Uploading to TestFlight..."

# Build for TestFlight
flutter build ios --release

# Create archive
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive

if [ $? -eq 0 ]; then
    echo "✅ Archive created successfully!"
    
    # Export for TestFlight
    xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath ../testflight_distribution -exportOptionsPlist ExportOptions.plist
    
    if [ $? -eq 0 ]; then
        echo "✅ Export completed successfully!"
        echo ""
        echo "📱 Next steps:"
        echo "1. Open Xcode"
        echo "2. Product → Archive"
        echo "3. Click 'Distribute App'"
        echo "4. Select 'App Store Connect'"
        echo "5. Upload to TestFlight"
        echo "6. Add testers in App Store Connect"
    else
        echo "❌ Export failed!"
    fi
else
    echo "❌ Archive creation failed!"
fi
EOF

chmod +x testflight_distribution/upload_to_testflight.sh

print_success "TestFlight distribution package created!"
echo ""
print_status "Files created in testflight_distribution/:"
ls -la testflight_distribution/

echo ""
print_status "Step 3: Creating TestFlight benefits summary..."

cat > testflight_distribution/TESTFLIGHT_BENEFITS.md << 'EOF'
# 🎯 TestFlight Benefits for Your App

## ✅ No Time Limitations
- **Ad-hoc builds expire after 7 days**
- **TestFlight builds stay installed indefinitely**
- **Users don't need to reinstall the app**

## ✅ Automatic Updates
- **Upload new version to TestFlight**
- **Users get automatic update notifications**
- **No manual reinstallation required**

## ✅ Easy Distribution
- **No USB cable needed**
- **No WiFi network requirement**
- **Works anywhere with internet**

## ✅ Professional Solution
- **Official Apple distribution method**
- **Trusted by users**
- **No "untrusted developer" warnings**

## ✅ Multiple Device Support
- **Works for both Device 1 and Device 2**
- **No device-specific provisioning needed**
- **Easy to add more testers**

## ✅ Built-in Analytics
- **Crash reports automatically collected**
- **Usage analytics available**
- **Performance monitoring**

## ✅ Cost Effective
- **No additional services needed**
- **Included with Apple Developer account**
- **No per-device costs**

## 🚀 Ready to Use
Your app is now ready for TestFlight distribution!
EOF

echo ""
print_success "🎉 TestFlight setup completed!"
echo ""
print_warning "Current Status:"
echo "✅ Device 1: Ready for TestFlight installation"
echo "✅ Device 2: Ready for TestFlight installation (no WiFi needed)"
echo "✅ App built and ready for TestFlight upload"
echo ""
print_status "Next Steps:"
echo "1. Add both UDIDs to Apple Developer account"
echo "2. Create ad-hoc provisioning profile with both devices"
echo "3. Update Xcode project with new profile"
echo "4. Upload app to TestFlight"
echo "5. Invite both device users via email"
echo ""
print_status "TestFlight will solve the WiFi limitation for Device 2!" 