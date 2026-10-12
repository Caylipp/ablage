#!/bin/bash
# Required parameters:
# @raycast.schemaVersion 1
# @raycast.title Ablage: iPhone-Verlauf durchsuchen
# @raycast.mode compact
# @raycast.argument1 { "type": "text", "placeholder": "Suchbegriff" }
# Optional parameters:
# @raycast.icon 🔎
# @raycast.packageName Ablage
# @raycast.description Kopiert den neuesten Eintrag aus dem iPhone-Verlauf, der den Suchbegriff enthält.

DIR="${ABLAGE_DIR:-$HOME/Library/Mobile Documents/com~apple~CloudDocs/Ablage}"
python3 - "$DIR/verlauf.json" "$1" <<'PY'
import json, subprocess, sys
try:
    items = json.load(open(sys.argv[1]))
except Exception:
    print("verlauf.json nicht gefunden"); sys.exit(1)
q = sys.argv[2].lower()
hits = [i for i in items if q in i["text"].lower() or q in (i.get("title") or "").lower()]
if not hits:
    print("Nichts gefunden"); sys.exit(0)
subprocess.run(["pbcopy"], input=hits[0]["text"].encode())
print(f"Kopiert ({len(hits)} Treffer): " + hits[0]["text"].replace("\n", " ")[:50])
PY
