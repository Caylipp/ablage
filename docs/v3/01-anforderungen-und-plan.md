# v3 – Anforderungen und Plan (13 Features)

Stand: 2026-10-12. Auftrag des Nutzers: „alles umsetzen“ (Ideenliste aus der v2.2-Übergabe).

| # | Feature | Umsetzung | Ort |
|---|---|---|---|
| 1 | Zuletzt-Bereich in der Tastatur | Die 3 neuesten Karten im Tab Verlauf breiter und markiert | Tastatur |
| 2 | Suche in der Tastatur | Lupe → eigenes Mini-QWERTZ, Treffer live darüber | Tastatur |
| 3 | Einfügen + anpinnen | Langes Drücken öffnet Aktionsleiste, erste Aktion „Einfügen & anpinnen“ | Tastatur |
| 4 | Links ohne Tracking | `utm_*`, `fbclid`, `gclid`, `si` … beim Sichern entfernen (abschaltbar) | Shared |
| 5 | Sensible Einträge löschen | Codes (4–8 Ziffern), passwortartige Zeichenketten, „concealed“-Typen von Passwortmanagern → nach 10 Min. weg (abschaltbar) | Shared |
| 6 | Text in Bildern (OCR) | Vision, lokal, de+en; Ergebnis durchsuchbar und in Details kopierbar | App |
| 7 | Bausteine mit Platzhaltern | `{Datum} {Uhrzeit} {Wochentag} {Zwischenablage} {Cursor}` (+ englische Namen) beim Einsetzen/Kopieren | Shared |
| 8 | Text umwandeln | GROSS, klein, Titel, Leerzeilen weg, Zeilen verbinden, Aufzählung, Nummerierung – in der Aktionsleiste | Tastatur |
| 9 | Widgets + Steuerzentrale | Widget „Zuletzt“ (klein/mittel/groß/Sperrbildschirm), Antippen kopiert über die App; Steuerzentrale-Knopf „Ablage“ | neue Widget-Erweiterung |
| 10 | Sync mit dem Mac | Ordner in iCloud Drive wählen → `verlauf.json` + `an-iphone.txt`; Raycast-Skripte unter `mac/raycast/` | App + Mac |
| 11 | Backup | Export/Import als JSON inkl. Bilder (Zusammenführen ohne Dubletten) | App |
| 12 | Linkvorschau | LinkPresentation lädt Titel + Bild (abschaltbar) | App |
| 13 | Dunkle Tastatur | Tastatur folgt dem Erscheinungsbild des Textfelds, eigene Tastenfarben | Tastatur |

## Grenzen

- Widgets laufen in eigenem Prozess. Ohne App Group lesen sie über den Ersatzweg (private Zwischenablage) – ob iOS das
  im Widget erlaubt, zeigt erst das Gerät.
- Ein Widget kann nicht selbst kopieren → Antippen öffnet kurz die App, die kopiert.
- Kurzbefehle lassen sich in iOS 18+ ohnehin direkt in die Steuerzentrale legen (eigener Kurzbefehl „Ablage sichern“).
- Mac-Sync nur, wenn die App läuft oder die Kurzbefehl-Aktion ausgeführt wird (kein Hintergrunddienst auf iOS).

## Reihenfolge

Shared-Logik + Tests (4, 5, 7, 8) → Tastatur (1, 2, 3, 8, 13) → App (6, 10, 11, 12) → Widget (9) → Build, Tests, Screenshots, IPA.
