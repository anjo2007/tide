#!/bin/bash

# Exit on error
set -e

echo "=== Starting Tide Build Script for Vercel ==="

# 1. Clone Flutter SDK if it doesn't exist
if [ ! -d "flutter" ]; then
  echo "Cloning Flutter SDK (stable channel)..."
  git clone --depth 1 --branch stable https://github.com/flutter/flutter.git
else
  echo "Flutter SDK already exists, skipping clone."
fi

# 2. Add Flutter to PATH
export PATH="$PATH:$(pwd)/flutter/bin"

echo "=== Checking Flutter Version ==="
flutter --version

# 3. Enable Web support
echo "=== Enabling Flutter Web ==="
flutter config --enable-web

# 4. Get dependencies
echo "=== Fetching Flutter Dependencies ==="
flutter pub get

# 5. Build Web Release
echo "=== Building Flutter Web Application ==="
flutter build web --release

echo "=== Build Completed Successfully! ==="
