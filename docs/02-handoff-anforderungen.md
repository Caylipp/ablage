# 02 – Handoff: Anforderungen → Planung

**Von:** Requirements Engineering  **An:** Planung/Architektur  **Datum:** 2026-10-10

## Kurzfassung

Kostenloser Zwischenablage-Verlauf für iOS im Stil der Abo-App „Paste“, nur für den Eigengebrauch.
Umfang: Funktionen F1–F15 aus [01-anforderungen.md](01-anforderungen.md), dazu F13 als Ersatz für die Share-Extension.

## Was die Planung wissen muss

- **Kernproblem ist das Erfassen**, nicht die Anzeige. iOS erlaubt nur: beim Öffnen lesen, manuell einfügen, Kurzbefehl per URL-Schema.
  Diese drei Wege müssen reibungslos sein.
- **Kein bezahlter Apple-Account**: keine Extensions, kein iCloud. Auslieferung als unsignierte IPA (LiveContainer) oder über Expo Go.
- **Bekannte Stolpersteine** aus anderen Projekten: Expo 57 + Xcode 27 braucht `enableSceneSupport`; IPA braucht den vtool-SDK-Patch auf 26 (siehe morse-trainer/clash-royale-trainer).
- **Nur Expo-Go-taugliche Module** verwenden (expo-clipboard, expo-file-system, expo-haptics, AsyncStorage).

## Offene Fragen an den Nutzer (nicht blockierend, Annahmen getroffen)

| Frage | Annahme |
|---|---|
| Name der App? | „Ablage“ |
| Verlaufslimit? | 500 Einträge, einstellbar |
| Sprache? | Deutsch |
| Sync mit dem Mac nötig? | Nein (geht ohne Account nicht) |

## Abnahme

Die 8 Abnahmekriterien in 01 gelten als Definition of Done.
