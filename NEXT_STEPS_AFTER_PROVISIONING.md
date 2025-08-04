# ✅ Next Steps After Selecting Provisioning Profile

## Great! You've successfully:
- ✅ Found the provisioning profile dropdown
- ✅ Selected your ad-hoc provisioning profile
- ✅ Got your file configured

## Now Let's Complete the Setup:

### Step 1: Verify Your Configuration
1. **Check that there are no red error messages** in the signing section
2. **Verify your settings look like this:**
   - Team: `U7Z33GC75W`
   - Bundle Identifier: `com.bechaalany.debt.bechaalanyDebtApp`
   - Provisioning Profile: [Your ad-hoc profile name]

### Step 2: Test the Build
1. **Press Cmd+B** to build the project
2. **Look for "Build Succeeded"** message
3. **If you see errors**, let me know what they say

### Step 3: Build the Ad-hoc IPA
Once the build succeeds, run this command in Terminal:

```bash
./ad_hoc_distribution/build_ad_hoc_ipa.sh
```

This will create an IPA file that you can install on both devices.

### Step 4: Install on Devices
After the IPA is built, you can install it on both devices:

#### For Device 1 (iPhone 15):
1. **Connect Device 1 to Mac via USB**
2. **Open Xcode → Window → Devices and Simulators**
3. **Select Device 1 from the list**
4. **Drag the Runner.app to Applications section**

#### For Device 2 (New device):
1. **Connect Device 2 to Mac via USB**
2. **Open Xcode → Window → Devices and Simulators**
3. **Select Device 2 from the list**
4. **Drag the Runner.app to Applications section**

### Step 5: Trust Developer Certificate
On each device after installation:
1. **Go to Settings → General → VPN & Device Management**
2. **Find your developer certificate**
3. **Tap "Trust"** for the certificate

## Quick Commands:

### Build and Create IPA:
```bash
./ad_hoc_distribution/build_ad_hoc_ipa.sh
```

### Check Connected Devices:
```bash
xcrun devicectl list devices
```

### Install via Command Line (if devices are connected):
```bash
./ad_hoc_distribution/install_via_usb.sh
```

## Success Indicators:
- ✅ No red error messages in Xcode
- ✅ Build succeeds (Cmd+B)
- ✅ IPA file created successfully
- ✅ Devices appear in Xcode Devices window
- ✅ Apps install without errors

## Troubleshooting:

### If build fails:
- Check that both UDIDs are in your Apple Developer account
- Verify the provisioning profile includes both devices
- Make sure the bundle identifier matches exactly

### If devices don't appear:
- Check USB cable connection
- Trust this computer on the device
- Unlock the device screen

### If app doesn't install:
- Check device registration in Apple Developer account
- Trust developer certificate on device
- Restart the device

## Next Steps:
1. **Test the build** (Cmd+B in Xcode)
2. **Run the ad-hoc build script**
3. **Connect devices via USB**
4. **Install on both devices**

---

**Let me know if the build succeeds (Cmd+B) and we'll continue with the next steps!** 