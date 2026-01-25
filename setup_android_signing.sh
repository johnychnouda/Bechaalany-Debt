#!/bin/bash

# Android Release Signing Setup Script
# This script helps you create a keystore for Android app signing

echo "=========================================="
echo "Android Release Signing Setup"
echo "=========================================="
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ ERROR: keytool not found!"
    echo "   keytool comes with Java JDK. Please install Java JDK first."
    echo "   On macOS: brew install openjdk"
    exit 1
fi

# Set default keystore location
KEYSTORE_DIR="$HOME"
KEYSTORE_FILE="$KEYSTORE_DIR/upload-keystore.jks"
KEYSTORE_ALIAS="upload"

echo "This script will create a keystore file for signing your Android app."
echo ""
echo "Keystore location: $KEYSTORE_FILE"
echo "Alias: $KEYSTORE_ALIAS"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Keep your keystore file and passwords SAFE!"
echo "   - You'll need this keystore for ALL future app updates"
echo "   - If you lose it, you CANNOT update your app on Google Play"
echo "   - Store a backup in a secure location"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo ""
    echo "⚠️  WARNING: Keystore file already exists at: $KEYSTORE_FILE"
    read -p "Do you want to overwrite it? (yes/no): " overwrite
    if [ "$overwrite" != "yes" ]; then
        echo "Cancelled. Using existing keystore."
        KEYSTORE_EXISTS=true
    else
        rm "$KEYSTORE_FILE"
        KEYSTORE_EXISTS=false
    fi
else
    KEYSTORE_EXISTS=false
fi

if [ "$KEYSTORE_EXISTS" = false ]; then
    echo ""
    echo "Creating keystore..."
    echo "You will be prompted for:"
    echo "  1. Keystore password (remember this!)"
    echo "  2. Key password (can be same as keystore password)"
    echo "  3. Your name and organization details"
    echo ""
    
    keytool -genkey -v \
        -keystore "$KEYSTORE_FILE" \
        -keyalg RSA \
        -keysize 2048 \
        -validity 10000 \
        -alias "$KEYSTORE_ALIAS"
    
    if [ $? -eq 0 ]; then
        echo ""
        echo "✅ Keystore created successfully!"
    else
        echo ""
        echo "❌ ERROR: Failed to create keystore"
        exit 1
    fi
fi

# Create key.properties file
echo ""
echo "Creating key.properties file..."

PROPERTIES_FILE="android/key.properties"

# Get absolute path to keystore
KEYSTORE_ABSOLUTE_PATH=$(cd "$(dirname "$KEYSTORE_FILE")" && pwd)/$(basename "$KEYSTORE_FILE")

echo ""
echo "Please enter your keystore password:"
read -s STORE_PASSWORD

echo "Please enter your key password (or press Enter to use same as keystore password):"
read -s KEY_PASSWORD

if [ -z "$KEY_PASSWORD" ]; then
    KEY_PASSWORD="$STORE_PASSWORD"
fi

cat > "$PROPERTIES_FILE" << EOF
storePassword=$STORE_PASSWORD
keyPassword=$KEY_PASSWORD
keyAlias=$KEYSTORE_ALIAS
storeFile=$KEYSTORE_ABSOLUTE_PATH
EOF

echo ""
echo "✅ key.properties file created at: $PROPERTIES_FILE"
echo ""
echo "=========================================="
echo "✅ Setup Complete!"
echo "=========================================="
echo ""
echo "Your keystore is ready for release builds."
echo ""
echo "Next steps:"
echo "  1. Test your release build: flutter build appbundle --release"
echo "  2. Keep your keystore file safe: $KEYSTORE_FILE"
echo "  3. Backup your keystore to a secure location"
echo ""
