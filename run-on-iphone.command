#!/bin/bash
# run-on-iphone.command — Double-click this in Finder to run Juku on your iPhone
# Requires iPhone connected via USB with Trust enabled on the device

export PATH="$HOME/development/flutter/bin:$PATH"
cd "$HOME/Documents/Claude/Projects/Juku-Flutter" || { echo "ERROR: Juku-Flutter folder not found"; exit 1; }

echo "=============================="
echo "  Juku → iPhone via USB"
echo "=============================="
echo ""
echo "Checking Flutter installation..."
flutter --version || { echo "ERROR: Flutter not found. Check PATH."; exit 1; }

echo ""
echo "Detecting connected devices..."
flutter devices

echo ""
echo "=============================="
echo "Starting app on iPhone..."
echo "Press Ctrl+C to stop."
echo "=============================="
echo ""

flutter run

echo ""
echo "[Done] App session ended."
