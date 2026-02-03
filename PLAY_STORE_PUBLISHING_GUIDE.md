# Publish Bechaalany Connect on Google Play Store

Follow these steps to publish your app on the Android Play Store.

---

## Part 1: Play Console – Create the app

1. In **Google Play Console** (the screen you showed), click **Create app**.
2. Fill in:
   - **App name:** Bechaalany Connect (or your store name).
   - **Default language:** Your choice (e.g. English).
   - **App or game:** App.
   - **Free or paid:** Free.
3. Accept the declarations (Developer Program Policies, US export laws).
4. Click **Create app**.

---

## Part 2: Prepare your app bundle (AAB)

### 2.1 Signing (release)

Your project is already set up to use `android/key.properties` for release signing.

- If you **already have** a release keystore and `android/key.properties` filled in, skip to 2.2.
- If **not**, create a keystore and key.properties:

**Create keystore (one time):**
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Use a strong password and store it safely. Never share the keystore or commit it to git.

**Create/update `android/key.properties`:**
- Copy from `android/key.properties.template` if needed.
- Set:
  - `storePassword` = keystore password  
  - `keyPassword` = key password  
  - `keyAlias` = `upload`  
  - `storeFile` = full path to the `.jks` file (e.g. `/Users/johnychnouda/upload-keystore.jks`)

Keep `key.properties` and the keystore file **out of version control** (they should be in `.gitignore`).

### 2.2 Build the App Bundle

From the project root:

```bash
flutter build appbundle
```

The file will be at:
`build/app/outputs/bundle/release/app-release.aab`

Use this **.aab** file (not APK) for Play Store.

---

## Part 3: Complete Play Console setup

After creating the app, complete the checklist on the left. Main items:

### 3.1 Dashboard / App content

- **Privacy policy:** Required.  
  Use a public URL, e.g. if you use Firebase Hosting:
  - Deploy: `firebase deploy --only hosting`
  - URL: `https://bechaalany-debt-app-e1bb0.web.app/privacy-policy`  
  (Replace with your actual project URL if different.)

### 3.2 Store listing (Main store listing)

- **App name:** Bechaalany Connect
- **Short description:** Up to 80 characters (e.g. “Debt management for small businesses.”)
- **Full description:** Up to 4000 characters – describe features, trial, contact admin, etc.
- **App icon:** 512 x 512 px PNG (no transparency).
- **Feature graphic:** 1024 x 500 px (optional but recommended).
- **Screenshots:** At least 2 (phone); 7-inch and 10-inch if you support tablets.
  - Phone: min 320px, max 3840px on shortest side.

### 3.3 Content rating

- Go to **Policy** → **App content** → **Content rating**.
- Complete the questionnaire (business/productivity, no sensitive content).
- Submit and download the rating, then assign it to the app.

### 3.4 Target audience and content

- **Target age groups:** Select as appropriate (e.g. 18+ if business-only).
- **News app:** No (unless you have news).
- **COVID-19 apps:** No.
- **Data safety:** Declare what data you collect (e.g. email, account info, Firebase). Link to your privacy policy.

### 3.5 App access

- If the app requires login, provide **demo credentials** (same idea as Apple):
  - Add a test account (e.g. with expired subscription) and provide username + password in the “App access” section so reviewers can test.

### 3.6 Ads (if applicable)

- If your app shows ads: declare it and complete the ad declaration.
- If no ads: select “No, my app does not contain ads.”

---

## Part 4: Create the release and publish

1. Go to **Release** → **Production** (or **Testing** first if you prefer).
2. **Create new release.**
3. **Upload** the `app-release.aab` from `build/app/outputs/bundle/release/`.
4. **Release name:** e.g. “1.1.1 (3)” or “Version 1.1.1”.
5. **Release notes:** Short description of what’s new (e.g. “Initial release” or “Bug fixes and improvements”).
6. **Review and roll out** (or “Start rollout to Production”).

---

## Part 5: After submission

- Review can take from a few hours to several days.
- Check **Policy and programs** and **App content** for any alerts (e.g. missing declarations).
- When approved, the app will go live on the Play Store according to your rollout (e.g. 100% production).

---

## Quick checklist

- [ ] Create app in Play Console  
- [ ] Release keystore + `key.properties` set up  
- [ ] `flutter build appbundle` succeeds  
- [ ] Privacy policy URL set and working  
- [ ] Store listing (name, short/full description, icon, screenshots)  
- [ ] Content rating completed  
- [ ] Data safety form completed  
- [ ] App access / demo account if login required  
- [ ] Production release created with AAB uploaded  
- [ ] Rollout started  

---

## Your app details (for reference)

- **Application ID:** `com.bechaalany.debt.bechaalanyDebtApp`
- **Version:** 1.1.1 (3) from pubspec.yaml
- **Privacy policy:** Deploy `public/` (or root `privacy-policy.html`) and use that URL in Play Console.

If you want, we can do the build step together or adjust store listing text for your app.
