# Ablage

> **Version 2 (aktuell): native iOS-App mit eigener Tastatur** in [`native/`](native/).
> Version 1 (Expo, ohne Tastatur) liegt weiter im Wurzelordner als Archiv.

## v2: Tastatur-first

Kopieren → in irgendein Textfeld tippen → Globus halten → **Ablage**. Die Tastatur sichert die aktuelle
Zwischenablage automatisch und zeigt Tab **Verlauf** und Tab **Angepinnt** (Notizen + Pinnwände).
Antippen fügt Text direkt ein; Bilder/Dateien landen in der Zwischenablage zum Einsetzen.

**Installieren** (LiveContainer geht nicht – iOS lädt Tastaturen nur aus direkt installierten Apps):
1. `sh scripts/build-native-ipa.sh` → `dist/Ablage-native.ipa`
2. Mit **SideStore/AltStore** installieren (übernimmt die App Group für den gemeinsamen Speicher; alle 7 Tage erneuern).
3. Einstellungen → Allgemein → Tastatur → Tastaturen → Tastatur hinzufügen → **Ablage** → **Vollen Zugriff erlauben**.
4. App öffnen → Tab „Einrichtung“ zeigt, ob alles grün ist.

Entwicklung: `cd native && xcodegen generate && open Ablage.xcodeproj`. Tests: Schema „Ablage“ → Test.
Debug-Startargumente: `-SeedDemo` (Beispieldaten), `-KeyboardDemo` (Tastatur-Oberfläche in der App).

---

## v1 (Expo, Archiv)

Kostenloser Zwischenablage-Verlauf für das iPhone, nachgebaut nach dem Vorbild der Abo-App „Paste“.
Alles bleibt lokal auf dem Gerät.

## Funktionen

- **Verlauf**: Text, Links, Bilder, Farben, Code, E-Mail-Adressen und Telefonnummern als Karten, neueste oben
- **Automatisch erfassen** beim Öffnen der App, ohne Dubletten (Gleiches wandert nur nach oben)
- **Antippen = kopieren**, lange drücken oder „…“ = Details (bearbeiten, Titel, teilen, öffnen, löschen)
- **Suche** und **Typfilter**
- **Pinnwände** mit Name und Farbe; ihre Einträge überleben „Verlauf leeren“ und das Limit
- **Neue Notiz** und **Einfügen per Knopf** oder durch Herunterziehen der Liste
- **Kurzbefehl/Back-Tap**: `ablage://add?text=…` speichert, ohne dass man die App erst bedient
- Hell/Dunkel nach System

## Grenzen von iOS

iOS lässt keine App die Zwischenablage im Hintergrund lesen, auch das Vorbild nicht. Ablage erfasst daher beim
Öffnen, per Knopf oder per Kurzbefehl. Share-Extension, eigene Tastatur und iCloud-Sync brauchen einen bezahlten
Apple-Developer-Account und fehlen deshalb. Siehe [docs/01-anforderungen.md](docs/01-anforderungen.md).

**Tipp:** Unter *Einstellungen → Apps → Ablage → Aus anderen Apps einsetzen → Erlauben* fragt iOS nicht mehr
bei jedem Öffnen nach.

## Entwicklung

```sh
npm install
npm start          # Expo Go (QR-Code scannen), läuft komplett in Expo Go
npm run check      # Typecheck + Lint + Tests
npm run ios:sim    # Release-Build im Simulator
npm run ios:ipa    # unsignierte IPA → dist/Ablage.ipa (für LiveContainer)
```

## Aufbau

- `src/lib/`: reine Logik (Typerkennung, Verlauf-Reducer, Hash), mit Tests
- `src/state/`: Store mit Persistenz (AsyncStorage) und Zugriff auf die Zwischenablage
- `src/app/`: Bildschirme (expo-router)
- `docs/`: Anforderungen, Handoffs, Konzept, Planungslog, Retrospektive
