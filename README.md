# Bechaalany Debt Management App

A professional Flutter mobile application for managing customer debts and payments for Bechaalany Connect shop.

## Features

- **Dashboard Overview**: Real-time statistics and debt summaries
- **Customer Management**: Add and manage customer information
- **Debt Tracking**: Record and track customer debts and payments
- **Payment History**: Complete payment history and status tracking
- **Professional UI**: Clean, modern interface with brand consistency

## App Structure

```
lib/
├── constants/
│   ├── app_colors.dart      # Color scheme and brand colors
│   └── app_theme.dart       # App theme and styling
├── models/
│   ├── customer.dart         # Customer data model
│   └── debt.dart            # Debt transaction model
├── screens/
│   └── home_screen.dart     # Main dashboard screen
├── widgets/
│   ├── dashboard_card.dart  # Reusable dashboard cards
│   ├── recent_debts_list.dart # Recent debts display
│   └── stats_summary.dart   # Statistics overview widget
└── main.dart               # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK (latest stable version)
- iOS Simulator or physical iOS device (for iOS development)
- Android Studio or Android SDK (for Android development)
- Xcode (for iOS development on macOS)

### Installation

1. Clone the repository
2. Navigate to the project directory:
   ```bash
   cd bechaalany_debt_app
   ```

3. Install dependencies:
   ```bash
   flutter pub get
   ```

4. **Firebase Setup** (Required):
   - The app is configured for Firebase on both iOS and Android
   - For Android: You need to add an Android app to your Firebase project and update `lib/firebase_options.dart` with the Android app ID
   - Replace `YOUR_ANDROID_APP_ID` in `lib/firebase_options.dart` with your actual Android app ID from Firebase Console
   - Download `google-services.json` and place it in `android/app/` directory

5. Run the app:
   ```bash
   flutter run
   ```

## Web (browser)

The same Firebase backend powers the web app — users sign in with the same account and see the same data as on mobile.

### Run locally

```bash
flutter run -d chrome
```

### Build & deploy to Firebase Hosting

```bash
./build_web.sh
firebase deploy --only hosting --project bechaalany-debt-app-e1bb0
```

Live URL after deploy: `https://bechaalany-debt-app-e1bb0.web.app`

### One-time Firebase / Google setup for web sign-in

1. [Firebase Console](https://console.firebase.google.com/project/bechaalany-debt-app-e1bb0/authentication/providers) → enable **Google** sign-in.
2. **Authentication → Settings → Authorized domains** — ensure `localhost` and `bechaalany-debt-app-e1bb0.web.app` are listed.
3. [Google Cloud Console](https://console.cloud.google.com/apis/credentials?project=bechaalany-debt-app-e1bb0) → OAuth **Web client** (`908856160324-8ft1tgo1lv5jmp1dr4astcankuq54u4a`) → **Authorized JavaScript origins** (include every port you use locally, e.g. Flutter’s default or `--web-port`):
   - `http://localhost`
   - `http://localhost:5000`
   - `http://localhost:7357`
   - `https://bechaalany-debt-app-e1bb0.web.app`
   - `https://bechaalany-debt-app-e1bb0.firebaseapp.com`

### Apple Sign-In on web

**Does not work on `localhost`.** Apple only allows Sign in with Apple on HTTPS domains you register. Use Google on local dev, or test Apple on the deployed site.

1. [Firebase Console](https://console.firebase.google.com/project/bechaalany-debt-app-e1bb0/authentication/providers) → enable **Apple** and fill in **all** fields: Services ID, Apple Team ID, Key ID, and the `.p8` private key (same Apple key as iOS is fine).
2. [Apple Developer](https://developer.apple.com/account/resources/identifiers/list/serviceId) → your **Services ID** (must match Firebase) → **Sign in with Apple** → **Configure** for **Web**:
   - **Domains and Subdomains:** `bechaalany-debt-app-e1bb0.firebaseapp.com` (required — OAuth completes on this host even when the app is served from `.web.app`)
   - **Return URLs:** `https://bechaalany-debt-app-e1bb0.firebaseapp.com/__/auth/handler` (exact match, no trailing slash)
3. Link the Services ID to your primary App ID under **Identifiers → App ID → Sign in with Apple → Edit**.
4. Test at [https://bechaalany-debt-app-e1bb0.web.app](https://bechaalany-debt-app-e1bb0.web.app) (hard refresh after deploy). Apple sign-in uses a full-page redirect; you return signed in or see a specific error on the sign-in screen.
5. Users sign in with the **same Apple ID** as on iPhone — one account, shared data.

If Apple still fails, the sign-in screen will show the Firebase/Apple error code — most often `invalid_client` or `invalid_request` means step 2 return URL or Services ID mismatch.

## Design System

The app uses a professional design system with:

- **Primary Colors**: Blue (#2563EB) - representing trust and professionalism
- **Secondary Colors**: Green (#10B981) - for success states and payments
- **Status Colors**: 
  - Success: Green for paid debts
  - Warning: Orange for pending debts
  - Error: Red for overdue debts

## Brand Integration

The app is designed to integrate seamlessly with your Bechaalany Connect brand:

- Professional color scheme that can be customized to match your brand
- Clean, modern interface that reflects your business values
- Consistent typography and spacing
- Placeholder for your logo (currently using a wallet icon)

## Next Steps

1. **Logo Integration**: Replace the placeholder logo with your actual Bechaalany Connect logo
2. **Color Customization**: Update the color scheme to match your brand colors from the Figma design
3. **Additional Screens**: Add customer management, debt entry, and detailed views
4. **Data Persistence**: Implement local storage or backend integration
5. **Notifications**: Add payment reminders and overdue alerts

## Development Guidelines

- Follow Flutter best practices and conventions
- Use clean architecture principles
- Maintain consistent code formatting
- Write comprehensive documentation
- Test thoroughly on both iOS and Android devices

## Support

For any questions or customization requests, please refer to the project documentation or contact the development team.

---

**Bechaalany Connect** - Professional Debt Management Solution
