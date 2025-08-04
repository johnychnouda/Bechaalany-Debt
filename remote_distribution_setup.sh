#!/bin/bash

# Remote Distribution Setup Script
# For devices that are not physically available and not on same WiFi

echo "📱 Setting up Remote Distribution for Both Devices..."

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
echo "Device 1: $DEVICE1_UDID (iPhone 15) - ❌ Not physically available"
echo "Device 2: $DEVICE2_UDID (New device) - ❌ Not physically available"
echo "Status: Both devices not on same WiFi as Mac"
echo ""

print_status "Step 1: Building app for remote distribution..."
flutter build ios --release

if [ $? -eq 0 ]; then
    print_success "App built successfully!"
else
    print_error "Build failed!"
    exit 1
fi

echo ""
print_status "Step 2: Creating remote distribution package..."

# Create remote distribution directory
mkdir -p remote_distribution
cp -r build/ios/iphoneos/Runner.app remote_distribution/

# Create comprehensive remote distribution guide
cat > remote_distribution/REMOTE_DISTRIBUTION_GUIDE.md << 'EOF'
# 📱 Remote Distribution Guide

## Device Information:
- **Device 1 UDID:** 00008120-001919823650A01E (iPhone 15)
- **Device 2 UDID:** 00008110-000064E13663801E (New device)
- **Status:** Both devices not physically available, not on same WiFi

## Distribution Options:

### Option 1: TestFlight (Recommended)
**Best for devices not physically available**

