# ✅ Xcode Setup Checklist

## Before You Start:
- [ ] You have both device UDIDs ready
- [ ] You've added both UDIDs to Apple Developer Portal
- [ ] You've created an ad-hoc provisioning profile
- [ ] You've downloaded the .mobileprovision file

## Xcode Configuration Steps:

### Step 1: Open Project
- [ ] Xcode is open with your project
- [ ] You can see the project structure in the left sidebar

### Step 2: Select Target
- [ ] Click on "Runner" project (blue icon)
- [ ] Click on "Runner" under TARGETS (not the project)
- [ ] You see target settings in the center panel

### Step 3: Signing & Capabilities
- [ ] Click "Signing & Capabilities" tab
- [ ] You see signing configuration options

### Step 4: Configure Signing
- [ ] "Automatically manage signing" is UNCHECKED
- [ ] Team shows: `U7Z33GC75W`
- [ ] Bundle Identifier shows: `com.bechaalany.debt.bechaalanyDebtApp`

### Step 5: Select Provisioning Profile
- [ ] Click the "Provisioning Profile" dropdown
- [ ] You can see your ad-hoc profile in the list
- [ ] Select your ad-hoc profile
- [ ] No red error messages appear

### Step 6: Verify Configuration
- [ ] Signing Certificate shows your development certificate
- [ ] Provisioning Profile shows your ad-hoc profile
- [ ] No red error messages in the signing section

### Step 7: Test Build
- [ ] Press Cmd+B to build
- [ ] Build succeeds without errors
- [ ] You see "Build Succeeded" message

## If You Get Stuck:

### Can't find the Runner target?
- Look in the left sidebar under "TARGETS"
- It should be listed under the blue "Runner" project icon

### Can't see Signing & Capabilities?
- Make sure you clicked on "Runner" under TARGETS (not the project)
- Look for tabs at the top of the center panel

### No provisioning profiles in dropdown?
- Download the .mobileprovision file from Apple Developer Portal
- Double-click the file to install it
- Restart Xcode and try again

### Getting signing errors?
- Check that both UDIDs are in your Apple Developer account
- Verify the provisioning profile includes both devices
- Make sure the bundle identifier matches exactly

## Success Indicators:
- ✅ No red error messages
- ✅ Build succeeds (Cmd+B)
- ✅ Provisioning profile is selected
- ✅ Team ID is correct

## Next Steps After Success:
1. Run the ad-hoc build script
2. Connect devices via USB
3. Install via Xcode or Apple Configurator 2

---

**Need help with a specific step? Let me know what you see in Xcode!** 