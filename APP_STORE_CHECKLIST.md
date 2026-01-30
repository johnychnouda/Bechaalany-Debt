# App Store Connect Verification Checklist

Use this checklist to verify your App Store Connect submission is compliant with Guideline 3.1.1.

---

## 1. Build Verification

### Current Build Status
- [ ] **Build number is 1.1.1 (3) or later**
  - Location: App Store Connect → My Apps → [Your App] → [Version]
  - Verify the build matches your latest compliant version
  - Commit: `21ac3a3a` (Replace subscription with access-based model)

- [ ] **Build date is after pricing removal**
  - Should be dated after January 2026
  - Check in App Store Connect → TestFlight → Builds

---

## 2. Screenshots & Media

### App Preview Screenshots
- [ ] **Screenshot 1 (Main screen)** - No pricing visible
- [ ] **Screenshot 2 (Features)** - No subscription plans
- [ ] **Screenshot 3 (Access screen)** - Shows "Request FREE Access", not pricing
- [ ] **Screenshot 4 (Settings)** - No subscription management
- [ ] **Screenshot 5 (Other screens)** - No payment options

### Screenshots to REMOVE if present:
- ❌ Any screenshot showing "Plans & pricing" section
- ❌ Any screenshot showing "$5.00" or "$99.00" subscription prices
- ❌ Any screenshot showing "Monthly Plan" or "Yearly Plan"
- ❌ Any screenshot showing payment method selection
- ❌ Any screenshot showing "Subscribe" or "Purchase" buttons

### Screenshots to ADD:
- ✅ Request Access screen showing "Free Trial" status
- ✅ Trial details showing days remaining
- ✅ Contact admin section (clarified for FREE access requests)
- ✅ Main dashboard showing debt management features
- ✅ Settings screen showing business features

### App Preview Videos
- [ ] **No videos show pricing or subscriptions**
  - Review all uploaded videos frame-by-frame
  - Look for any mention of prices, plans, or subscriptions

---

## 3. App Information

### App Description

**Current description should emphasize:**
- [ ] App is **FREE** (use this word prominently)
- [ ] Access is **admin-granted** (no payment required)
- [ ] Trial period for evaluation
- [ ] Debt management for small businesses

**Should NOT mention:**
- ❌ Subscriptions
- ❌ Pricing plans
- ❌ Monthly/yearly fees
- ❌ In-app purchases
- ❌ Payment methods

### Suggested Description Template:

```
Bechaalany Connect - FREE Debt Management

Completely FREE debt management app for small businesses. Track customer debts, payments, and revenue with ease.

✨ KEY FEATURES:
• Customer debt tracking
• Payment history and reminders
• Revenue calculations
• Product catalog management
• WhatsApp automation
• Multi-currency support (USD/LBP)
• Data backup & recovery

🎁 FREE ACCESS:
• Start with a free trial period
• Request continued FREE access from administrator
• No subscriptions or payments required
• All features available at no cost

📱 PERFECT FOR:
• Small business owners
• Shop keepers
• Retailers
• Service providers
• Anyone managing customer credit

🔒 SECURE & PRIVATE:
• Firebase-backed data security
• Sign in with Google or Apple
• Your data stays private and secure

Download now and start managing your business debts professionally - completely FREE!

Contact the administrator through the app to request continued access after your trial period.
```

- [ ] **Description updated with FREE emphasis**

### Keywords

**Good keywords:**
- free debt management
- business accounting
- customer tracking
- payment reminders
- small business
- revenue tracking
- debt tracker free

**Avoid keywords:**
- subscription
- pricing
- premium
- paid
- purchase

- [ ] **Keywords updated - no subscription mentions**

### Promotional Text

- [ ] **No mention of pricing or subscriptions**
- [ ] **Emphasizes FREE access**

### Support URL

- [ ] **Points to valid support page**
- [ ] **Support page doesn't mention pricing**

### Marketing URL

- [ ] **If present, doesn't mention subscriptions**

---

## 4. App Store Categories

- [ ] **Primary category appropriate:** Business or Finance
- [ ] **No "Subscription" category selected**

---

## 5. Pricing & Availability

### Price
- [ ] **Set to FREE ($0.00)**
- [ ] **No in-app purchases listed**

### In-App Purchases
- [ ] **Section is EMPTY**
- [ ] **No products configured**
- [ ] **No subscriptions configured**

If you see any IAP products listed:
1. Delete all in-app purchase products
2. Delete all subscription groups
3. Ensure section shows "No In-App Purchases"

---

## 6. App Privacy

### Privacy Policy
- [ ] **Privacy policy URL is valid and accessible**
- [ ] **Privacy policy states app is FREE**
- [ ] **Privacy policy clarifies no payment data collected**

### Data Collection
Review the privacy report and ensure:
- [ ] **"Purchase History" is NOT selected**
- [ ] **"Financial Info" is NOT selected**
- [ ] **"Payment Info" is NOT selected**

If these are selected, you need to:
1. Update App Privacy settings
2. Deselect payment-related data types
3. Submit updated privacy information

---

## 7. Age Rating

