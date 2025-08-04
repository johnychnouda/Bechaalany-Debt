# 📱 Wireless Distribution Guide for Bechaalany Debt App

## 🎯 **Quick Setup for Wireless Distribution**

Since you have the device UDIDs but can't physically connect the devices, here are your options:

### **Option 1: TestFlight (Recommended)**
- **Pros:** Easy, official Apple solution, no device limits
- **Cons:** Requires App Store Connect setup
- **Steps:**
  1. Upload app to App Store Connect
  2. Add testers via email
  3. Testers install TestFlight app
  4. Install your app through TestFlight

### **Option 2: Ad-hoc IPA with Enterprise Distribution**
- **Pros:** Direct control, no App Store review
- **Cons:** Requires enterprise certificate, device registration
- **Steps:**
  1. Add device UDIDs to Apple Developer account
  2. Create ad-hoc provisioning profile
  3. Build IPA file
  4. Distribute via web server or services like Diawi

### **Option 3: Web-based Installation**
- **Pros:** No App Store, direct installation
- **Cons:** Requires HTTPS server, device registration
- **Steps:**
  1. Host IPA on HTTPS server
  2. Create manifest.plist file
  3. Users visit web page to install

## 🔧 **Immediate Steps to Take**

### **Step 1: Add Device UDIDs**
1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Go to **Devices** section
4. Click **+** to add new device
5. Enter device UDIDs one by one
6. Save changes

### **Step 2: Create Ad-hoc Provisioning Profile**
1. In Apple Developer Portal, go to **Profiles**
2. Click **+** to create new profile
3. Select **Ad Hoc** distribution
4. Choose your App ID: `com.bechaalany.debt.bechaalanyDebtApp`
5. Select the devices you want to support
6. Download the `.mobileprovision` file

### **Step 3: Update Xcode Project**
1. Open `ios/Runner.xcodeproj` in Xcode
2. Select **Runner** target
3. Go to **Signing & Capabilities**
4. Select your new ad-hoc provisioning profile
5. Verify Team ID is correct: `U7Z33GC75W`

### **Step 4: Build IPA for Wireless Distribution**
```bash
# After updating the provisioning profile
flutter build ios --release
cd ios
xcodebuild -exportArchive -archivePath build/Runner.xcarchive -exportPath ../wireless_distribution -exportOptionsPlist ExportOptions.plist
```

## 📋 **Current Status**

✅ **App built successfully**  
✅ **All bugs fixed** (ios18_service.dart, notification service)  
❌ **Need ad-hoc provisioning profile with device UDIDs**  
❌ **Need to update Xcode project**  

## 🚀 **Quick Wireless Solutions**

### **For Immediate Testing:**
1. **TestFlight:** Upload to App Store Connect
2. **Diawi:** Upload IPA to diawi.com for web distribution
3. **Firebase App Distribution:** Use Google's service
4. **HockeyApp:** Microsoft's distribution platform

### **For Production:**
1. **App Store:** Submit for review
2. **Enterprise Distribution:** Use enterprise certificate
3. **Ad-hoc with web server:** Host IPA on HTTPS server

## 📞 **Next Actions**

1. **Add your device UDIDs to Apple Developer account**
2. **Create ad-hoc provisioning profile**
3. **Update Xcode project with new profile**
4. **Rebuild app with correct provisioning**
5. **Create IPA for wireless distribution**

## 🔗 **Useful Links**

- [Apple Developer Portal](https://developer.apple.com/account/)
- [TestFlight](https://developer.apple.com/testflight/)
- [Diawi](https://www.diawi.com/)
- [Firebase App Distribution](https://firebase.google.com/docs/app-distribution)

---

**Need help with any specific step? Let me know and I'll guide you through it!** 