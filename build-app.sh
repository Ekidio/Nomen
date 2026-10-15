#!/bin/bash
# Builds build/Nomen.app (release, universal: Apple Silicon + Intel, ad-hoc signed).
set -euo pipefail
cd "$(dirname "$0")"

ARCHS=(--arch arm64 --arch x86_64)
swift build -c release "${ARCHS[@]}"
BIN=$(swift build -c release "${ARCHS[@]}" --show-bin-path)

APP=build/Nomen.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/Nomen" "$APP/Contents/MacOS/Nomen"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"

echo "Kész: $(pwd)/$APP"
