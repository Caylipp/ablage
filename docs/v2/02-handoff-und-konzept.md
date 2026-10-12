# v2 – 02 Handoff, Konzept und Planung

**Von:** Requirements  **An:** Umsetzung  **Datum:** 2026-10-12

## Architektur

```
native/
  project.yml            XcodeGen → Ablage.xcodeproj
  Shared/                in App UND Tastatur kompiliert
    Models.swift         Clip, Pinboard, Library (Codable)
    Detect.swift         Typerkennung (Port von v1 detect.ts)
    SharedStore.swift    JSON + Bilder im App-Group-Container, sperrt per NSFileCoordinator
    Pasteboard.swift     Zwischenablage lesen/schreiben, changeCount-Merker
    Theme.swift          Typfarben, Icons (SF Symbols, Linien-Stil)
  App/                   SwiftUI-App: Verlauf, Pinnwände, Einstellungen/Einrichtung, Detail
  Keyboard/              UIInputViewController + SwiftUI-Oberfläche
scripts/build-native-ipa.sh   unsignierte IPA inkl. .appex für SideStore
```

## Datenfluss

```
 Kopieren (irgendwo)
     │
     ├── Tastatur erscheint ─► changeCount neu? ─► lesen ─► SharedStore.add ─┐
     └── App wird aktiv     ─► changeCount neu? ─► lesen ─► SharedStore.add ─┤
                                                                            ▼
                                       App-Group-Container/library.json + images/
```

Jede Änderung: neu laden → ändern → atomar schreiben, koordiniert über `NSFileCoordinator`. So überschreiben sich
App und Tastatur nicht gegenseitig.

## App-Group-ID beim Sideloading

SideStore/AltStore benennen App Groups beim Signieren um und schreiben die echten IDs in `Info.plist` → `ALTAppGroups`.
`SharedStore` liest zuerst diesen Schlüssel, dann den Standard `group.com.philipphoang.ablage`. Fallback, wenn gar keine
Gruppe erreichbar ist: Dokumentordner der App. Die Tastatur zeigt dann einen Hinweis.

## Datenmodell (Änderung zu v1)

`Clip` bekommt `isNote` (in der App angelegte Notiz) und `thumbPath` (kleines JPEG für die Tastatur, max. 300 px).
„Angepinnt“ = `isNote || !pinboardIds.isEmpty`. Diese Einträge zählen nicht zum Limit.

## Tastatur-Layout

```
┌───────────────────────────────────────────────┐
│ [Verlauf | Angepinnt]   [Suche]          [⌫]  │
│ ┌──────┐ ┌──────┐ ┌──────┐ ┌──────┐  → wischen│
│ │Karte │ │Karte │ │Bild  │ │Farbe │            │
│ └──────┘ └──────┘ └──────┘ └──────┘            │
│ [🌐]          [ Leerzeichen ]          [⏎]     │
└───────────────────────────────────────────────┘
```

Horizontale Karten wie beim Vorbild, Höhe ca. 270 pt.

## Aufgaben

| T | Aufgabe |
|---|---|
| T1 | project.yml, Info.plists, Entitlements (App Group, `RequestsOpenAccess`) |
| T2 | Shared: Models, Detect, Store, Pasteboard |
| T3 | Keyboard-Controller + SwiftUI-Oberfläche |
| T4 | App-Oberfläche (Port v1) + Einrichtungs-Seite |
| T5 | Logik-Tests (Detect, Store-Regeln) als XCTest |
| T6 | Simulator-Build + Screenshots, IPA-Skript |
| T7 | Doku, Retrospektive v2 |