- [ ] **Age rating is appropriate** (likely 4+ or 9+)
- [ ] **No "In-App Purchases" indicator**

---

## 8. App Review Information

### Notes for Reviewer

**Add this note to help reviewer understand:**

```
IMPORTANT: This app is completely FREE with no in-app purchases or subscriptions.

HOW ACCESS WORKS:
1. Users receive a FREE trial period upon first login
2. After trial, users contact the administrator to request continued FREE access
3. Access is granted manually by the administrator at no cost
4. NO payment is ever required

PAYMENT REFERENCES IN APP:
All mentions of "payments" in the app refer to business operations:
- Customer debt payments (customers paying their debts to the business)
- Payment reminders for debt collection
- Business revenue tracking

The app does NOT collect any payments from app users for app access.

CONTACT ADMIN FEATURE:
The "Contact Administrator" section allows users to request FREE access, 
get support, and ask questions. It is NOT for purchasing subscriptions or 
making payments.

TEST ACCOUNT:
[Provide demo account credentials if needed]
Email: [test account]
Password: [test password]

Please test the app to verify there are no subscription purchase flows or 
payment mechanisms for app access.
```

- [ ] **Review notes added with FREE access clarification**

### Demo Account
- [ ] **Valid test account provided**
- [ ] **Test account has active access to test all features**

---

## 9. Version Release

### Version Information
- [ ] **Version number matches current build** (1.1.1)
- [ ] **What's New text doesn't mention subscriptions**

### Suggested "What's New" Text:

```
Version 1.1.1

• FREE access model - Request continued access from administrator
• Improved trial period tracking
• Enhanced debt management features
• Better currency conversion support
• Bug fixes and performance improvements

The app is completely FREE! Contact the administrator through the app 
to request continued access after your trial period.
```

- [ ] **"What's New" text updated**

---

## 10. Response to Apple Rejection

### In Resolution Center

If Apple provides a Resolution Center for the rejection:

1. **Click "Reply to App Review"**

2. **Paste this response:**

```
Dear App Review Team,

Thank you for your review. We would like to clarify that Bechaalany Connect 
does NOT require any payments or subscriptions.

APP BUSINESS MODEL:
• The app is completely FREE
• No in-app purchases exist
• No subscription fees
• Access is granted manually by administrator at no cost

CURRENT BUILD:
• Version 1.1.1 (Build 3)
• Contains NO pricing or subscription purchase options
• Shows only trial status and free access request feature

GUIDELINE 3.1.1 COMPLIANCE:
• We do not offer paid digital content or services
• No payment mechanisms are implemented in the app
• All features are available free of charge
• Contact admin feature is for requesting FREE access, not purchasing

PAYMENT REFERENCES:
All "payment" mentions in the app refer to business operations (customer 
debt payments), not app subscriptions. This is a debt management tool for 
tracking customer payments to the business.

SCREENSHOTS:
We have updated all screenshots to show the current version without any 
pricing or subscription options.

We respectfully request a re-review. The current build fully complies with 
App Store guidelines as it contains no payment mechanisms for app access.

Please let us know if you need additional clarification.

Best regards,
Bechaalany Connect Team
```

- [ ] **Response submitted to Apple**

---

## 11. Re-submission Checklist

Before clicking "Submit for Review":

- [ ] ✅ Verified build is version 1.1.1 (3) or later
- [ ] ✅ Removed all screenshots showing pricing
- [ ] ✅ Uploaded new screenshots showing free access model
- [ ] ✅ Updated app description emphasizing FREE
- [ ] ✅ Removed subscription keywords
- [ ] ✅ Verified no IAP products exist
- [ ] ✅ Updated privacy report (no payment data)
- [ ] ✅ Added reviewer notes explaining free model
- [ ] ✅ Provided test account credentials
- [ ] ✅ Updated "What's New" text
- [ ] ✅ Replied to rejection in Resolution Center (if available)

---

## 12. Additional Verification

### Double-Check These Common Issues:

- [ ] **App icon doesn't mention "Premium" or "Pro"**
- [ ] **No promotional images show pricing**
- [ ] **No marketing materials uploaded show subscriptions**
- [ ] **App Store listing in all languages is consistent**
- [ ] **If you have multiple versions (iPad, iPhone), all are updated**

---

## 13. Post-Submission

After re-submitting:

- [ ] **Monitor App Store Connect for reviewer questions**
- [ ] **Respond promptly to any additional requests**
- [ ] **Keep this checklist for future reference**

---

## Need Help?

If Apple rejects again:
1. Request a phone call with App Review (available in Resolution Center)
2. Clearly explain the app is FREE with admin-granted access
3. Demonstrate the app has no payment flows
4. Emphasize business payments vs. app subscriptions distinction

---

**Checklist Version:** 1.0  
**Last Updated:** January 29, 2026  
**For App Version:** 1.1.1 (Build 3)

---

## Status Summary

**Codebase:** ✅ Compliant (no changes needed)  
**App Store Connect:** ⚠️ Needs verification (follow checklist above)  
**Response Draft:** ✅ Ready (see APP_STORE_RESPONSE.md)  
**Next Steps:** Follow this checklist to verify and update App Store Connect
