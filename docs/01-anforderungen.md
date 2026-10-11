# 01 – Anforderungen (Requirements Engineering)

Stand: 2026-10-10

## Ausgangslage

Der Nutzer nutzt auf dem Mac den Zwischenablage-Verlauf von Raycast. Auf dem iPhone fehlt so etwas.
Die bekannte iOS-App „Paste“ kann das, kostet aber ein Abo. Ziel: ein eigener, kostenloser Nachbau
für den Eigengebrauch, so nah am Vorbild wie iOS es zulässt.

## Referenz: Was das Vorbild auf iOS kann

| Funktion des Vorbilds | Beschreibung |
|---|---|
| Verlauf | Horizontale/vertikale Karten aller kopierten Inhalte, neueste zuerst |
| Inhaltstypen | Text, Links (mit Domain), Bilder, Farben (Hex), Code, Dateien |
| Pinnwände | Eigene Sammlungen („Pinboards“) mit Name und Farbe, Einträge dauerhaft ablegen |
| Suche & Filter | Volltextsuche, Filter nach Typ |
| Zurückkopieren | Tippen auf Karte = wieder in die Zwischenablage |
| Erfassen | Beim Öffnen der App; Share-Extension; eigene Tastatur; Kurzbefehle |
| Bearbeiten | Text eines Eintrags ändern, umbenennen |
| Sync | iCloud-Sync mit dem Mac |
| Abo | Kostenpflichtig |

## Harte Grenzen von iOS (wichtig für die Erwartung)

1. **Keine App darf die Zwischenablage im Hintergrund lesen.** Auch das Vorbild kann das nicht.
   Es liest erst, wenn man die App öffnet, oder über Extension/Kurzbefehl.
2. Beim Lesen fragt iOS „Einfügen erlauben?“. Einmalig abschaltbar unter
   *Einstellungen → Ablage → Aus anderen Apps einsetzen → Erlauben*.
3. Share-Extension und Tastatur-Erweiterung sind eigene native Ziele. Ohne bezahlten
   Developer-Account (nicht vorhanden) und unter LiveContainer funktionieren Erweiterungen nicht.
4. iCloud-Sync braucht ebenfalls einen bezahlten Account.

## Funktionale Anforderungen

Priorität: **M** = Muss (MVP), **S** = Soll, **K** = Kann (später)

| ID | Anforderung | Prio |
|---|---|---|
| F1 | Beim Öffnen/Zurückkehren in die App wird die Zwischenablage gelesen und als neuer Eintrag gespeichert (abschaltbar) | M |
| F2 | Doppelte Einträge werden nicht neu angelegt, sondern nach oben geholt | M |
| F3 | Typen automatisch erkennen: Text, Link, Bild, Farbe, E-Mail, Telefonnummer, Code | M |
| F4 | Verlauf als Karten mit Vorschau, Typ, Quelle/Zeit | M |
| F5 | Tippen auf Karte kopiert Inhalt zurück (mit Haptik und Bestätigung) | M |
| F6 | Löschen per Wischen/Menü, Verlauf leeren | M |
| F7 | Volltextsuche | M |
| F8 | Filter nach Typ | M |
| F9 | Pinnwände anlegen, umbenennen, Farbe, löschen; Einträge hinzufügen/entfernen | M |
| F10 | Einträge in Pinnwänden bleiben beim Verlauf-Leeren und beim Limit erhalten | M |
| F11 | Detailansicht: ganzer Inhalt, Text bearbeiten, Teilen, Link öffnen | M |
| F12 | Manuelles „Aus Zwischenablage einfügen“ und „Neue Notiz“ | M |
| F13 | Erfassen über iOS-Kurzbefehle per URL-Schema `ablage://add?text=…` (Ersatz für Share-Extension, funktioniert mit Back-Tap) | S |
| F14 | Einstellungen: Auto-Erfassen an/aus, Verlaufslimit, Verlauf leeren | M |
| F15 | Bilder werden als Datei gespeichert, Vorschau im Verlauf | M |
| F16 | Share-Extension / Tastatur-Erweiterung | K (blockiert durch Account) |
| F17 | iCloud-Sync | K (blockiert durch Account) |

## Nicht-funktionale Anforderungen

- **Datenschutz:** Alles bleibt lokal auf dem Gerät. Kein Netzwerk, keine Analytics.
- **Kostenlos:** keine Abhängigkeit von bezahlten Diensten.
- **Design:** eigenständig, ohne Markennamen und ohne Emoji als Bedien-Icons, schlichte Linien-Icons (Feather), Hell/Dunkel.
- **Sprache:** Oberfläche Deutsch.
- **Plattform:** Expo SDK 57 / React Native, läuft in Expo Go (keine eigenen nativen Module) und als unsignierte IPA für LiveContainer.
- **Leistung:** Verlauf bis 1000 Einträge flüssig (FlatList).
- **Qualität:** Logik (Typerkennung, Verlaufsverwaltung) mit Unit-Tests; `typecheck`, `lint`, `test` grün.

## Abnahmekriterien (MVP)

1. Text kopieren in Safari → Ablage öffnen → Eintrag erscheint oben, Typ korrekt.
2. Dasselbe nochmals kopieren → kein Duplikat.
3. Bild kopieren → Bildkarte erscheint.
4. Karte antippen → Inhalt liegt in der Zwischenablage.
5. Pinnwand anlegen, Eintrag hinzufügen, Verlauf leeren → Eintrag bleibt in der Pinnwand.
6. Suche „http“ findet Links; Filter „Farben“ zeigt nur Farben.
7. App neu starten → alles noch da.
8. Kurzbefehl öffnet `ablage://add?text=Hallo` → Eintrag „Hallo“ erscheint.
