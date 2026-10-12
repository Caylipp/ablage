#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Ablage: Mac-Zwischenablage ans iPhone senden
# @raycast.mode compact
# Optional parameters:
# @raycast.icon 📲
# @raycast.packageName Ablage
# @raycast.description Hängt die aktuelle Mac-Zwischenablage an an-iphone.txt an; Ablage übernimmt sie beim nächsten Öffnen.

DIR="${ABLAGE_DIR:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/Ablage}"
mkdir -p "$DIR"
TEXT="$(pbpaste)"
[ -z "$TEXT" ] && { echo "Zwischenablage ist leer"; exit 0; }
# Zeilenumbrüche als \n kodieren: eine Zeile = ein Eintrag
printf '%s\n' "$(printf '%s' "$TEXT" | python3 -c 'import sys; print(sys.stdin.read().replace("\\","\\\\").replace("\n","\\n"), end="")')" >> "$DIR/an-iphone.txt"
echo "An iPhone gesendet: ${TEXT:0:50}"
