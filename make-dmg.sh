#!/bin/bash
# Builds build/Nomen-<version>.dmg: the app, an Applications shortcut and a background with an arrow.
set -euo pipefail
cd "$(dirname "$0")"

VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" Resources/Info.plist)
DMG=build/Nomen-$VERSION.dmg
VOLUME=Nomen
STAGE=build/dmg-stage
RW=build/Nomen-rw.dmg

./build-app.sh

rm -rf "$STAGE" "$RW" "$DMG"
mkdir -p "$STAGE/.background"
cp -R build/Nomen.app "$STAGE/"
ln -s /Applications "$STAGE/Applications"
swift Scripts/make-dmg-background.swift "$STAGE/.background"
tiffutil -cathidpicheck "$STAGE/.background/background.png" "$STAGE/.background/background@2x.png" \
    -out "$STAGE/.background/background.tiff" >/dev/null 2>&1
rm "$STAGE/.background/"*.png

# Detach a volume left over from an earlier run.
if [ -d "/Volumes/$VOLUME" ]; then hdiutil detach "/Volumes/$VOLUME" -force -quiet || true; fi

hdiutil create -srcfolder "$STAGE" -volname "$VOLUME" -fs HFS+ -format UDRW -ov "$RW" -quiet
DEVICE=$(hdiutil attach "$RW" -readwrite -noverify -noautoopen | awk '/Apple_HFS/ {print $1}')
sleep 1

# Window layout (needs Finder automation permission; the DMG still works without it).
osascript <<EOF || echo "Figyelem: a Finder elrendezést nem sikerült beállítani."
tell application "Finder"
    tell disk "$VOLUME"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {200, 120, 840, 616}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 112
        set text size of viewOptions to 13
        set background picture of viewOptions to file ".background:background.tiff"
        set position of item "Nomen.app" of container window to {160, 190}
        set position of item "Applications" of container window to {480, 190}
        update without registering applications
        delay 1
        close
    end tell
end tell
EOF

chmod -Rf go-w "/Volumes/$VOLUME" || true
sync
hdiutil detach "$DEVICE" -quiet
hdiutil convert "$RW" -format UDZO -imagekey zlib-level=9 -o "$DMG" -quiet
rm -rf "$RW" "$STAGE"

echo "Kész: $(pwd)/$DMG"
