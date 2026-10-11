# 05 – Handoff: Planung → Umsetzung

**Von:** Planung  **An:** Umsetzung  **Datum:** 2026-10-10

- Grundlage: [03-konzept.md](03-konzept.md) (Architektur, Datenmodell, Kernregeln) und Aufgabenplan T1–T9 in [04-planungslog.md](04-planungslog.md).
- Reihenfolge: zuerst reine Logik mit Tests (T2–T3), dann Store/Capture, dann Bildschirme.
- Leitplanken:
  - keine nativen Zusatzmodule (Expo Go muss laufen)
  - keine Emoji-Bedienicons, nur Feather
  - Oberflächentexte auf Deutsch
  - `app.json`: `expo-build-properties` mit `ios.enableSceneSupport: true`
  - `scripts/build-ipa.sh` mit vtool-Patch auf SDK 26
- Fertig heißt: `npm run check` grün, Web-Export baut, Abnahmekriterien im Simulator geprüft, soweit ohne iPhone möglich.
- Risiken: Die Signatur von `expo-clipboard.getImageAsync` und die neue `expo-file-system`-API müssen gegen die installierten Typen geprüft werden.
