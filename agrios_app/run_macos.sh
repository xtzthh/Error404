#!/bin/bash
# Run Flutter app on macOS desktop

cd "$(dirname "$0")"

echo "📱 Starting AGRIOS Flutter App on macOS..."
echo "=========================================="
echo ""

# Check Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found in PATH"
    echo "Adding Flutter to PATH..."
    export PATH="$HOME/flutter/bin:$PATH"
fi

# Run on macOS
echo "🚀 Launching app on macOS desktop..."
flutter run -d macos
