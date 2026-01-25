# Apple App Store Upload Guide

## 📦 What You Need

- ✅ **IPA File:** Will be created when you build
- ✅ **Privacy Policy URL:** https://bechaalany-debt-app-e1bb0.web.app/privacy-policy.html
- ✅ **App Name:** Bechaalany
- ✅ **Bundle ID:** com.bechaalany.debt.bechaalanyDebtApp
- ✅ **Version:** 1.1.1 (build 3)
- ✅ **Apple Developer Account:** Required (paid membership)

---

## Step 1: Verify Apple Developer Account

1. Go to: https://developer.apple.com/account
2. Sign in with your Apple ID
3. Verify your membership is active (paid membership required)
4. Your Team ID: **U7Z33GC75W** (already configured)

---

## Step 2: Create App in App Store Connect

1. Go to: https://appstoreconnect.apple.com
2. Sign in with your Apple ID
3. Click **"My Apps"**
4. Click **"+"** → **"New App"**
5. Fill in:
   - **Platform:** iOS
   - **Name:** Bechaalany
   - **Primary Language:** English (or your preferred language)
   - **Bundle ID:** com.bechaalany.debt.bechaalanyDebtApp
   - **SKU:** bechaalany-ios-001 (unique identifier)
   - **User Access:** Full Access
6. Click **"Create"**

---

## Step 3: Build IPA

### Option A: Using Flutter CLI (Recommended)

```bash
cd /Users/johnychnouda/Desktop/bechaalany_debt_app
flutter build ipa --release
```

The IPA will be at: `build/ios/ipa/bechaalany_connect.ipa`

### Option B: Using Xcode

1. Open project:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode:
   - Select **"Any iOS Device"** as destination
   - Go to **Product → Archive**
   - Wait for archive to complete

3. In Organizer window:
   - Select your archive
   - Click **"Distribute App"**
   - Choose **"App Store Connect"**
   - Follow the wizard to upload

---

## Step 4: Upload IPA to App Store Connect

### Using Transporter App (Easiest)

1. Download **"Transporter"** from Mac App Store (free)
2. Open Transporter
3. Drag and drop your IPA file: `build/ios/ipa/bechaalany_connect.ipa`
4. Click **"Deliver"**
5. Wait for upload to complete

### Using Xcode

1. In Xcode Organizer:
   - Select your archive
   - Click **"Distribute App"**
   - Choose **"App Store Connect"**
   - Select **"Upload"**
   - Follow the wizard

### Using Command Line

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/bechaalany_connect.ipa \
  --username YOUR_APPLE_ID \
  --password YOUR_APP_SPECIFIC_PASSWORD
