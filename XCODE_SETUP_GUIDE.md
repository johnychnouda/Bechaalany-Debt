# 🔧 Xcode Project Setup Guide

## Step-by-Step Instructions for Updating Xcode Project

### Step 1: Open Xcode Project
✅ **Xcode should now be open** with your project loaded

### Step 2: Select the Runner Target
1. **In the left sidebar**, you should see your project structure
2. **Click on "Runner"** (the blue project icon at the top)
3. **In the center panel**, you'll see "TARGETS" section
4. **Click on "Runner"** under TARGETS (not the project, but the target)

### Step 3: Navigate to Signing & Capabilities
1. **With Runner target selected**, look at the top of the center panel
2. **Click on "Signing & Capabilities"** tab
3. **You should see signing options**

### Step 4: Configure Signing
1. **Make sure "Automatically manage signing" is UNCHECKED**
2. **Team:** Should show `U7Z33GC75W` (your team)
3. **Bundle Identifier:** Should be `com.bechaalany.debt.bechaalanyDebtApp`

### Step 5: Select Provisioning Profile
1. **Look for "Provisioning Profile" dropdown**
2. **Click the dropdown arrow**
3. **Select your new ad-hoc provisioning profile**
   - It should be named something like "Bechaalany Ad Hoc Profile"
   - If you don't see it, you need to download it first

### Step 6: Download Provisioning Profile (if needed)
If you don't see your ad-hoc profile:

1. **Go to [Apple Developer Portal](https://developer.apple.com/account/)**
2. **Navigate to Certificates, Identifiers & Profiles**
3. **Click on "Profiles"**
4. **Find your ad-hoc profile**
5. **Click the download button (⬇️)**
6. **Double-click the downloaded .mobileprovision file**
7. **Go back to Xcode and refresh the provisioning profile dropdown**

### Step 7: Verify Configuration
1. **Check that "Signing Certificate" shows your development certificate**
2. **Verify "Provisioning Profile" shows your ad-hoc profile**
3. **Make sure there are no red error messages**

### Step 8: Build Configuration
1. **At the top of Xcode, make sure:**
   - **Scheme:** Runner
   - **Destination:** Any iOS Device (arm64)
   - **Configuration:** Release

### Step 9: Test the Configuration
1. **Press Cmd+B** to build the project
2. **If successful**, you'll see "Build Succeeded"
3. **If there are errors**, they'll be shown in red

## Troubleshooting Common Issues:

### Issue: "No provisioning profiles found"
**Solution:**
1. Download the provisioning profile from Apple Developer Portal
2. Double-click the .mobileprovision file to install it
3. Restart Xcode
4. Try selecting the profile again

### Issue: "Bundle identifier doesn't match"
**Solution:**
1. Check that Bundle Identifier is exactly: `com.bechaalany.debt.bechaalanyDebtApp`
2. Make sure your App ID in Apple Developer Portal matches

### Issue: "Team ID doesn't match"
**Solution:**
1. Verify Team ID is: `U7Z33GC75W`
2. Make sure you're signed in with the correct Apple ID

### Issue: "Device not included in provisioning profile"
**Solution:**
1. Add both device UDIDs to Apple Developer Portal:
   - Device 1: `00008120-001919823650A01E`
   - Device 2: `00008110-000064E13663801E`
2. Recreate the provisioning profile with both devices
3. Download and install the new profile

## Visual Guide:
```
Xcode Window Layout:
┌─────────────────────────────────────────────────────────┐
│ [Runner Project] → [Runner Target] → [Signing & Capabilities]
│                                                         │
│ ┌─────────────────┐ ┌─────────────────────────────────┐ │
│ │   PROJECT       │ │      TARGET SETTINGS           │ │
│ │   Runner        │ │  ┌─────────────────────────────┐ │ │
│ │   └─ TARGETS    │ │  │ Signing & Capabilities     │ │ │
│ │       Runner    │ │  │ ┌─────────────────────────┐ │ │ │
│ │                 │ │  │ │ Team: U7Z33GC75W       │ │ │ │
│ │                 │ │  │ │ Bundle ID: com.becha...│ │ │ │
│ │                 │ │  │ │ Provisioning Profile:  │ │ │ │
│ │                 │ │  │ │ [Select Ad-hoc Profile]│ │ │ │
│ │                 │ │  │ └─────────────────────────┘ │ │ │
│ │                 │ │  └─────────────────────────────┘ │ │
│ └─────────────────┘ └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────┘
```

## Next Steps After Configuration:
1. **Build the project** (Cmd+B)
2. **If successful**, run the ad-hoc build script:
   ```bash
   ./ad_hoc_distribution/build_ad_hoc_ipa.sh
   ```
3. **Install on devices** via USB connection

## Need Help?
If you're still stuck, let me know:
- What you see in the Signing & Capabilities tab
- Any error messages
- Whether you can see your provisioning profile in the dropdown 