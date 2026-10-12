#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Ablage: Letzten iPhone-Eintrag kopieren
# @raycast.mode compact
# Optional parameters:
# @raycast.icon 📋
# @raycast.packageName Ablage
# @raycast.description Kopiert den neuesten Eintrag aus dem iPhone-Verlauf in die Mac-Zwischenablage.

DIR="${ABLAGE_DIR:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/Ablage}"
python3 - "$DIR/verlauf.json" <<'PY'
import json, subprocess, sys
try:
    items = json.load(open(sys.argv[1]))
except Exception:
    print("verlauf.json nicht gefunden – Ordner in der App gewählt?"); sys.exit(1)
if not items:
    print("Verlauf ist leer"); sys.exit(0)
text = items[0]["text"]
subprocess.run(["pbcopy"], input=text.encode())
print("Kopiert: " + text.replace("\n", " ")[:60])
PY
