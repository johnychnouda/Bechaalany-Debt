# Ad Hoc Distribution Setup Guide
## Bechaalany Debt App

This guide will walk you through setting up Ad Hoc distribution for your Flutter app, allowing you to install it on specific devices without going through the App Store.

## Prerequisites ✅
- [x] Apple Developer Account ($99/year subscription)
- [x] Mac computer with Xcode installed
- [x] iOS devices for testing
- [x] Flutter project ready

## Step 1: Apple Developer Portal Setup

### 1.1 Create App ID
1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple ID
3. Navigate to "Certificates, Identifiers & Profiles"
4. Click "Identifiers" → "+" → "App IDs"
5. Select "App" and click "Continue"
6. Fill in the details:
   - **Description**: `Bechaalany Debt App`
   - **Bundle ID**: `com.bechaalany.debt.bechaalanyDebtApp`
7. Enable capabilities as needed:
   - ✅ Built-in Backend (iCloud removed)
   - ✅ Push Notifications
   - ✅ Background Modes
8. Click "Continue" and "Register"

### 1.2 Create Development Certificate
1. Go to "Certificates" → "+" → "iOS App Development"
2. Follow the instructions to create a CSR:
   - Open "Keychain Access" on your Mac
   - Keychain Access → Certificate Assistant → Request a Certificate From a Certificate Authority
   - Fill in your email and name
   - Select "Saved to disk" and "Let me specify key pair information"
   - Choose "2048 bits" and "RSA"
   - Save the CSR file
3. Upload the CSR to Apple Developer Portal
4. Download the certificate and double-click to install

### 1.3 Register Test Devices
1. **Get Device UDIDs**:
   - Connect each test device to your Mac
   - Open Xcode → Window → Devices and Simulators
   - Select each device and copy the Identifier (UDID)

2. **Register Devices**:
   - In Apple Developer Portal, go to "Devices" → "+"
   - Add each device UDID with descriptive names
   - You can register up to 100 devices per year

### 1.4 Create Ad Hoc Provisioning Profile
1. Go to "Profiles" → "+" → "iOS App Development"
2. Select your App ID: `com.bechaalany.debt.bechaalanyDebtApp`
3. Select your Development Certificate
4. Select all the devices you want to test on
5. Name it: `Bechaalany Ad Hoc Profile`
6. Download the provisioning profile

## Step 2: Xcode Configuration

### 2.1 Install Provisioning Profile
1. Double-click the downloaded `.mobileprovision` file
2. It will automatically install in Xcode

### 2.2 Configure Project Settings
The project has been updated with an Ad Hoc build configuration. You can verify this in Xcode:

1. Open your project in Xcode: `ios/Runner.xcworkspace`
2. Select the "Runner" target
3. Go to "Signing & Capabilities"
4. You should see the Ad Hoc configuration available

## Step 3: Build and Distribute

### 3.1 Using the Automated Script
The easiest way to build your Ad Hoc version:

```bash
# Run the build script
./build_ad_hoc.sh
```

This script will:
- Clean previous builds
- Get dependencies
- Build the iOS Ad Hoc version
- Create a distribution folder with installation instructions

### 3.2 Manual Build (Alternative)
If you prefer to build manually:

```bash
# Clean and get dependencies
flutter clean
flutter pub get

# Build Ad Hoc version
flutter build ios --release --flavor AdHoc
```

## Step 4: Install on Test Devices

### 4.1 Method 1: Using Xcode
1. Connect device via USB
2. Open Xcode → Window → Devices and Simulators
3. Select your device
4. Drag the `Runner.app` from `build/ios/iphoneos/` to the Applications section

### 4.2 Method 2: Using Apple Configurator 2
1. Download Apple Configurator 2 from Mac App Store
2. Connect device via USB
3. Drag the `Runner.app` to the device

### 4.3 Method 3: Using iTunes (if available)
1. Connect device via USB
2. Open iTunes
3. Go to Apps section
4. Drag the `Runner.app` to install

## Step 5: Trust Developer Certificate

After installation, users must trust your developer certificate:

1. On the device, go to **Settings** → **General** → **VPN & Device Management**
2. Find your developer certificate
3. Tap on it and select **Trust**

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Unable to install app"
**Solution**: 
- Check if device is registered in Apple Developer Portal
- Verify the device UDID is correct
- Make sure the provisioning profile includes the device

#### Issue: App crashes on launch
**Solution**:
- Check if developer certificate is trusted on device
- Verify the provisioning profile is correct
- Make sure device is running iOS 18.0 or later

#### Issue: Build fails with signing errors
**Solution**:
- Check that the provisioning profile is installed
- Verify the bundle identifier matches
- Make sure the development team is set correctly

#### Issue: "Untrusted Developer" error
**Solution**:
- Go to Settings → General → VPN & Device Management
- Trust the developer certificate
- If not listed, reinstall the app

### Build Configuration Details

The project now includes an Ad Hoc build configuration with these settings:

```yaml
Build Configuration: AdHoc
Code Signing: Manual
Code Sign Identity: iPhone Distribution
Provisioning Profile: Bechaalany Ad Hoc Profile
Bundle Identifier: com.bechaalany.debt.bechaalanyDebtApp
Development Team: U7Z33GC75W
```

## Distribution Checklist

Before distributing to users, ensure:

- [ ] All test devices are registered in Apple Developer Portal
- [ ] Ad Hoc provisioning profile includes all devices
- [ ] Development certificate is installed on your Mac
- [ ] App builds successfully with Ad Hoc configuration
- [ ] Test installation on at least one device
- [ ] Users know how to trust the developer certificate

## Security Notes

- Ad Hoc builds are signed with your developer certificate
- Users must trust your certificate to run the app
- The app will expire when your developer certificate expires
- You can revoke certificates if needed for security

## Support

If you encounter issues:

1. Check the troubleshooting section above
2. Verify all prerequisites are met
3. Ensure device registration is correct
4. Check Apple Developer Portal for any account issues

## Next Steps

Once Ad Hoc distribution is working:

1. **Test thoroughly** on all target devices
2. **Document the process** for future builds
3. **Consider TestFlight** for easier distribution (up to 10,000 users)
4. **Plan for App Store submission** when ready for public release

---

**Last Updated**: $(date)
**App Version**: $(grep 'version:' pubspec.yaml | cut -d' ' -f2)
**Bundle ID**: com.bechaalany.debt.bechaalanyDebtApp 