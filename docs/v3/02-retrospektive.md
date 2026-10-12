# v3 – Umsetzungslog und Retrospektive

Stand: 2026-10-12

## Umgesetzt

| # | Feature | Geprüft |
|---|---|---|
| 1 | Zuletzt-Bereich (3 breite Karten mit Schild) | Screenshot Tastatur-Vorschau |
| 2 | Suche mit Mini-QWERTZ | Screenshot |
| 3 | Langes Drücken → „Einfügen & anpinnen“ | Screenshot Aktionsleiste |
| 4 | Tracking aus Links entfernen | Unit-Tests |
| 5 | Codes/Passwörter nach 10 Min. löschen (+ Passwortmanager-Typen, „transient“ wird gar nicht gesichert) | Unit-Tests |
| 6 | Texterkennung (Vision, de/en), durchsuchbar, in Details kopierbar | Build; am Gerät prüfen |
| 7 | Platzhalter `{Datum} {Uhrzeit} {Wochentag} {Zwischenablage} {Cursor}` + Leiste im Editor | Unit-Tests |
| 8 | Umwandlungen in der Aktionsleiste | Unit-Tests + Screenshot |
| 9 | Widget (klein/mittel/groß/Sperrbildschirm) + Steuerzentrale-Knopf | Build; am Gerät prüfen |
| 10 | Mac-Sync über iCloud-Drive-Ordner + 3 Raycast-Skripte | Skripte lokal getestet |
| 11 | Backup Export/Import | Build; am Gerät prüfen |
| 12 | Linkvorschau (LinkPresentation) | Build; am Gerät prüfen |
| 13 | Dunkle Tastatur | Screenshot |

Außerdem: Englisch für alle neuen Texte, 14 Unit-Tests grün, IPA 1,0 MB mit drei Teilen (App, Tastatur, Widgets).

## Lernpunkte

- Simulator-App-Group-Container überlebt Deinstallation → Demo-Daten waren alt; nicht verwechseln mit Fehlern.
- Schild-Overlays brauchen Platz: in der flachen Suchansicht ausblenden.
- Beim Testen der Raycast-Skripte wurde die Mac-Zwischenablage überschrieben – künftig vorher sichern.

## Offene Risiken am Gerät

- Widget ohne App Group: liest über den Ersatzweg (private Zwischenablage); ob iOS das Widgets erlaubt, ist ungeprüft.
- Fotozugriff in der Tastatur (Bildschirmfotos) ebenfalls ungeprüft.

## Feedback des Nutzers

_Ausstehend._
