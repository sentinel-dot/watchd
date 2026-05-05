# Versioning & Releases

## Schema

```
MAJOR.MINOR.PATCH (z. B. 1.1.0)
```

- **MAJOR** — Breaking Change oder kompletter Relaunch (selten)
- **MINOR** — neues Feature, größere UI-Änderung, sichtbarer Fortschritt für Tester
- **PATCH** — Bugfix, Crash-Fix, stille Korrektur ohne neuen Scope

Beispiele:
- 1.0.0 → erster TestFlight-Build
- 1.1.0 → neues Feature (z. B. Share-Code-Flow)
- 1.1.1 → Bugfix auf Feature-Stand 1.1
- 1.2.0 → nächstes Feature
- 2.0.0 → wenn die App wirklich eine andere ist

Der Build-Number ist technisch und steigt bei jedem Upload, egal wie klein.

---

## Wo stellen

Beide Werte sitzen in Xcode unter Target → General:

| Feld | Xcode-Name | Beispiel |
|---|---|---|
| Version | MARKETING_VERSION | 1.1.0 |
| Build | CURRENT_PROJECT_VERSION | 7 |

Oder direkt in der `project.pbxproj` — aber Xcode-UI ist einfacher.

**Regel**: Build-Number bei jedem Upload hochzählen (Apple lehnt doppelte ab). Version nur hochzählen wenn es sich für Tester lohnt zu wissen.

---

## Release-Ablauf (jedes Update)

1. Änderungen fertig und lokal getestet
2. Version und/oder Build in Xcode hochzählen
3. Railway: `APNS_PRODUCTION=true` prüfen (muss für TestFlight immer `true` sein)
4. Xcode → Product → Archive
5. Organizer → Distribute App → App Store Connect → Upload
6. App Store Connect → TestFlight: ~10–30 min Processing abwarten
7. Build für Tester freischalten + What's New Text eintragen
8. Tester kriegen automatisch Push-Benachrichtigung von TestFlight

---

## "What's New" Text (What to Test)

TestFlight zeigt Testern pro Build einen optionalen Text. Kurz halten, Deutsch:

```
1.1.0 (Build 5)
– Profil: Code teilen via Share-Sheet (Link öffnet App direkt)
– Partner hinzufügen: Code tippt sich bei geteiltem Link automatisch ein
```

Kein Marketing-Blabla. Konkret was neu oder gefixt ist, damit Tester gezielt testen können.

---

## Internes vs. Externes TestFlight

| | Intern | Extern |
|---|---|---|
| Max. Tester | 25 | 10.000 |
| Review nötig | Nein, sofort | Ja, ~1 Tag (Beta App Review) |
| Voraussetzung | App Store Connect Rolle (Developer/Admin) | Nur E-Mail-Adresse |
| Wann nutzen | Freunde/Familie mit Apple-Account im Team | Größerer Beta-Kreis |

Für die ersten Releases: intern reicht. Extern erst wenn der Kreis größer wird.

---

## Checkliste vor jedem Upload

- [ ] Build-Number hochgezählt (nie wiederholen)
- [ ] Version hochgezählt falls sinnvoll (MINOR für Features, PATCH für Fixes)
- [ ] Railway `APNS_PRODUCTION=true`
- [ ] App einmal auf echtem Gerät laufen lassen
- [ ] Archive und Upload erfolgreich
- [ ] "What's New" Text in TestFlight eingetragen
