# v2 – 03 Umsetzungslog und Retrospektive

Stand: 2026-10-12

## Umsetzungslog

| # | Ereignis |
|---|---|
| 1 | XcodeGen per Homebrew installiert; `native/project.yml` mit App, Tastatur-Erweiterung und Tests |
| 2 | Shared-Code (Modelle, Typerkennung, App-Group-Speicher mit NSFileCoordinator, Zwischenablage) – Build beim ersten Versuch grün |
| 3 | 8 XCTests grün (Typerkennung, Dedupe, Limit, Pinnwand, Notizen, Codable) |
| 4 | Tastatur im Simulator nicht ohne GUI aktivierbar → Debug-Vorschau `-KeyboardDemo` rendert die echte Tastatur-Oberfläche; Screenshot geprüft |
| 5 | Kosmetik: Zeitangabe im Kartenkopf brach um → `lineLimit(1)` |
| 6 | Debug-Build im Simulator braucht beim ersten Start ~15 s (SwiftUI-Debug, Schriftcache) – Release nicht betroffen |
| 7 | IPA ad-hoc signiert mit Entitlements, damit SideStore die App Group erkennt; 688 KB |

## Abnahme

| # | Kriterium | Status |
|---|---|---|
| 1 | Kopieren → Tastatur zeigt es → Antippen setzt ein | ⚠️ Code + Oberfläche fertig, **am iPhone testen** |
| 2 | Bild in Tastatur → Zwischenablage → Einsetzen | ⚠️ am iPhone testen |
| 3 | Notiz in App → Tab „Angepinnt“ der Tastatur | ✅ gleiche Daten/Filter (`keptOnly`), Unit-Test + Demo |
| 4 | App zeigt, was die Tastatur erfasst hat | ⚠️ am iPhone testen (App Group nur auf Gerät echt) |

## Risiken für den ersten Gerätetest

- **App Group nach SideStore-Signatur:** `SharedStore` liest `ALTAppGroups` aus der Info.plist. Wenn die Einrichtungsseite
  „Gemeinsamer Speicher“ orange zeigt, sehen App und Tastatur getrennte Daten.
- **Einsetzen-Dialog in der Tastatur:** iOS kann auch bei der Tastatur nachfragen. Falls ja: Einstellungen → Apps → Ablage → Aus anderen Apps einsetzen → Erlauben.
- **Xcode per Kabel mit kostenloser Apple-ID:** Xcode erlaubt persönlichen Teams keine App Groups → SideStore nehmen.

## Lernpunkte

- Kernwunsch (Tastatur) wurde in v1 still auf „Kann“ gesetzt. In v2 erst gefragt, dann gebaut.
- Native statt Expo war richtig: Erweiterung + gemeinsamer Speicher ohne Bastelei, IPA 13 MB → 0,7 MB.

## Feedback des Nutzers

_Ausstehend – nach dem ersten Test mit SideStore hier eintragen._
