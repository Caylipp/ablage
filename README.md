# Ablage

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
