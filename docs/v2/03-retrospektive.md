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

## Erster Gerätetest (2026-10-12) und v2.1

**Feedback:** Installiert per Sideload-Werkzeug. Tastatur funktioniert und zeigt Kopiertes. Aber:
1. „Voller Zugriff“ und „Gemeinsamer Speicher“ blieben orange, obwohl voller Zugriff an ist.
2. App „stürzt ab“, wenn man aus den Einstellungen zurückkommt.
3. Einsetzen-Dialog bei jedem Erfassen nervt; Wunsch: automatisch, ohne App, jeder Workaround ok.
4. Screenshots sollen auch im Verlauf landen.

**Ursache 1:** Das Werkzeug hat keine App Group eingerichtet → App und Tastatur hatten getrennte Speicher.
**Fix v2.1:**
- Ersatz-Synchronisierung über private benannte Zwischenablagen (`Mirror.swift`), gleiche Team-ID genügt.
  Im Simulator mit `-ForceMirror` geprüft: lokale Datei gelöscht → Daten kamen aus dem Spiegel zurück.
- Kurzbefehle-Aktion „In Ablage sichern“ (App Intent, läuft im Hintergrund, kein Dialog) für Back-Tap.
- Bildschirmfotos automatisch übernehmen (Fotomediathek, beim Öffnen von App/Tastatur).
- Deployment-Ziel iOS 18 (für die Intent-API).

**Zu 2:** Vermutlich beendet iOS die App selbst, wenn man Tastatur-Rechte ändert (normales Verhalten). Kein Absturzbericht
verfügbar (iPhone nicht am Mac). Falls es auch ohne Rechte-Änderung passiert: Bericht unter Einstellungen → Datenschutz →
Analyse & Verbesserungen → Analysedaten → „Ablage…“.

## Feedback 2 (2026-10-12) und v2.2

**Feedback:** Kurzbefehl + Back-Tap „klappt super“. Kleinigkeiten: Kurzbefehl-Bereich wirkt wie Nebensache → hervorheben;
Texte verbessern, mehrere Sprachen (auch Englisch); kaputte Anführungszeichen entfernen; Hinweis „Einsetzen aus anderen
Apps → Erlauben (nicht Fragen)“ fehlte; Testfeld mit Beispieltext in der Einrichtung.

**Umgesetzt (v2.2):**
- Einrichtung neu: hervorgehobene Karte „Empfohlen – Kopieren, zweimal hinten tippen“ mit 4 Schritten und Knopf „Kurzbefehle öffnen“ ganz oben.
- Eigener Abschnitt „Ohne Nachfrage“ mit **Erlauben, nicht Fragen** und Knopf zu den Ablage-Einstellungen.
- Abschnitt „Testen“: Beispieltext mit Kopieren-Knopf + Eingabefeld zum Ausprobieren der Tastatur.
- Alle Anführungszeichen durch Fettdruck ersetzt.
- Deutsch (Entwicklungssprache) + Englisch für App, Tastatur, Kurzbefehl-Aktion und Fotozugriff-Text (108 Texte),
  Schlüssel per `SWIFT_EMIT_LOC_STRINGS` aus dem Build gezogen; im Simulator in beiden Sprachen geprüft.