```

---

## Step 5: Complete App Information

Go to your app in App Store Connect → **App Information**

### Basic Information:

1. **Name:** Bechaalany
2. **Subtitle** (optional): Debt Management App
3. **Category:**
   - **Primary:** Business or Finance
   - **Secondary:** (optional)
4. **Privacy Policy URL:**
   ```
   https://bechaalany-debt-app-e1bb0.web.app/privacy-policy.html
   ```
5. **Support URL:**
   - Can use your privacy policy URL or create a support page
6. **Marketing URL** (optional):
   - Your website if you have one

---

## Step 6: Complete Store Listing

Go to **App Store → 1.0 Prepare for Submission**

### Required Information:

1. **Screenshots** (Required for all device sizes):
   
   **iPhone 6.7" Display** (iPhone 14 Pro Max, 15 Pro Max):
   - Required: At least 1 screenshot
   - Size: 1290 x 2796 pixels
   
   **iPhone 6.5" Display** (iPhone 11 Pro Max, XS Max):
   - Required: At least 1 screenshot
   - Size: 1242 x 2688 pixels
   
   **iPhone 5.5" Display** (iPhone 8 Plus):
   - Required: At least 1 screenshot
   - Size: 1242 x 2208 pixels
   
   **iPad Pro 12.9"** (if supporting iPad):
   - Size: 2048 x 2732 pixels

2. **App Preview Video** (Optional but recommended):
   - 15-30 seconds
   - Showcase your app's features

3. **Description:**
   ```
   Bechaalany is a professional debt management application designed for businesses to efficiently track and manage customer debts and payments.

   Features:
   • Dashboard Overview: Real-time statistics and debt summaries
   • Customer Management: Add and manage customer information
   • Debt Tracking: Record and track customer debts and payments
   • Payment History: Complete payment history and status tracking
   • Receipt Generation: Generate professional PDF receipts
   • Multiple Payment Methods: Track various payment types
   • Secure Cloud Sync: Your data is safely stored in the cloud
   • Professional UI: Clean, modern interface

   Perfect for small businesses, shops, and service providers who need to manage customer accounts and track outstanding debts.
   ```

4. **Keywords:**
   ```
   debt,management,business,finance,customer,payment,tracking,receipt
   ```
   (100 characters max, comma-separated)

5. **Support URL:**
   ```
   https://bechaalany-debt-app-e1bb0.web.app/privacy-policy.html
   ```

6. **Marketing URL** (optional):
   - Your website if available

7. **Promotional Text** (optional, 170 characters):
   ```
   Professional debt management for your business. Track customers, payments, and generate receipts.
   ```

8. **What's New in This Version:**
   ```
   Initial release of Bechaalany
   - Professional debt management
   - Customer tracking
   - Payment history
   - Receipt generation
   ```

---

## Step 7: Complete App Privacy

Go to **App Privacy**

1. **Data Collection:**
   - Based on your privacy policy, declare:
     - ✅ Personal Information (email, name)
     - ✅ Financial Information (debt amounts, payments)
     - ✅ Authentication Data
   
2. **Data Usage:**
   - Explain how each data type is used
   - Select purposes (App Functionality, Analytics, etc.)

3. **Data Linked to User:**
   - Yes (data is linked to user accounts)

4. **Tracking:**
   - Declare if you track users across apps (probably "No")

---

## Step 8: Complete Version Information

Go to **Version Information**

1. **Version:** 1.1.1
2. **Copyright:** © 2026 Bechaalany (or your company name)
3. **Age Rating:**
   - Complete the age rating questionnaire
   - For business apps: Usually "4+" or "12+"

---

## Step 9: Build Information

1. **Build:** Select the uploaded build
2. If no build appears:
   - Wait a few minutes (processing takes time)
   - Refresh the page
   - Check email for processing notifications

---

## Step 10: Review Information

1. **Contact Information:**
   - **First Name:** (Your name)
   - **Last Name:** (Your name)
   - **Phone Number:** +96171862577
   - **Email:** support@bechaalany.com

2. **Demo Account** (if required):
   - Some apps need a demo account for review
   - Your app might not need this

3. **Notes:**
   ```
   This is a business debt management app. No special setup required for review.
   Privacy Policy: https://bechaalany-debt-app-e1bb0.web.app/privacy-policy.html
   ```

---

## Step 11: Submit for Review

1. Review all sections for completeness
2. Check for any warnings (yellow indicators)
3. Fix any issues
4. Click **"Submit for Review"**

**Review time:** Usually 24-48 hours

---

## Step 12: Monitor Submission

1. Check **App Store Connect** for status:
   - **Waiting for Review**
   - **In Review**
   - **Ready for Sale** (approved)
   - **Rejected** (with reasons)

2. You'll receive email notifications about status changes

---

## 📋 Pre-Submission Checklist

- [ ] App created in App Store Connect
- [ ] IPA file built and uploaded
- [ ] App name set
- [ ] Description added
- [ ] Keywords added
- [ ] Screenshots uploaded (all required sizes)
- [ ] App icon configured (1024x1024)
- [ ] Privacy Policy URL added
- [ ] Support URL added
- [ ] App Privacy completed
- [ ] Age rating completed
- [ ] Version information complete
- [ ] Build selected
- [ ] Contact information added
- [ ] Review notes added (if needed)

---

## 🚨 Common Issues and Solutions

### Issue: "No builds available"
- **Solution:** Wait 10-15 minutes after upload, then refresh

### Issue: "Missing screenshots"
- **Solution:** Upload screenshots for all required device sizes

### Issue: "Privacy policy URL not accessible"
- **Solution:** Verify URL works: https://bechaalany-debt-app-e1bb0.web.app/privacy-policy.html

### Issue: "Code signing failed"
- **Solution:** Open in Xcode, verify signing in Signing & Capabilities

### Issue: "App Privacy incomplete"
- **Solution:** Complete the App Privacy section with your data collection details

---

## 📱 After Approval

Once approved:
1. Your app will be live on the App Store
2. Users can download and install
3. You can track downloads and ratings in App Store Connect
4. You can push updates by uploading new IPA files

---

## 🔄 Updating Your App

For future updates:
1. Increment version in `pubspec.yaml` (e.g., 1.1.2+4)
2. Build new IPA: `flutter build ipa --release`
3. Upload new IPA to App Store Connect
4. Update "What's New" section
5. Submit for review

---

## 📞 Support

- **App Store Connect Help:** https://help.apple.com/app-store-connect/
- **Apple Developer Support:** https://developer.apple.com/support/
- **Your Privacy Policy:** https://bechaalany-debt-app-e1bb0.web.app/privacy-policy.html

---

## 💡 Tips

1. **TestFlight:** Consider using TestFlight for beta testing before public release
2. **Screenshots:** Use real device screenshots, not simulators
3. **Description:** Make it clear and compelling
4. **Keywords:** Use relevant keywords for better discoverability
5. **Support:** Be ready to respond to user reviews and support requests

---

**Good luck with your submission!** 🚀
