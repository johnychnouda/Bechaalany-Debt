# 🔍 How to Find the Provisioning Profile Dropdown

## The Issue:
The "Provisioning Profile" dropdown is **hidden** when "Automatically manage signing" is **checked**.

## Solution:

### Step 1: Uncheck "Automatically manage signing"
1. **In Xcode**, with the Runner target selected
2. **Go to "Signing & Capabilities"** tab
3. **Look for "Automatically manage signing"** checkbox
4. **UNCHECK this box** (click to remove the checkmark)

### Step 2: The Dropdown Will Appear
After unchecking "Automatically manage signing", you should see:
- **Team** dropdown
- **Bundle Identifier** field
- **Provisioning Profile** dropdown ← **This is what you need!**

## Visual Guide:

```
BEFORE (Automatically manage signing = CHECKED):
┌─────────────────────────────────────────┐
│ Signing & Capabilities                  │
│ ┌─────────────────────────────────────┐ │
│ │ ☑️ Automatically manage signing    │ │
│ │ Team: U7Z33GC75W                   │ │
│ │ Bundle Identifier: com.bechaalany..│ │
│ │ [No Provisioning Profile dropdown] │ │
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘

AFTER (Automatically manage signing = UNCHECKED):
┌─────────────────────────────────────────┐
│ Signing & Capabilities                  │
│ ┌─────────────────────────────────────┐ │
│ │ ☐ Automatically manage signing     │ │
│ │ Team: U7Z33GC75W                   │ │
│ │ Bundle Identifier: com.bechaalany..│ │
│ │ Provisioning Profile: [Dropdown ▼] │ │ ← HERE!
│ └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

## Step-by-Step Instructions:

### 1. Open Xcode Project
- Xcode should already be open with your project

### 2. Select Runner Target
- **Click on "Runner"** (blue project icon) in left sidebar
- **Click on "Runner"** under TARGETS (not the project)

### 3. Go to Signing & Capabilities
- **Click "Signing & Capabilities"** tab at the top

### 4. Uncheck Automatic Signing
- **Find "Automatically manage signing"** checkbox
- **Click to UNCHECK it** (remove the checkmark)
- **You might see a warning** - click "Disable Automatic"

### 5. Find the Provisioning Profile Dropdown
- **After unchecking**, you should see:
  - Team dropdown
  - Bundle Identifier field
  - **Provisioning Profile dropdown** ← This is what you need!

### 6. Select Your Ad-hoc Profile
- **Click the Provisioning Profile dropdown**
- **Select your ad-hoc profile** from the list
- **If you don't see it**, you need to download it first

## If You Still Can't Find It:

### Check 1: Are you in the right place?
- Make sure you clicked on **"Runner" under TARGETS** (not the project)
- Make sure you're in **"Signing & Capabilities"** tab

### Check 2: Is "Automatically manage signing" unchecked?
- This is the most common reason the dropdown is hidden
- You MUST uncheck this to see the provisioning profile dropdown

### Check 3: Do you have a provisioning profile installed?
- If you don't see any profiles in the dropdown:
  1. Go to [Apple Developer Portal](https://developer.apple.com/account/)
  2. Download your ad-hoc provisioning profile
  3. Double-click the .mobileprovision file to install it
  4. Restart Xcode

## Troubleshooting:

### "Automatically manage signing" is grayed out?
- Make sure you have the correct team selected
- Check that you're signed in with the right Apple ID

### No profiles in the dropdown?
- Download your ad-hoc provisioning profile from Apple Developer Portal
- Double-click the .mobileprovision file to install it
- Restart Xcode and try again

### Getting signing errors?
- Make sure both device UDIDs are in your Apple Developer account
- Verify the provisioning profile includes both devices
- Check that the bundle identifier matches exactly

## Success Indicators:
- ✅ "Automatically manage signing" is UNCHECKED
- ✅ You can see the "Provisioning Profile" dropdown
- ✅ Your ad-hoc profile appears in the dropdown
- ✅ No red error messages
- ✅ Build succeeds (Cmd+B)

---

**Let me know if you can see the "Automatically manage signing" checkbox and whether it's checked or unchecked!** 