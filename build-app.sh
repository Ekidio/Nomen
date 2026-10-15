#!/bin/bash
# Builds build/Nomen.app (release, ad-hoc signed).
set -euo pipefail
cd "$(dirname "$0")"

swift build -c release

APP=build/Nomen.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/Nomen "$APP/Contents/MacOS/Nomen"
cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --sign - "$APP"

echo "Kész: $(pwd)/$APP"
