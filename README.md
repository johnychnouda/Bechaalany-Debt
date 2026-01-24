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
