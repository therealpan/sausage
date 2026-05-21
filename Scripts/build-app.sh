#!/bin/bash
set -euo pipefail

PRODUCT_NAME="ClaudeMeter"
BUNDLE_ID="com.piirz.claudemeter"
VERSION="1.0.0"
APP_DIR="dist/${PRODUCT_NAME}.app"

echo "→ Building release..."
swift build -c release

echo "→ Creating .app bundle..."
rm -rf "dist/${PRODUCT_NAME}.app"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

cp ".build/release/${PRODUCT_NAME}" "${APP_DIR}/Contents/MacOS/${PRODUCT_NAME}"

# Copy resources (icons, etc.)
if [ -d "Sources/ClaudeMeter/Resources" ]; then
  cp -r Sources/ClaudeMeter/Resources/. "${APP_DIR}/Contents/Resources/"
fi

cat > "${APP_DIR}/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>        <string>${PRODUCT_NAME}</string>
  <key>CFBundleIdentifier</key>        <string>${BUNDLE_ID}</string>
  <key>CFBundleName</key>              <string>${PRODUCT_NAME}</string>
  <key>CFBundleDisplayName</key>       <string>ClaudeMeter</string>
  <key>CFBundleVersion</key>           <string>${VERSION}</string>
  <key>CFBundleShortVersionString</key><string>${VERSION}</string>
  <key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
  <key>CFBundlePackageType</key>       <string>APPL</string>
  <key>LSMinimumSystemVersion</key>    <string>14.0</string>
  <key>LSUIElement</key>               <integer>1</integer>
  <key>NSHighResolutionCapable</key>   <true/>
  <key>NSPrincipalClass</key>          <string>NSApplication</string>
  <key>NSSupportsAutomaticTermination</key><false/>
</dict>
</plist>
PLIST

codesign --force --deep --sign "-" "${APP_DIR}" 2>/dev/null || true

echo "✓ Built: ${APP_DIR}"
echo "  Run with: open ${APP_DIR}"
