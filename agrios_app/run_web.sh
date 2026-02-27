#!/bin/bash
# Run Flutter app on Web (Chrome) - No Xcode needed!

cd "$(dirname "$0")"

echo "🌐 Starting AGRIOS Flutter App on Web..."
echo "========================================="
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found in PATH"
    echo "Adding Flutter to PATH..."
    export PATH="$HOME/flutter/bin:$PATH"
fi

# Enable web support
echo "🔧 Enabling web support..."
flutter config --enable-web

# Run on Chrome
echo "🚀 Launching app in Chrome browser..."
flutter run -d chrome
