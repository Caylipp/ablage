# Ablage ↔ Mac (Raycast)

1. In iCloud Drive einen Ordner **Ablage** anlegen (oder einen anderen und `ABLAGE_DIR` setzen).
2. In der iPhone-App: Einrichtung → Mac-Sync → diesen Ordner wählen.
3. Raycast → Settings → Extensions → Script Commands → **Add Directories** → diesen Ordner (`mac/raycast`).

| Skript | Wirkung |
|---|---|
| Ablage: Letzten iPhone-Eintrag kopieren | neuester iPhone-Eintrag → Mac-Zwischenablage |
| Ablage: iPhone-Verlauf durchsuchen | Suchbegriff → neuester Treffer → Mac-Zwischenablage |
| Ablage: Mac-Zwischenablage ans iPhone senden | landet beim nächsten Öffnen von Ablage (oder Kurzbefehl) im iPhone-Verlauf |

Abgeglichen wird auf dem iPhone beim Öffnen der App und bei jedem „In Ablage sichern“ (Back-Tap).
