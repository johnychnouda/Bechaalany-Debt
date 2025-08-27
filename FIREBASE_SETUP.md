# 🔥 Firebase Setup Guide for Bechaalany Debt App

## **📋 Prerequisites**
- ✅ Firebase project created: `bechaalany-debt-app`
- ✅ Firebase CLI installed and logged in
- ✅ Flutter app with Firebase dependencies

## **🚀 Step 1: Get Firebase Configuration**

### **Web Configuration:**
1. Go to [Firebase Console](https://console.firebase.google.com/project/bechaalany-debt-app)
2. Click on your project: `bechaalany-debt-app`
3. Click the gear icon ⚙️ → "Project settings"
4. Scroll down to "Your apps" section
5. Click "Add app" → "Web" (</>) 
6. Register app with name: `Bechaalany Debt Web`
7. Copy the configuration object

### **iOS Configuration:**
1. In the same "Your apps" section
2. Click "Add app" → "iOS" 
3. Enter iOS bundle ID: `com.bechaalany.debt.bechaalanyDebtApp`
4. Download `GoogleService-Info.plist`
5. Add it to your iOS project

## **🔧 Step 2: Update Configuration Files**

### **Update `lib/firebase_options.dart`:**
Replace the placeholder values with your actual Firebase config:

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID',
  projectId: 'bechaalany-debt-app',
  authDomain: 'bechaalany-debt-app.firebaseapp.com',
  storageBucket: 'bechaalany-debt-app.appspot.com',
  measurementId: 'YOUR_ACTUAL_MEASUREMENT_ID',
);

static const FirebaseOptions ios = FirebaseOptions(
  apiKey: 'YOUR_ACTUAL_API_KEY',
  appId: 'YOUR_ACTUAL_APP_ID',
  messagingSenderId: 'YOUR_ACTUAL_SENDER_ID',
  projectId: 'bechaalany-debt-app',
  storageBucket: 'bechaalany-debt-app.appspot.com',
  iosClientId: 'YOUR_ACTUAL_IOS_CLIENT_ID',
  iosBundleId: 'com.bechaalany.debt.bechaalanyDebtApp',
);
```

### **Update `web/firebase-config.js`:**
Replace with your actual web config:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_ACTUAL_API_KEY",
  authDomain: "bechaalany-debt-app.firebaseapp.com",
  projectId: "bechaalany-debt-app",
  storageBucket: "bechaalany-debt-app.appspot.com",
  messagingSenderId: "YOUR_ACTUAL_SENDER_ID",
  appId: "YOUR_ACTUAL_APP_ID",
  measurementId: "YOUR_ACTUAL_MEASUREMENT_ID"
};
```

## **📱 Step 3: iOS Setup**

1. **Add GoogleService-Info.plist to iOS project:**
   - Drag `GoogleService-Info.plist` into your iOS project in Xcode
   - Make sure it's added to your app target
   - Ensure "Copy items if needed" is checked

2. **Update iOS Info.plist (if needed):**
   - Add any required permissions for Firebase

## **🌐 Step 4: Web Setup**

1. **Deploy Firestore Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Deploy Firestore Indexes:**
   ```bash
   firebase deploy --only firestore:indexes
   ```

## **🔒 Step 5: Security Rules**

Your Firestore security rules are already configured in `firestore.rules`. They allow:
- Users to access only their own data
- Anonymous authentication for data sync
- Secure data structure

## **✅ Step 6: Test Firebase Connection**

1. **Run your app:**
   ```bash
   flutter run
   ```

2. **Check Firebase initialization:**
   - Look for "Firebase initialized successfully" in console
   - Check if anonymous sign-in works

3. **Test data sync:**
   - Add a customer/debt in the app
   - Check if it appears in Firebase Console

## **🚨 Troubleshooting**

### **Common Issues:**
1. **"Firebase not initialized"** → Check configuration values
2. **"Permission denied"** → Verify Firestore rules are deployed
3. **"Network error"** → Check internet connection and Firebase project status

### **Debug Steps:**
1. Check Firebase Console for errors
2. Verify configuration values match exactly
3. Ensure all dependencies are installed
4. Check iOS bundle ID matches exactly

## **🎯 Next Steps**

After Firebase is working:
1. **Test data sync** between web and mobile
2. **Set up cPanel hosting** for web version
3. **Prepare TestFlight** for iOS distribution
4. **Test cross-platform sync** functionality

## **📞 Support**

If you encounter issues:
1. Check Firebase Console for error logs
2. Verify all configuration values are correct
3. Ensure Firebase project is active and billing is set up

---

**🎉 Congratulations!** Your debt tracking app now has cloud sync capabilities!
