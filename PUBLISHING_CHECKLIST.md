# App Store & Google Play Publishing Checklist

## ✅ Fixed Issues

1. **iOS Entitlements** - Removed unused `aps-environment` (push notifications not used)
2. **iOS Info.plist** - Removed placeholder "New Exception Domain"
3. **Android Build Config** - Added comments about signing requirements

## ⚠️ Critical Issues to Fix Before Publishing

### 1. Android Release Signing (REQUIRED)
**Status:** ⚠️ Currently using debug keys - MUST be fixed before publishing

**Action Required:**
1. Create a keystore file:
   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties`:
   ```properties
   storePassword=<your-keystore-password>
   keyPassword=<your-key-password>
   keyAlias=upload
   storeFile=<path-to-keystore>/upload-keystore.jks
   ```

3. Update `android/app/build.gradle.kts` to use release signing config
   - See: https://docs.flutter.dev/deployment/android#signing-the-app

**Current Status:** Using debug signing (line 38 in build.gradle.kts)

---

### 2. Unused Permissions (RECOMMENDED)
**Status:** ⚠️ Many permissions declared but not used - may cause store rejections

**Android Permissions to Review:**
- `CAMERA` - Not used (no image picker found)
- `READ_CONTACTS` - Not used
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` - Not used
- `RECORD_AUDIO` - Not used
- `READ_EXTERNAL_STORAGE` / `WRITE_EXTERNAL_STORAGE` - Deprecated on Android 13+, may not be needed

**iOS Permission Descriptions to Review:**
- `NSBluetoothAlwaysUsageDescription` / `NSBluetoothPeripheralUsageDescription` - Not used
- `NSCalendarsUsageDescription` - Not used
- `NSCameraUsageDescription` - Not used
- `NSContactsUsageDescription` - Not used
- `NSLocationAlwaysAndWhenInUseUsageDescription` / `NSLocationWhenInUseUsageDescription` - Not used
- `NSMicrophoneUsageDescription` - Not used
- `NSSiriUsageDescription` - Not used

**Note:** `local_auth` package is in dependencies but not used. If you plan to use biometric auth, keep `USE_BIOMETRIC`/`USE_FINGERPRINT` and `NSFaceIDUsageDescription`. Otherwise, consider removing them.

**Action:** Remove unused permissions to avoid App Store/Play Store review issues.

---

## 📋 Store Listing Requirements

### App Store (iOS)
- [ ] App name: "Bechaalany" (configured in Info.plist)
- [ ] Bundle ID: `com.bechaalany.debt.bechaalanyDebtApp`
- [ ] Version: 1.1.1 (build 3)
- [ ] App icon: ✅ Configured (1024x1024 required for App Store)
- [ ] Screenshots (required for all device sizes)
- [ ] App description
- [ ] Privacy policy URL (REQUIRED)
- [ ] Support URL
- [ ] Marketing URL (optional)
- [ ] Age rating
- [ ] App Store categories
- [ ] Keywords
- [ ] Promotional text (optional)
- [ ] App preview video (optional)

### Google Play Store (Android)
- [ ] App name: "Bechaalany Connect" (configured in AndroidManifest.xml)
- [ ] Package name: `com.bechaalany.debt.bechaalanyDebtApp`
- [ ] Version: 1.1.1 (versionCode: 3)
- [ ] App icon: ✅ Configured
- [ ] Feature graphic (1024x500)
- [ ] Screenshots (phone, tablet, TV if applicable)
- [ ] App description (short and full)
- [ ] Privacy policy URL (REQUIRED)
- [ ] Content rating questionnaire
- [ ] Target audience
- [ ] App category
- [ ] Contact details (email, phone, website)

---

## 🔐 Security & Compliance

### Required
- [x] Firebase configured correctly
- [x] Encryption declaration (ITSAppUsesNonExemptEncryption: false)
- [ ] Privacy policy URL (MUST be provided in store listings)
- [ ] Terms of service (recommended)

### Data Collection
Your app collects:
- User authentication data (Firebase Auth)
- Financial/debt data (Firestore)
- Customer information

**Action Required:** Create and host a privacy policy that explains:
- What data is collected
- How it's used
- How it's stored (Firebase)
- User rights (data deletion, etc.)

---

## 🧪 Testing Checklist

Before submitting:
- [ ] Test on physical iOS device (iPhone)
- [ ] Test on physical Android device
- [ ] Test all authentication methods (Google, Apple)
- [ ] Test core features (debt management, receipts, sharing)
- [ ] Test subscription flow (if applicable)
- [ ] Test offline functionality
- [ ] Test app updates/migrations
- [ ] Test on different screen sizes
- [ ] Test with slow network connection
- [ ] Verify no debug logs in production build

---

## 📱 Build Commands

### iOS
```bash
flutter build ipa --release
```
Then upload via Xcode or Transporter app.

### Android
```bash
flutter build appbundle --release
```
Then upload to Google Play Console.

**Note:** Ensure Android signing is configured before building release.

---

## 🚨 Common Rejection Reasons

1. **Missing Privacy Policy** - Both stores require it
2. **Unused Permissions** - Can cause rejections
3. **Debug/Development Configuration** - Ensure production configs
4. **Missing App Icons** - All sizes must be present
5. **Crash on Launch** - Test thoroughly before submitting
6. **Incomplete Store Listing** - Fill all required fields

---

## 📝 Current Configuration Summary

### App Info
- **Name:** Bechaalany / Bechaalany Connect
- **Version:** 1.1.1+3
- **Bundle ID (iOS):** com.bechaalany.debt.bechaalanyDebtApp
- **Package (Android):** com.bechaalany.debt.bechaalanyDebtApp

### Firebase
- **Project ID:** bechaalany-debt-app-e1bb0
- **iOS App ID:** 1:908856160324:ios:08460e3562c039349f8c11
- **Android App ID:** 1:908856160324:android:1a848127d23fd5c59f8c11

### Dependencies
- Firebase Core, Auth, Firestore, Functions ✅
- Google Sign-In ✅
- Apple Sign-In ✅
- PDF generation ✅
- Share functionality ✅

---

## ✅ Next Steps

1. **IMMEDIATE:** Set up Android release signing
2. **IMMEDIATE:** Create and host privacy policy
3. **RECOMMENDED:** Remove unused permissions
4. **BEFORE SUBMISSION:** Complete all store listing requirements
5. **BEFORE SUBMISSION:** Test thoroughly on physical devices
6. **BEFORE SUBMISSION:** Build release versions and verify

---

## 📞 Support Resources

- [Flutter Android Deployment](https://docs.flutter.dev/deployment/android)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Google Play Console Help](https://support.google.com/googleplay/android-developer)
