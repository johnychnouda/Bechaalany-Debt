#!/bin/bash

# Simple Keystore Creation Script
# Run this in your terminal to create the keystore interactively

echo "=========================================="
echo "Android Keystore Creation"
echo "=========================================="
echo ""
echo "This will create your keystore file."
echo "You'll be asked for passwords and information."
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Use passwords that are at least 6 characters"
echo "   - Remember your passwords - write them down!"
echo "   - You'll need this keystore for all app updates"
echo ""

KEYSTORE_PATH="$HOME/upload-keystore.jks"

# Check if keystore exists
if [ -f "$KEYSTORE_PATH" ]; then
    echo "⚠️  Keystore already exists at: $KEYSTORE_PATH"
    read -p "Overwrite? (yes/no): " overwrite
    if [ "$overwrite" != "yes" ]; then
        echo "Cancelled."
        exit 0
    fi
    rm "$KEYSTORE_PATH"
fi

echo ""
echo "Creating keystore at: $KEYSTORE_PATH"
echo ""
echo "You'll be prompted for:"
echo "  1. Keystore password (min 6 characters)"
echo "  2. Key password (or press Enter for same as keystore)"
echo "  3. Your name/company information"
echo ""
read -p "Press Enter to start..."

# Create keystore with interactive prompts
keytool -genkey -v \
    -keystore "$KEYSTORE_PATH" \
    -alias upload \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore created successfully!"
    echo ""
    echo "Now I need to create the key.properties file."
    echo "Please enter your passwords again:"
    echo ""
    
    # Get passwords for key.properties
    read -sp "Enter keystore password: " STORE_PASS
    echo ""
    read -sp "Enter key password (or press Enter if same): " KEY_PASS
    echo ""
    
    if [ -z "$KEY_PASS" ]; then
        KEY_PASS="$STORE_PASS"
    fi
    
    # Get absolute path
    ABS_KEYSTORE_PATH=$(cd "$(dirname "$KEYSTORE_PATH")" && pwd)/$(basename "$KEYSTORE_PATH")
    
    # Create key.properties
    cat > android/key.properties << EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=upload
storeFile=$ABS_KEYSTORE_PATH
EOF
    
    echo ""
    echo "✅ Created android/key.properties"
    echo ""
    echo "=========================================="
    echo "✅ Setup Complete!"
    echo "=========================================="
    echo ""
    echo "Your keystore is ready!"
    echo ""
    echo "⚠️  IMPORTANT: Backup your keystore!"
    echo "   Location: $KEYSTORE_PATH"
    echo "   Store it in a secure location (password manager, encrypted cloud storage)"
    echo ""
    echo "Next step: Test your build"
    echo "   flutter build appbundle --release"
    echo ""
else
    echo ""
    echo "❌ Failed to create keystore."
    echo "Make sure your passwords are at least 6 characters."
    exit 1
fi
