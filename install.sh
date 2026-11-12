#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_BIN="$HOME/.local/bin/mgy-tray"
LAUNCH_DIR="$HOME/Library/LaunchAgents"
PLIST_FILE="$LAUNCH_DIR/dev.mgy.tray.plist"
DATA_DIR="$HOME/.local/share/mgy-tray"

echo "==> Mempersiapkan direktori..."
mkdir -p "$HOME/.local/bin" "$LAUNCH_DIR" "$DATA_DIR"

echo "==> Mengompilasi main.swift -> $TARGET_BIN..."
swiftc -O "$SCRIPT_DIR/main.swift" -o "$TARGET_BIN"
chmod +x "$TARGET_BIN"

echo "==> Memasang LaunchAgent background service..."
cat << EOF > "$PLIST_FILE"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>dev.mgy.tray</string>
    <key>ProgramArguments</key>
    <array>
        <string>$TARGET_BIN</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$DATA_DIR/mgy-tray.log</string>
    <key>StandardErrorPath</key>
    <string>$DATA_DIR/mgy-tray.err.log</string>
    <key>ProcessType</key>
    <string>Interactive</string>
</dict>
</plist>
EOF

echo "==> Menjalankan service via launchctl..."
launchctl unload "$PLIST_FILE" 2>/dev/null || true
launchctl load "$PLIST_FILE"

echo "==> Selesai! mgy-quota-tray telah aktif di menu bar."
