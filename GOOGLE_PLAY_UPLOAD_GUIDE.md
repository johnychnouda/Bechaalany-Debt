# Google Play Store Upload Guide

## 📦 What You Need

- ✅ **App Bundle (AAB):** `build/app/outputs/bundle/release/app-release.aab` (54MB)
- ✅ **Privacy Policy URL:** https://bechaalany-debt-app-e1bb0.web.app/privacy-policy.html
- ✅ **App Name:** Bechaalany Connect
- ✅ **Package Name:** com.bechaalany.debt.bechaalanyDebtApp
- ✅ **Version:** 1.1.1 (versionCode: 3)

---

## Step 1: Access Google Play Console

1. Go to: https://play.google.com/console
2. Sign in with your Google account
3. Accept the Developer Distribution Agreement (if first time)

---

## Step 2: Create Your App

1. Click **"Create app"** button
2. Fill in:
   - **App name:** Bechaalany Connect
   - **Default language:** English (or your preferred language)
   - **App or game:** Select "App"
   - **Free or paid:** Select "Free" or "Paid"
   - **Declarations:** Check all applicable boxes
3. Click **"Create app"**

---

## Step 3: Complete Store Listing

Go to **Store presence → Main store listing**

### Required Information:

1. **App name:** Bechaalany Connect
2. **Short description** (80 characters max):
   ```
   Professional debt management app for tracking customer debts and payments.
   ```
3. **Full description** (4000 characters max):
   ```
   Bechaalany Connect is a professional debt management application designed for businesses to efficiently track and manage customer debts and payments.

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

   Privacy Policy: https://bechaalany-debt-app-e1bb0.web.app/privacy-policy.html
   ```

4. **App icon** (512x512 pixels):
   - Use: `assets/images/app_icon.png` (resize to 512x512 if needed)

5. **Feature graphic** (1024x500 pixels):
   - Create a promotional banner for your app
   - Can include app name, key features, or branding

6. **Screenshots** (Required - at least 2, up to 8):
   - **Phone screenshots** (required):
     - Minimum 2 screenshots
     - Recommended sizes:
       - 1080 x 1920 (portrait)
       - 1920 x 1080 (landscape)
   - **Tablet screenshots** (if supporting tablets):
     - 1200 x 1920 (portrait)
     - 1920 x 1200 (landscape)

7. **Privacy Policy URL** (Required):
   ```
   https://bechaalany-debt-app-e1bb0.web.app/privacy-policy.html
   ```

8. **Contact details:**
   - **Email:** support@bechaalany.com
   - **Phone:** +96171862577
   - **Website:** (if you have one)

9. **App category:**
   - **Category:** Business or Finance
   - **Tags:** (optional keywords)

10. **Content rating:**
    - Complete the content rating questionnaire
    - Answer questions about your app's content
    - Google will assign a rating (usually "Everyone" for business apps)

---

## Step 4: Upload Your App Bundle

1. Go to **Production** (or **Testing** for internal testing first)
2. Click **"Create new release"**
3. **Upload your AAB file:**
   - Click **"Upload"**
   - Select: `build/app/outputs/bundle/release/app-release.aab`
   - Wait for upload to complete (may take a few minutes)

4. **Release name** (optional):
   - Example: "1.1.1 - Initial Release"

5. **Release notes:**
   ```
   Initial release of Bechaalany Connect
   - Professional debt management
   - Customer tracking
   - Payment history
   - Receipt generation
   ```

6. Click **"Save"**

---

## Step 5: Complete App Content

Go to **Policy → App content**

1. **Data safety:**
   - Declare what data you collect
   - Based on your privacy policy:
     - ✅ Personal info (email, name)
     - ✅ Financial info (debt amounts, payments)
     - ✅ Authentication data
   - Explain how data is used and shared

2. **Target audience:**
   - Select appropriate age groups
   - For business apps: Usually "All ages"

3. **Ads:**
   - Declare if your app shows ads (probably "No")

---

## Step 6: Pricing and Distribution

1. **Pricing:**
   - Set as "Free" or set a price
   - If paid, set up payment methods

2. **Countries/regions:**
   - Select where your app will be available
   - Default: All countries

---

## Step 7: Review and Submit

1. Go to **Dashboard**
2. Check for any warnings or errors (red/yellow indicators)
3. Fix any issues
4. Click **"Submit for review"**

**Review time:** Usually 1-7 days

---

## Step 8: Monitor Submission

1. Check **Dashboard** for status updates
2. You'll receive email notifications about:
   - Review status
   - Approval
   - Rejection (with reasons)

---

## 📋 Pre-Submission Checklist

- [ ] App bundle (AAB) uploaded
- [ ] App name set
- [ ] Short description added (80 chars max)
- [ ] Full description added
- [ ] App icon uploaded (512x512)
- [ ] Feature graphic uploaded (1024x500)
- [ ] At least 2 phone screenshots uploaded
- [ ] Privacy policy URL added
- [ ] Contact email added
- [ ] Content rating completed
- [ ] Data safety form completed
- [ ] Target audience selected
- [ ] Pricing set
- [ ] Countries selected
- [ ] Release notes added

---

## 🚨 Common Issues and Solutions

### Issue: "App bundle is too large"
- **Solution:** Your AAB is 54MB, which is fine (limit is 150MB)

### Issue: "Missing privacy policy"
- **Solution:** Make sure the URL is publicly accessible and working

### Issue: "Screenshots required"
- **Solution:** Upload at least 2 screenshots of your app

### Issue: "Content rating incomplete"
- **Solution:** Complete the questionnaire in Policy → App content

---

## 📱 After Approval

Once approved:
1. Your app will be live on Google Play Store
2. Users can download and install
3. You can track downloads and ratings in the console
4. You can push updates by uploading new AAB files

---

## 🔄 Updating Your App

For future updates:
1. Increment version in `pubspec.yaml` (e.g., 1.1.2+4)
2. Build new AAB: `flutter build appbundle --release`
3. Upload new AAB to a new release
4. Add release notes
5. Submit for review

---

## 📞 Support

- **Google Play Console Help:** https://support.google.com/googleplay/android-developer
- **Your App Bundle:** `build/app/outputs/bundle/release/app-release.aab`
- **Privacy Policy:** https://bechaalany-debt-app-e1bb0.web.app/privacy-policy.html

---

**Good luck with your submission!** 🚀
