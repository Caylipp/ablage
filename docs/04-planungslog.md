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

(wird während der Umsetzung ergänzt, siehe unten)
