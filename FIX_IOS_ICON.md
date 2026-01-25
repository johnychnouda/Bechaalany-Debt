# Fix iOS App Icon Showing as Black Square

## Problem
The Bechaalany app icon is showing as a black square on your iPhone instead of the custom icon.

## Cause
iOS caches app icons. When you update the icon, iOS may still show the old cached version (or a placeholder) until you:
1. Completely uninstall the app
2. Rebuild and reinstall the app
3. Clear iOS icon cache

## Solution

### Step 1: Stop the App
1. Stop the app if it's currently running
2. Close Xcode if it's open

### Step 2: Uninstall the App from Simulator/Device
**On Simulator:**
- Long press the app icon
- Tap the "X" to delete
- Confirm deletion

**On Physical Device:**
- Long press the app icon
- Tap "Remove App" → "Delete App"
- Confirm deletion

### Step 3: Clean Build
```bash
cd /Users/johnychnouda/Desktop/bechaalany_debt_app
flutter clean
```

### Step 4: Rebuild and Reinstall
```bash
# For simulator
flutter run

# OR for physical device
flutter run --release
```

### Step 5: If Still Black - Rebuild in Xcode
1. Open Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. In Xcode:
   - Product → Clean Build Folder (Shift+Cmd+K)
   - Product → Build (Cmd+B)
   - Product → Run (Cmd+R)

### Step 6: Verify Icon Files
Check that icons are generated:
```bash
ls -lh ios/Runner/Assets.xcassets/AppIcon.appiconset/
```

You should see multiple icon files (20x20, 29x29, 40x40, 60x60, 76x76, 1024x1024, etc.)

## Alternative: Force Icon Refresh

If the above doesn't work:

1. **Delete Derived Data:**
   - In Xcode: Xcode → Preferences → Locations
   - Click arrow next to "Derived Data" path
   - Delete the folder for your project

2. **Reset Simulator (if using simulator):**
   - Device → Erase All Content and Settings

3. **Rebuild completely:**
   ```bash
   flutter clean
   cd ios
   pod deintegrate
   pod install
   cd ..
   flutter pub get
   flutter run
   ```

## Verify Icon Source

Make sure your source icon (`assets/images/app_icon.png`) is not actually black:
- The icon should be 1024x1024 pixels
- It should have your actual logo/design
- It should not be a solid black square

## After Fix

Once the icon appears correctly:
- The icon will persist for future builds
- You won't need to do this again unless you change the icon

---

**Note:** Icons have been regenerated. You just need to uninstall and reinstall the app to see the new icon.
