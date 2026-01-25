#!/usr/bin/env python3
"""
Automated Android Keystore Creation Script
This script creates the keystore and key.properties file automatically.
"""

import subprocess
import sys
import os
from getpass import getpass

def run_command(cmd, input_text=None):
    """Run a command and return the result"""
    try:
        if input_text:
            result = subprocess.run(
                cmd,
                input=input_text,
                text=True,
                capture_output=True,
                check=True
            )
        else:
            result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        return True, result.stdout
    except subprocess.CalledProcessError as e:
        return False, e.stderr

def create_keystore():
    """Create the Android keystore"""
    print("=" * 50)
    print("Android Keystore Creation")
    print("=" * 50)
    print()
    print("⚠️  IMPORTANT: You'll need to remember these passwords!")
    print("   - Keep them in a secure location (password manager)")
    print("   - You'll need them for all future app updates")
    print()
    
    # Get keystore password
    while True:
        store_password = getpass("Enter keystore password (min 6 characters): ")
        if len(store_password) < 6:
            print("❌ Password must be at least 6 characters. Try again.")
            continue
        confirm_password = getpass("Re-enter keystore password: ")
        if store_password != confirm_password:
            print("❌ Passwords don't match. Try again.")
            continue
        break
    
    # Get key password
    print()
    key_password = getpass("Enter key password (or press Enter to use same as keystore): ")
    if not key_password:
        key_password = store_password
    
    # Get user information
    print()
    print("Enter your information for the certificate:")
    name = input("Your name or company name: ").strip() or "Bechaalany"
    org_unit = input("Organizational Unit (press Enter to skip): ").strip() or ""
    organization = input("Organization (press Enter to skip): ").strip() or name
    city = input("City: ").strip() or "Unknown"
    state = input("State/Province (press Enter to skip): ").strip() or ""
    country = input("Country code (2 letters, e.g., US): ").strip() or "US"
    
    if len(country) != 2:
        country = "US"
        print("⚠️  Using default country code: US")
    
    # Build the keytool command
    keystore_path = os.path.expanduser("~/upload-keystore.jks")
    
    # Create the DNAME string
    dname_parts = []
    if name:
        dname_parts.append(f"CN={name}")
    if org_unit:
        dname_parts.append(f"OU={org_unit}")
    if organization:
        dname_parts.append(f"O={organization}")
    if city:
        dname_parts.append(f"L={city}")
    if state:
        dname_parts.append(f"ST={state}")
    if country:
        dname_parts.append(f"C={country}")
    
    dname = ",".join(dname_parts)
    
    print()
    print("Creating keystore...")
    print(f"Location: {keystore_path}")
    print()
    
    # Build command with passwords
    cmd = [
        "keytool",
        "-genkey",
        "-v",
        "-keystore", keystore_path,
        "-alias", "upload",
        "-keyalg", "RSA",
        "-keysize", "2048",
        "-validity", "10000",
        "-storepass", store_password,
        "-keypass", key_password,
        "-dname", dname
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print("✅ Keystore created successfully!")
        print()
        return True, store_password, key_password, keystore_path
    except subprocess.CalledProcessError as e:
        print(f"❌ Error creating keystore: {e.stderr}")
        return False, None, None, None

def create_key_properties(store_password, key_password, keystore_path):
    """Create the key.properties file"""
    properties_path = "android/key.properties"
    
    # Get absolute path
    abs_keystore_path = os.path.abspath(os.path.expanduser(keystore_path))
    
    content = f"""storePassword={store_password}
keyPassword={key_password}
keyAlias=upload
storeFile={abs_keystore_path}
"""
    
    try:
        os.makedirs("android", exist_ok=True)
        with open(properties_path, "w") as f:
            f.write(content)
        print(f"✅ Created {properties_path}")
        return True
    except Exception as e:
        print(f"❌ Error creating key.properties: {e}")
        return False

def main():
    """Main function"""
    # Check if keytool is available
    success, _ = run_command(["which", "keytool"])
    if not success:
        print("❌ Error: keytool not found. Please install Java JDK.")
        print("See INSTALL_JAVA.md for instructions.")
        sys.exit(1)
    
    # Check if keystore already exists
    keystore_path = os.path.expanduser("~/upload-keystore.jks")
    if os.path.exists(keystore_path):
        print(f"⚠️  Keystore already exists at: {keystore_path}")
        response = input("Do you want to overwrite it? (yes/no): ").strip().lower()
        if response != "yes":
            print("Cancelled.")
            sys.exit(0)
        os.remove(keystore_path)
        print("Removed existing keystore.")
        print()
    
    # Create keystore
    success, store_password, key_password, keystore_path = create_keystore()
    
    if not success:
        print("❌ Failed to create keystore.")
        sys.exit(1)
    
    # Create key.properties
    print()
    print("Creating key.properties file...")
    success = create_key_properties(store_password, key_password, keystore_path)
    
    if not success:
        print("❌ Failed to create key.properties file.")
        sys.exit(1)
    
    print()
    print("=" * 50)
    print("✅ Setup Complete!")
    print("=" * 50)
    print()
    print("Your keystore is ready for release builds.")
    print()
    print("⚠️  IMPORTANT - Save this information securely:")
    print(f"   Keystore location: {keystore_path}")
    print(f"   Keystore password: [Remember this!]")
    print(f"   Key password: [Remember this!]")
    print()
    print("Next steps:")
    print("  1. Backup your keystore file to a secure location")
    print("  2. Test your release build: flutter build appbundle --release")
    print()

if __name__ == "__main__":
    main()
