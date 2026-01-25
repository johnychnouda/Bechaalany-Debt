#!/bin/bash

# Build script for publishing Bechaalany app
# Run this script to build both Android and iOS release versions

set -e

echo "🚀 Building Bechaalany App for Publishing"
echo "========================================"
echo ""

# Get the project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

echo "📦 Step 1: Cleaning and getting dependencies..."
flutter clean
flutter pub get

echo ""
echo "🤖 Step 2: Building Android App Bundle (AAB)..."
flutter build appbundle --release

if [ -f "build/app/outputs/bundle/release/app-release.aab" ]; then
    AAB_SIZE=$(du -h "build/app/outputs/bundle/release/app-release.aab" | cut -f1)
    echo "✅ Android AAB built successfully!"
    echo "   Location: build/app/outputs/bundle/release/app-release.aab"
    echo "   Size: $AAB_SIZE"
else
    echo "❌ Android AAB build failed!"
    exit 1
fi

echo ""
echo "🍎 Step 3: Installing iOS pods..."
cd ios
pod install
cd ..

echo ""
echo "🍎 Step 4: Building iOS IPA..."
echo "   (This may take 5-15 minutes)"
flutter build ipa --release

if [ -f "build/ios/ipa/bechaalany_connect.ipa" ]; then
    IPA_SIZE=$(du -h "build/ios/ipa/bechaalany_connect.ipa" | cut -f1)
    echo "✅ iOS IPA built successfully!"
    echo "   Location: build/ios/ipa/bechaalany_connect.ipa"
    echo "   Size: $IPA_SIZE"
elif [ -d "build/ios/ipa" ] && [ "$(ls -A build/ios/ipa/*.ipa 2>/dev/null)" ]; then
    IPA_FILE=$(ls build/ios/ipa/*.ipa | head -1)
    IPA_SIZE=$(du -h "$IPA_FILE" | cut -f1)
    echo "✅ iOS IPA built successfully!"
    echo "   Location: $IPA_FILE"
    echo "   Size: $IPA_SIZE"
else
    echo "⚠️  iOS IPA may not have been created. Check for errors above."
    echo "   You can try building manually: flutter build ipa --release"
fi

echo ""
echo "✅ Build process complete!"
echo ""
echo "📱 Next Steps:"
echo "   1. Read PUBLISH_NOW.md for step-by-step publishing instructions"
echo "   2. Upload Android AAB to Google Play Console"
echo "   3. Upload iOS IPA to App Store Connect"
echo ""
