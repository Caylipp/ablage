Stand: 2026-11-28

# Ablage – Stand

Zwischenablage-Verlauf fürs iPhone nach Vorbild „Paste“. v2/v3 nativ (SwiftUI, Tastatur-Erweiterung, Widgets, XcodeGen in `native/`), v1 Expo/React Native liegt als Archiv im Repo-Root. Repo: github.com/Caylipp/ablage (letzter Commit 2026-11-22, README 2026-10-29 auf Englisch mit MIT-Lizenz).

## Was funktioniert
- v3 (Commit 2026-10-12) mit 13 Funktionen (Tastatur-Suche, Aktionen, Bausteine, OCR, Widgets, Mac-Sync, Backup u. a.). Laut `docs/v3/02-retrospektive.md`: 14 Unit-Tests grün, IPA 1,0 MB mit App, Tastatur und Widgets (Stand 2026-10-12).
- IPA-Bau per `sh scripts/build-native-ipa.sh` (ad-hoc signiert); Installation per SideStore (Gedächtnis `ablage-projekt`).
- Tests in dieser Sitzung nicht neu gelaufen: `npm run check` scheitert hier, weil `node_modules` fehlt (ungeprüft, ob v1 noch grün ist).

## Nächste Schritte
1. Auf dem iPhone testen (App Group nach SideStore-Signatur ist laut Gedächtnis das Hauptrisiko).
2. Offene Risiken aus der Retrospektive prüfen: Widget ohne App Group (Ersatzweg über private Zwischenablage), Fotozugriff der Tastatur.
3. Nutzerfeedback in `docs/v3/02-retrospektive.md` eintragen (dort „Ausstehend“).

## Offene Fragen an Philipp
- Ist die App inzwischen am iPhone getestet, und wie war das Ergebnis?
- Soll die veraltete Leitstand-Beschreibung („Expo“, Start über Expo Go) auf die native App umgestellt werden? (ungeprüft, ob der Leitstand-Task noch sinnvoll ist)
