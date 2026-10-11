# 03 – Konzept & Architektur

## Produktidee

„Ablage“ ist ein Zwischenablage-Verlauf für das iPhone. Man kopiert wie gewohnt und öffnet Ablage. Der Inhalt
ist dann schon gesichert. Antippen kopiert ihn zurück. Wichtiges kommt auf Pinnwände.

## Erfassungswege (wegen iOS-Grenzen)

```
 Kopieren in beliebiger App
        │
        ├─► Ablage öffnen ──► AppState "active" ──► Zwischenablage lesen ──► Eintrag (F1)
        ├─► Plus-Knopf „Aus Zwischenablage“ ──────────────────────────────► Eintrag (F12)
        └─► Kurzbefehl „Zwischenablage abrufen“ → URL ablage://add?text=… ─► Eintrag (F13)
                (per Back-Tap: 2× auf iPhone-Rückseite tippen)
```

Der Kurzbefehl ist der Ersatz für die Share-Extension, die ohne Developer-Account nicht geht.

## Architektur

```
src/
  app/                    expo-router (Bildschirme)
    _layout.tsx           Stack + Provider + Auto-Erfassen
    (tabs)/index.tsx      Verlauf (Suche, Typfilter, Karten)
    (tabs)/pinboards.tsx  Pinnwände
    (tabs)/settings.tsx   Einstellungen, Kurzbefehl-Anleitung
    clip/[id].tsx         Detail: Ansehen, Bearbeiten, Teilen, Pinnwand
    pinboard/[id].tsx     Inhalt einer Pinnwand
    add.tsx               Ziel des URL-Schemas ablage://add
  lib/                    reine Logik, voll getestet
    detect.ts             Typerkennung
    history.ts            Reducer: hinzufügen, dedupe, Limit, Pinnwände, Suche
    hash.ts               FNV-1a-Fingerabdruck
    format.ts             relative Zeit, Kurzvorschau
  state/store.tsx         Context + useReducer + AsyncStorage-Persistenz
  state/capture.ts        Zwischenablage lesen/schreiben, Bilder in Dateien
  components/             ClipCard, Icon, FilterBar, ui
  theme/                  Farben hell/dunkel
```

## Datenmodell

```ts
type ClipKind = 'text' | 'link' | 'image' | 'color' | 'email' | 'phone' | 'code';
interface Clip {
  id: string; kind: ClipKind;
  text?: string;          // Inhalt bei Text-Typen
  imageUri?: string;      // Datei im Dokumentordner bei Bildern
  hash: string;           // Fingerabdruck für Dubletten
  createdAt: number; usedAt: number;
  title?: string;         // optional umbenannt
  pinboardIds: string[];
}
interface Pinboard { id: string; name: string; color: string; createdAt: number }
interface State { clips: Clip[]; pinboards: Pinboard[]; settings: Settings }
```

Persistenz: ein JSON in AsyncStorage (`ablage.v1`), Bilder als PNG in `Dokumente/clips/`.

## Kernregeln

- **Dedupe:** Gleicher Hash → bestehender Eintrag wandert nach oben (`usedAt = jetzt`), kein neuer.
- **Limit:** Nur Einträge ohne Pinnwand zählen zum Limit. Die ältesten ungepinnten fallen raus.
- **Verlauf leeren:** löscht nur ungepinnte Einträge.
- **Zurückkopieren** setzt einen „Selbst-Kopie“-Hash, damit das Wiederöffnen keinen Eintrag erzeugt. Der vorhandene Eintrag wandert nur nach oben.
- **Typerkennung:** Reihenfolge Farbe → E-Mail → Link → Telefon → Code → Text.

## Gestaltung

Karten mit farbigem Typ-Streifen oben (wie beim Vorbild) und Feather-Linien-Icons, keine Emoji.
Hell/Dunkel folgt dem System. Farbkarten zeigen die Farbe als Fläche, Bildkarten das Bild.

## Bewusst nicht enthalten

Share-Extension, Tastatur, iCloud-Sync, OCR. Die ersten drei sind durch den fehlenden Account blockiert.
