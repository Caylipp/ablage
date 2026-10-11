# 04 – Planungslog

Chronologisches Log der Planungs- und Umsetzungsentscheidungen.

| # | Datum | Entscheidung | Begründung |
|---|---|---|---|
| P1 | 2026-10-10 | Expo SDK 57 / RN wie morse-trainer | Bewährt auf diesem Mac, Expo Go zum Testen, IPA-Skript vorhanden |
| P2 | 2026-10-10 | Nur Expo-Go-Module (expo-clipboard, -file-system, -haptics, AsyncStorage) | Nutzer testet in Expo Go; native Module würden dort brechen |
| P3 | 2026-10-10 | Kurzbefehl + URL-Schema statt Share-Extension | Extensions brauchen bezahlten Account, laufen nicht in LiveContainer |
| P4 | 2026-10-10 | Ein JSON in AsyncStorage statt SQLite | ≤ 1000 Einträge, Bilder liegen als Dateien → JSON bleibt klein; einfacher |
| P5 | 2026-10-10 | Reiner Reducer in `lib/history.ts` | Komplett testbar ohne React/Native |
| P6 | 2026-10-10 | Pinnwand-Einträge zählen nicht zum Limit | Entspricht Vorbild: Pinnwände sind dauerhaft |
| P7 | 2026-10-10 | Liste vertikal statt horizontalem Karussell | Hochkant am iPhone besser lesbar; Karten-Optik bleibt |

## Aufgabenplan

| T | Aufgabe | Abnahme |
|---|---|---|
| T1 | Projektgerüst, Abhängigkeiten, app.json (Scheme `ablage`, SceneSupport) | `typecheck` läuft |
| T2 | `detect.ts`, `hash.ts`, `format.ts` + Tests | Tests grün |
| T3 | `history.ts` Reducer + Tests (Dedupe, Limit, Pinnwände, Suche) | Tests grün |
| T4 | Store mit Persistenz | Neustart behält Daten |
| T5 | Capture (Text + Bild, Auto beim Öffnen, Selbst-Kopie-Schutz) | Abnahme 1–4 |
| T6 | Verlauf-Bildschirm mit Suche/Filter/Karten | Abnahme 6 |
| T7 | Detail, Pinnwände, Einstellungen | Abnahme 5 |
| T8 | Deep-Link `add` | Abnahme 8 |
| T9 | IPA-Skript, README, Web-Export als Rauchtest | Build läuft |

## Umsetzungslog

| U | Datum | Ereignis |
|---|---|---|
| U1 | 2026-10-10 | T1–T3 fertig; 33 Unit-Tests auf Anhieb grün |
| U2 | 2026-10-10 | Lint-Fehler `react-hooks/refs`: `stateRef.current = state` während Render → in `useEffect` verschoben |
| U3 | 2026-10-10 | T4–T8 fertig; `npm run check` grün; Web-Export baut |
| U4 | 2026-10-10 | Release-Build im iOS-27-Simulator startet dank `enableSceneSupport`; Oberfläche korrekt |
| U5 | 2026-10-10 | `simctl pbcopy` hängt auf diesem Xcode 27 (Timeout) → Zwischenablage im Simulator nicht automatisiert testbar |
| U6 | 2026-10-10 | `simctl openurl` zeigt Systemdialog „In Ablage öffnen?“; ohne Simulator-GUI nicht antippbar → Deep-Link im Web getestet |
| U7 | 2026-10-11 | Web-Test in Chrome: Deep-Link, Typerkennung, Dedupe, Filter, Pinnwand, Verlauf leeren, Persistenz ✔ |
| U8 | 2026-10-11 | Eigenes App-Icon (gestapelte Karten) statt Platzhalter aus morse-trainer |
| U9 | 2026-10-11 | IPA gebaut (`dist/Ablage.ipa`) |

