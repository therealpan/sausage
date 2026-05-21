#!/bin/bash
set -euo pipefail

BUNDLE_ID="com.piirz.claudemeter"
PLIST_PATH="${HOME}/Library/LaunchAgents/${BUNDLE_ID}.plist"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_PATH="${SCRIPT_DIR}/../dist/ClaudeMeter.app"
EXECUTABLE="${APP_PATH}/Contents/MacOS/ClaudeMeter"
LOG_DIR="${HOME}/Library/Logs/ClaudeMeter"

if [ ! -f "${EXECUTABLE}" ]; then
  echo "Error: ClaudeMeter.app not found. Run Scripts/build-app.sh first."
  exit 1
fi

mkdir -p "${LOG_DIR}"

cat > "${PLIST_PATH}" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${BUNDLE_ID}</string>
  <key>ProgramArguments</key>
  <array>
    <string>${EXECUTABLE}</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <dict>
    <key>SuccessfulExit</key>
    <false/>
  </dict>
  <key>LimitLoadToSessionType</key>
  <array>
    <string>Aqua</string>
  </array>
  <key>StandardOutPath</key>
  <string>${LOG_DIR}/stdout.log</string>
  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/stderr.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>${HOME}</string>
    <key>PATH</key>
    <string>/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin</string>
  </dict>
</dict>
</plist>
PLIST

launchctl unload "${PLIST_PATH}" 2>/dev/null || true
launchctl load "${PLIST_PATH}"

echo "✓ LaunchAgent installed: ${PLIST_PATH}"
echo "  Logs: ${LOG_DIR}/"
echo ""
echo "  To uninstall:"
echo "  launchctl unload ${PLIST_PATH} && rm ${PLIST_PATH}"
