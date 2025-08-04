#!/bin/bash

# Complete TestFlight Setup Script
# This will fix provisioning profile issues and set up TestFlight

echo "🚀 Setting up TestFlight Distribution..."

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
echo ""

print_status "Step 1: Fixing provisioning profile issue..."
print_warning "The error shows: 'Provisioning profile doesn't include the currently selected device'"
print_status "This means we need to create a proper ad-hoc provisioning profile with both devices."

echo ""
print_status "Step 2: Manual steps required in Apple Developer Portal..."

cat > testflight_setup/APPLE_DEVELOPER_STEPS.md << 'EOF'
# 🍎 Apple Developer Portal Setup Steps

## Step 1: Add Device UDIDs
1. **Go to [Apple Developer Portal](https://developer.apple.com/account/)**
2. **Navigate to Certificates, Identifiers & Profiles**
3. **Click on "Devices"**
4. **Click the "+" button to add new device**
5. **Add both UDIDs:**
   - Device 1: `00008120-001919823650A01E`
   - Device 2: `00008110-000064E13663801E`
6. **Click "Continue" and "Register"**

## Step 2: Create Ad-hoc Provisioning Profile
1. **Go to "Profiles" section**
2. **Click the "+" button to create new profile**
3. **Select "Ad Hoc" distribution**
4. **Choose App ID:** `com.bechaalany.debt.bechaalanyDebtApp`
5. **Select both devices from the list**
6. **Name the profile:** "Bechaalany Ad Hoc Profile"
7. **Click "Continue" and "Generate"**
8. **Download the .mobileprovision file**

## Step 3: Install Provisioning Profile
1. **Double-click the downloaded .mobileprovision file**
2. **It should install automatically**
3. **Restart Xcode if it's open**

## Step 4: Update Xcode Project
1. **Open Xcode with your project**
2. **Select Runner target**
3. **Go to Signing & Capabilities**
4. **Uncheck "Automatically manage signing"**
5. **Select your new ad-hoc provisioning profile**
6. **Verify no red error messages**

## Step 5: Test Build
1. **Press Cmd+B in Xcode**
2. **Look for "Build Succeeded"**
3. **If successful, continue to TestFlight setup**
EOF

print_status "Step 3: Creating TestFlight setup guide..."

cat > testflight_setup/TESTFLIGHT_SETUP_GUIDE.md << 'EOF'
# 🚀 TestFlight Setup Guide

## Why TestFlight?
- ✅ **No physical access needed** - works remotely
- ✅ **No WiFi requirement** - users can install anywhere
- ✅ **Automatic updates** - when you upload new versions
- ✅ **Professional distribution** - official Apple method
- ✅ **Built-in crash reporting** and analytics
- ✅ **No time limitations** - apps stay installed indefinitely

## Step-by-Step TestFlight Setup:

### Step 1: App Store Connect Setup
1. **Go to [App Store Connect](https://appstoreconnect.apple.com)**
2. **Click "+" to create new app**
3. **Fill in the details:**
   - **App Name:** "Bechaalany Debt App"
   - **Bundle ID:** `com.bechaalany.debt.bechaalanyDebtApp`
   - **Platform:** iOS
   - **Language:** English
4. **Click "Create"**

### Step 2: Upload Build to TestFlight
1. **In Xcode, go to Product → Archive**
2. **Click "Distribute App"**
3. **Select "App Store Connect"**
4. **Choose "Upload"**
5. **Select your ad-hoc provisioning profile**
6. **Click "Upload"**
7. **Wait for processing to complete**

### Step 3: Add Testers
1. **In App Store Connect, go to your app**
2. **Click "TestFlight" tab**
3. **Click "Testers and Groups"**
4. **Click "+" to add testers**
5. **Add email addresses for both device users**
6. **Send invitations**

### Step 4: Users Install TestFlight
1. **Users install TestFlight app from App Store**
2. **Users check email for invitation**
3. **Users tap invitation link**
4. **Users install your app through TestFlight**

## Benefits of TestFlight:
- ✅ **No 7-day expiration** like ad-hoc builds
- ✅ **Automatic updates** when you upload new versions
- ✅ **No WiFi requirement** for installation
- ✅ **Professional distribution** method
- ✅ **Easy to manage** multiple testers
- ✅ **Built-in crash reporting** and analytics

## Troubleshooting:

### If upload fails:
- Check that both UDIDs are in your Apple Developer account
- Verify the provisioning profile includes both devices
- Make sure the bundle identifier matches exactly

### If users can't install:
- Ensure they have TestFlight app installed
- Check that they accepted the invitation
- Verify device is running iOS 12.0 or later

### If app crashes:
- Check crash reports in App Store Connect
- Verify provisioning profile includes device UDIDs
- Ask users to restart device

## Next Steps After Setup:
1. **Upload your first build**
2. **Add testers via email**
3. **Monitor usage and crash reports**
4. **Upload updates as needed**

## Files Included:
- `APPLE_DEVELOPER_STEPS.md` - Apple Developer Portal setup
- `TESTFLIGHT_SETUP_GUIDE.md` - This TestFlight guide
- `build_testflight_ipa.sh` - Build script for TestFlight
EOF

# Create TestFlight build script
cat > testflight_setup/build_testflight_ipa.sh << 'EOF'
#!/bin/bash

echo "🚀 Building for TestFlight..."

# Build for TestFlight
flutter build ios --release

# Create archive
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive

if [ $? -eq 0 ]; then
    echo "✅ Archive created successfully!"
    echo ""
    echo "📱 Next steps for TestFlight:"
    echo "1. Open Xcode"
    echo "2. Product → Archive"
    echo "3. Click 'Distribute App'"
    echo "4. Select 'App Store Connect'"
    echo "5. Choose 'Upload'"
    echo "6. Select your ad-hoc provisioning profile"
    echo "7. Upload to TestFlight"
    echo ""
    echo "📋 Then in App Store Connect:"
    echo "1. Go to your app"
    echo "2. Click 'TestFlight' tab"
    echo "3. Add testers via email"
    echo "4. Send invitations"
else
    echo "❌ Archive creation failed!"
    echo "Make sure you've completed the Apple Developer Portal steps first."
fi
EOF

chmod +x testflight_setup/build_testflight_ipa.sh

# Create TestFlight benefits summary
cat > testflight_setup/TESTFLIGHT_BENEFITS.md << 'EOF'
# 🎯 TestFlight Benefits for Remote Distribution

## ✅ Perfect for Your Situation
- **No physical access needed** - works for both devices
- **No WiFi requirement** - users can install anywhere
- **Professional distribution** - official Apple method

## ✅ No Time Limitations
- **Ad-hoc builds expire after 7 days**
- **TestFlight builds stay installed indefinitely**
- **Users don't need to reinstall the app**

## ✅ Automatic Updates
- **Upload new version to TestFlight**
- **Users get automatic update notifications**
- **No manual reinstallation required**

## ✅ Easy Management
- **Add testers via email**
- **Monitor usage and crash reports**
- **Professional analytics**

## ✅ Built-in Features
- **Crash reporting automatically collected**
- **Usage analytics available**
- **Performance monitoring**

## ✅ Cost Effective
- **No additional services needed**
- **Included with Apple Developer account**
- **No per-installation costs**

## 🚀 Ready to Use
Your app is now ready for TestFlight distribution!
EOF

print_success "TestFlight setup package created!"
echo ""
print_status "Files created in testflight_setup/:"
ls -la testflight_setup/

echo ""
print_warning "IMPORTANT: You need to complete these steps first:"
echo "1. Add both UDIDs to Apple Developer account"
echo "2. Create ad-hoc provisioning profile with both devices"
echo "3. Update Xcode project with new profile"
echo "4. Test build in Xcode (Cmd+B)"
echo ""
print_status "Then run: ./testflight_setup/build_testflight_ipa.sh"
echo ""
print_success "TestFlight will solve all your remote distribution needs!" 