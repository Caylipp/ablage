# v2 – 01 Anforderungen: Tastatur-first

Stand: 2026-10-12. Auslöser: Nutzerfeedback zu v1 (siehe [../06-retrospektive.md](../06-retrospektive.md)).

## Ziel

Wie beim Vorbild: Man muss die App **nicht öffnen**. Kopieren → irgendwo tippen → zur Ablage-Tastatur wechseln →
Verlauf sehen → antippen → eingesetzt.

## Entscheidungen des Nutzers (2026-10-12)

1. Installation per **SideStore/AltStore oder Xcode per Kabel** (7-Tage-Signatur) ist okay. LiveContainer entfällt.
2. **Neubau nativ in Swift/SwiftUI** (App + Tastatur-Erweiterung), Expo-v1 bleibt als Archiv im Repo.

## Funktionale Anforderungen

| ID | Anforderung | Prio |
|---|---|---|
| K1 | Eigene Tastatur-Erweiterung „Ablage“ | M |
| K2 | Tastatur-Tab **Verlauf**: Karten aller Einträge (Text, Link, Bild, Farbe, Code …), neueste zuerst | M |
| K3 | Tastatur-Tab **Angepinnt**: Notizen und Pinnwand-Einträge, dauerhaft, nach Pinnwand filterbar | M |
| K4 | Antippen fügt Text direkt ins aktive Textfeld ein | M |
| K5 | Bild antippen → liegt in der Zwischenablage, Hinweis „Bild kopiert – Einsetzen“ | M |
| K6 | Beim Erscheinen der Tastatur wird die aktuelle Zwischenablage **unsichtbar gesichert** (nur bei neuem `changeCount`) | M |
| K7 | Tastatur hat Globus (Tastatur wechseln), Löschen, Leerzeichen, Zeilenumbruch | M |
| K8 | Suche in der Tastatur | S |
| K9 | App und Tastatur teilen dieselben Daten (App Group) | M |
| K10 | App: alle v1-Funktionen (Verlauf, Suche, Filter, Pinnwände, Notizen, Details, Einstellungen) | M |
| K11 | App: Einrichtungsanleitung (Tastatur hinzufügen, vollen Zugriff erlauben, Einsetzen erlauben) mit Status-Prüfung | M |
| K12 | App erfasst beim Öffnen weiterhin automatisch | M |
| K13 | Dateien aus der Zwischenablage (PDF u. a.) als Datei-Eintrag | K |

## Grenzen (nicht verhandelbar durch iOS 27, auch mit Nutzer-Erlaubnis)

- Hintergrund-Mitlesen jeder Kopie ist unmöglich, ohne Jailbreak. Ersatz: K6, erfasst beim nächsten Tastatur-Aufruf.
- Tastatur ohne **„Vollen Zugriff“** darf weder Zwischenablage noch App-Group lesen → Pflicht in der Anleitung.
- Tastaturen sind auf ca. 60 MB Speicher begrenzt → Bilder nur als kleine Vorschauen in der Tastatur.
- Eine Tastatur kann Bilder nicht direkt „tippen“, nur in die Zwischenablage legen.

## Abnahme

1. In Safari Text kopieren → in Notizen zur Ablage-Tastatur wechseln → Text ist oben im Verlauf → Antippen setzt ihn ein.
2. Bild kopieren → Tastatur zeigt Bild → Antippen → „Einsetzen“ fügt es ein.
3. Notiz in der App anlegen → erscheint im Tab „Angepinnt“ der Tastatur.
4. App öffnen → zeigt alles, was die Tastatur erfasst hat.
