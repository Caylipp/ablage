# 06 – Retrospektive

Stand: 2026-10-11

## Ergebnis gegen Abnahmekriterien

| # | Kriterium | Status | Wie geprüft |
|---|---|---|---|
| 1 | Kopierter Text erscheint beim Öffnen | ⚠️ offen | Code fertig; Simulator-Zwischenablage (`simctl pbcopy`) hängt → **am iPhone testen** |
| 2 | Keine Dublette | ✅ | Unit-Test + Web (zweimal `#3D7BFD` → ein Eintrag) |
| 3 | Bild kopieren → Bildkarte | ⚠️ offen | Code fertig, nur am Gerät testbar |
| 4 | Antippen kopiert zurück | ⚠️ offen | Code fertig, nur am Gerät sinnvoll prüfbar |
| 5 | Pinnwand überlebt „Verlauf leeren“ | ✅ | Unit-Test + Web-Klicktest |
| 6 | Suche / Typfilter | ✅ | Unit-Tests + Filterchips im Web sichtbar |
| 7 | Neustart behält Daten | ✅ | Web: Daten über fünf Seitenaufrufe erhalten |
| 8 | `ablage://add?text=…` | ✅ Web / ⚠️ iOS | Route im Web getestet; iOS-Dialog im Simulator nicht antippbar |

## Was gut lief

- Reine Logik zuerst (Reducer + Typerkennung) → 33 Tests grün, UI-Bugs blieben aus.
- Bewährter Stack aus morse-trainer (Expo 57, SceneSupport) → Build lief beim ersten Mal im iOS-27-Simulator.
- Expo-Go-tauglich: keine eigenen nativen Module.

## Was schlecht lief / Lernpunkte

- Clipboard-Funktionen lassen sich im Xcode-27-Simulator nicht automatisieren (`simctl pbcopy` Timeout,
  keine Simulator-GUI). Die Kernfunktion ist daher ungetestet, bis sie am echten Gerät läuft.
- Port 8765 war schon belegt (anderer lokaler Dienst) → vor lokalen Servern freien Port prüfen.
- Platzhalter-Icon aus morse-trainer wäre fast mitgeliefert worden.

## Abweichungen vom Vorbild (bewusst)

| Vorbild | Ablage | Grund |
|---|---|---|
| Share-Extension, Tastatur | Kurzbefehl + Back-Tap | kein Developer-Account, LiveContainer |
| iCloud-Sync | – | kein Developer-Account |
| Horizontales Karussell | vertikale Kartenliste | Hochformat besser lesbar |
| Abo | kostenlos | Ziel des Projekts |

## Nächste Schritte (Vorschläge)

1. Am iPhone testen (Kriterien 1, 3, 4, 8) und „Aus anderen Apps einsetzen → Erlauben“ setzen.
2. Wischen zum Löschen (react-native-gesture-handler ist in Expo Go enthalten).
3. Link-Vorschau (Seitentitel laden), optional, weil sie Netzwerk braucht.
4. Export/Import des Verlaufs als JSON (Backup ohne iCloud).

## Feedback des Nutzers

> _Noch ausstehend._ Bitte nach dem ersten Test am iPhone hier eintragen:
> Was fehlt im Vergleich zum Vorbild? Was stört? Funktioniert das Erfassen beim Öffnen zuverlässig?