#### Setup Steps:
1. **Go to [App Store Connect](https://appstoreconnect.apple.com)**
2. **Create new app:** "Bechaalany Debt App"
3. **Bundle ID:** `com.bechaalany.debt.bechaalanyDebtApp`
4. **Add both UDIDs to Apple Developer account**
5. **Create ad-hoc provisioning profile with both devices**
6. **Upload app to TestFlight**
7. **Invite users via email**

#### Benefits:
- ✅ **No physical access needed**
- ✅ **No WiFi requirement**
- ✅ **Automatic updates**
- ✅ **Professional distribution**

### Option 2: Web-based Distribution
**For immediate distribution**

#### Services to Use:
1. **[Diawi](https://www.diawi.com/)** - Upload IPA, get download link
2. **[Firebase App Distribution](https://firebase.google.com/docs/app-distribution)** - Google's service
3. **[HockeyApp](https://hockeyapp.net/)** - Microsoft's platform
4. **[Instabug](https://instabug.com/)** - Another option

#### Steps:
1. **Build IPA with ad-hoc profile**
2. **Upload to chosen service**
3. **Share download link with device users**
4. **Users install via web link**

### Option 3: Email Distribution
**Simple but limited**

#### Steps:
1. **Build IPA with ad-hoc profile**
2. **Email IPA file to device users**
3. **Users install via Files app on iOS**
4. **Trust developer certificate on device**

### Option 4: Cloud Storage
**Using Google Drive, Dropbox, etc.**

#### Steps:
1. **Build IPA with ad-hoc profile**
2. **Upload to cloud storage (Google Drive, Dropbox, etc.)**
3. **Share download link with device users**
4. **Users download and install**

## Required Setup:

### Step 1: Apple Developer Account
1. **Add both UDIDs to Apple Developer account:**
   - Device 1: `00008120-001919823650A01E`
   - Device 2: `00008110-000064E13663801E`

### Step 2: Create Ad-hoc Provisioning Profile
1. **In Apple Developer Portal → Profiles**
2. **Create new "Ad Hoc" profile**
3. **Select both devices**
4. **Download .mobileprovision file**

### Step 3: Build IPA
```bash
# Build the app
flutter build ios --release

# Create archive
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive

# Export IPA for ad-hoc distribution
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath ../remote_distribution -exportOptionsPlist ExportOptions.plist
```

## Installation Instructions for Users:

### For TestFlight:
1. **Install TestFlight app from App Store**
2. **Check email for invitation**
3. **Tap invitation link**
4. **Install app through TestFlight**

### For Web-based Distribution:
1. **Click download link**
2. **Install via web browser**
3. **Trust developer certificate on device**

### For Email/Cloud Distribution:
1. **Download IPA file**
2. **Open Files app on iOS**
3. **Tap IPA file to install**
4. **Trust developer certificate on device**

## Troubleshooting:

### If users can't install:
- **Check device UDIDs are in provisioning profile**
- **Verify users trust developer certificate**
- **Ensure device is running iOS 12.0 or later**

### If app crashes:
- **Check crash reports in App Store Connect (TestFlight)**
- **Verify provisioning profile includes device UDIDs**
- **Ask users to restart device**

## Recommended Approach:
1. **Set up TestFlight** for professional distribution
2. **Use web-based service** (Diawi) for immediate needs
3. **Email IPA** as backup option

## Files Included:
- `Runner.app` - Ready for IPA creation
- `REMOTE_DISTRIBUTION_GUIDE.md` - This comprehensive guide
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

# Create IPA build script for remote distribution
cat > remote_distribution/build_remote_ipa.sh << 'EOF'
#!/bin/bash

echo "📱 Building IPA for Remote Distribution..."

# Build for ad-hoc distribution
flutter build ios --release

# Create archive
cd ios
xcodebuild -workspace Runner.xcworkspace -scheme Runner -configuration Release -archivePath build/Runner.xcarchive archive

if [ $? -eq 0 ]; then
    echo "✅ Archive created successfully!"
    
    # Export for ad-hoc distribution
    xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath ../remote_distribution -exportOptionsPlist ExportOptions.plist
    
    if [ $? -eq 0 ]; then
        echo "✅ IPA created successfully!"
        echo ""
        echo "📱 Remote Distribution Options:"
        echo "1. Upload to TestFlight (recommended)"
        echo "2. Upload to Diawi.com for web distribution"
        echo "3. Email IPA file to users"
        echo "4. Upload to cloud storage (Google Drive, Dropbox)"
        echo ""
        echo "📁 Files created in remote_distribution/:"
        ls -la ../remote_distribution/
    else
        echo "❌ Export failed!"
    fi
else
    echo "❌ Archive creation failed!"
fi
EOF

chmod +x remote_distribution/build_remote_ipa.sh

print_success "Remote distribution package created!"
echo ""
print_status "Files created in remote_distribution/:"
ls -la remote_distribution/

echo ""
print_status "Step 3: Creating distribution options summary..."

cat > remote_distribution/DISTRIBUTION_OPTIONS.md << 'EOF'
# 🎯 Remote Distribution Options

## Option 1: TestFlight (Best)
**Pros:**
- ✅ No physical access needed
- ✅ Professional distribution
- ✅ Automatic updates
- ✅ Built-in crash reporting

**Steps:**
1. Upload to App Store Connect
2. Add testers via email
3. Users install via TestFlight app

## Option 2: Web-based (Diawi)
**Pros:**
- ✅ Immediate distribution
- ✅ No App Store review
- ✅ Easy to use

**Steps:**
1. Upload IPA to diawi.com
2. Share download link
3. Users install via web

## Option 3: Email Distribution
**Pros:**
- ✅ Simple
- ✅ No additional services

**Steps:**
1. Email IPA file
2. Users install via Files app
3. Trust developer certificate

## Option 4: Cloud Storage
**Pros:**
- ✅ Familiar to users
- ✅ No additional services

**Steps:**
1. Upload to Google Drive/Dropbox
2. Share download link
3. Users download and install

## Recommendation:
1. **Set up TestFlight** for long-term solution
2. **Use Diawi** for immediate distribution
3. **Email IPA** as backup option
EOF

echo ""
print_success "🎉 Remote distribution setup completed!"
echo ""
print_warning "Current Status:"
echo "✅ App built and ready for remote distribution"
echo "❌ Devices not physically available"
echo "❌ Devices not on same WiFi"
echo ""
print_status "Recommended next steps:"
echo "1. Set up TestFlight for professional distribution"
echo "2. Use Diawi.com for immediate web-based distribution"
echo "3. Email IPA file as backup option"
echo ""
print_status "Remote distribution will work for both devices without physical access!" 