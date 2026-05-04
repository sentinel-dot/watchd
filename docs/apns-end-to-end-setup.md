# APNs End-to-End Setup

Diese Anleitung beschreibt die komplette Kette fuer Match-Pushes in Watchd: Apple Developer Portal -> Xcode -> Backend -> echter Geraetetest.

## Aktueller Projektstand

- Apple Developer Team ID: `RNK5A8AP8B`
- Bundle ID: `com.milinkovic.watchd`
- Entitlements-Datei: `watchd/watchd/watchd.entitlements`
- Aktueller `aps-environment`-Wert im Repo: `production` (siehe Abschnitt 6)
- CI-Build: `.github/workflows/ios-release.yml` (Manual Signing via Distribution Cert + Provisioning Profile aus GitHub-Secrets, Upload via `altool`)
- iOS-Codepfad fuer Permission + Registrierung:
  - `watchd/watchd/ViewModels/AuthViewModel.swift`
  - `watchd/watchd/AppDelegate.swift`
- Backend-Codepfad fuer APNs:
  - `watchd_backend-mac/src/services/apns.ts`
  - `watchd_backend-mac/src/routes/users.ts`

## 1. APNs-Key im Apple Developer Portal erzeugen

1. [Apple Developer](https://developer.apple.com/account/) oeffnen.
2. `Certificates, Identifiers & Profiles` -> `Keys`.
3. `+` klicken und einen neuen Key anlegen, z. B. `watchd-apns`.
4. `Apple Push Notifications service (APNs)` aktivieren.
5. **Configure** klicken → bei `APNs Environment` zwingend **`Sandbox & Production`** wählen, **nicht** `Sandbox only`.
6. Key anlegen und die `.p8`-Datei sofort herunterladen.

Wichtig:
- Die `.p8`-Datei kann spaeter nicht erneut heruntergeladen werden.
- Nach dem Anlegen die `Key ID` notieren — sie sieht aus wie `55937BNHD9` (10 Zeichen, Teil des Dateinamens `AuthKey_55937BNHD9.p8`).
- Die `Team ID` steht oben rechts im Developer Portal oder im Membership-Bereich. Fuer dieses Projekt ist sie aktuell `RNK5A8AP8B`.

### Falle: Sandbox-Only-Key

Wenn der Key beim Anlegen versehentlich auf `Sandbox only` gesetzt wurde, schlägt jeder Push gegen den Production-Endpoint mit `BadEnvironmentKeyInToken` fehl — selbst wenn `APNS_PRODUCTION=true` korrekt gesetzt ist. Apple lässt nachträglich oft keine Änderung zu; in dem Fall: Key revoken und neu anlegen.

### Falle: Verwechslung mit Sign-in-with-Apple-Key

Watchd hat **zwei** `.p8`-Keys im Developer Portal:
- `Apple Push Notifications service (APNs)` — fuer Push (`APNS_KEY_ID`, `APNS_PRIVATE_KEY`)
- `Sign In with Apple` — fuer Auth-Code-Exchange (`APPLE_KEY_ID`, `APPLE_PRIVATE_KEY`)

Diese werden regelmäßig verwechselt. Der Key-ID-Hinweis in der Spalte `Services` der Developer-Portal-Tabelle ist die einzige Unterscheidung. Wenn der Sign-in-with-Apple-Key in `APNS_KEY_ID` landet, gibt Apple ebenfalls `BadEnvironmentKeyInToken` zurück (lautlos auf der Client-Seite).

## 2. `.p8` fuer Railway vorbereiten

Das Backend erwartet den privaten Schluessel in `APNS_PRIVATE_KEY` als einzeilige Base64-Zeichenkette.

Beispiel:

```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n'
```

Benötigte Backend-Variablen:

- `APNS_KEY_ID=<Key ID aus Apple Portal>`
- `APNS_TEAM_ID=RNK5A8AP8B`
- `APNS_PRIVATE_KEY=<base64 der .p8 Datei>`
- `APNS_PRODUCTION=false` fuer Debug-Deploys gegen Xcode-Geraete
- `APNS_PRODUCTION=true` fuer TestFlight / App Store

Wichtig:
- Die `.p8`-Auth-Key-Datei ist nicht getrennt in "Sandbox" und "Production".
- Entscheidend ist, dass das Backend ueber `APNS_PRODUCTION` den passenden APNs-Endpoint nutzt.

## 3. Railway konfigurieren

Im Railway-Projekt `watchd_backend-mac` die vier APNs-Variablen setzen oder rotieren:

1. Railway Dashboard -> Service -> `Variables`
2. `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY`, `APNS_PRODUCTION` eintragen
3. Speichern und den automatischen Redeploy abwarten
4. Bei Unsicherheit den Deploy einmal manuell `Redeploy`en

Empfehlung:
- Nach jeder Key-Rotation auch die lokale `.env` synchronisieren, damit Device-Tests gegen dieselbe Konfiguration laufen.

## 4. Xcode-Projekt pruefen

### Push Capability

Im Xcode-Target `watchd`:

1. `Signing & Capabilities` oeffnen
2. `+ Capability` -> `Push Notifications`
3. Pruefen, dass `watchd/watchd/watchd.entitlements` referenziert ist
4. Pruefen, dass dort ein `aps-environment`-Eintrag existiert

Ohne dieses Entitlement schlaegt `registerForRemoteNotifications()` lautlos fehl.

### Associated Domains

Die Entitlements-Datei enthaelt aktuell auch:

```xml
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:watchd.up.railway.app</string>
</array>
```

Das ist fuer Universal Links relevant und sollte bei Bundle-ID-/Target-Aenderungen nicht versehentlich entfernt werden.

## 5. Runtime-Flow im iOS-Client

Der aktuelle Ablauf im Code:

1. Login / Register / Guest-Login persistiert die Session in `AuthViewModel.persistSession(...)`
2. Danach ruft `requestPushPermissionIfNeeded()` die Notification-Settings ab
3. Bei bestehender Freigabe oder erfolgreichem Prompt erfolgt `UIApplication.shared.registerForRemoteNotifications()`
4. `AppDelegate.didRegisterForRemoteNotificationsWithDeviceToken` wandelt das Device-Token in Hex um
5. Das Token wird an `POST /api/users/me/device-token` gesendet

Konsequenz:
- Pushes lassen sich nur auf echten iPhones testen, nicht sinnvoll im Simulator.
- Wenn der User Notifications ablehnt, bleibt die App funktional, aber Match-Pushes kommen nicht an.

## 6. Sandbox vs Production richtig mappen

Das ist der haeufigste Fehlerpfad. Drei Stellen muessen zusammenpassen:

| Build-Typ | `aps-environment` (entitlements) | `APNS_PRODUCTION` | APNs-Endpoint |
| --- | --- | --- | --- |
| Xcode-Debug auf Geraet | `development` | `false` | `api.sandbox.push.apple.com` |
| TestFlight / App Store | `production` | `true` | `api.push.apple.com` |

Wichtig zu wissen:

- **Bei Manual Signing in CI gewinnt das Entitlements-File**, nicht das Provisioning-Profile. Was im Profile steht, ist nur die *erlaubte* Menge — der tatsächlich ins Binary geschriebene Wert kommt aus `watchd/watchd/watchd.entitlements`. Nach einer Änderung dort muss das Profile zwar zur neuen Entitlement passen (sonst bricht das Signing), aber das Profile selbst bestimmt nicht den Wert.
- **Bei Automatic Signing in Xcode** überschreibt das Distribution-Profile beim Re-Sign waehrend `Distribute App → App Store Connect` den `aps-environment`-Wert. Aber: Bei Manual Signing (wie in unserer GitHub-Action) passiert das nicht.
- Bei `.p8`-Auth-Keys bleibt der Schluessel gleich; nur der APNs-Endpoint wechselt ueber `APNS_PRODUCTION`. Voraussetzung: der Key ist nicht `Sandbox only`-scoped (siehe Abschnitt 1).
- Falsche Kombinationen schlagen typischerweise lautlos fehl: kein sichtbarer Client-Fehler, oft auch kein klarer Server-Fehler.

Der aktuelle Repo-Stand (`aps-environment = production`) passt zu TestFlight- und App-Store-Builds. Fuer lokales Push-Testing mit Xcode-Debug-Build muss die Datei temporaer auf `development` umgestellt werden — und im Backend `APNS_PRODUCTION=false`.

## 7. End-to-End-Test auf echtem Geraet

Minimaler Smoke-Test:

1. Backend mit korrekten APNs-Variablen deployen
2. App per Xcode auf ein echtes iPhone installieren
3. Notification Permission erlauben
4. Zwei User in denselben Room bringen
5. Auf beiden Geraeten denselben Film nach rechts swipen
6. Pruefen:
   - Match erscheint in der App
   - mindestens ein Push-Banner erscheint
   - Device-Token wurde im Backend fuer den User gespeichert

Wenn der Match in-app erscheint, aber kein Push ankommt, liegt das Problem fast immer in einer dieser Stellen:

- falscher `APNS_PRODUCTION`-Wert
- neues oder rotiertes `.p8` nicht auf Railway uebernommen
- Push Capability / Entitlement fehlt
- Test im Simulator statt auf echtem Geraet
- User hat Notifications fuer die App abgelehnt

## 8. CI-Verifikation der Entitlements

Die GitHub-Action enthält einen `Verify IPA Entitlements`-Step, der nach dem Export das tatsächliche Binary inspiziert:

```bash
unzip -q $RUNNER_TEMP/export/watchd.ipa -d $RUNNER_TEMP/inspect
codesign -d --entitlements - $RUNNER_TEMP/inspect/Payload/watchd.app
security cms -D -i $RUNNER_TEMP/inspect/Payload/watchd.app/embedded.mobileprovision \
  | plutil -extract Entitlements xml1 -o - -
```

Bei einem korrekten TestFlight-Build muss der Output zeigen:

- `aps-environment = production`
- `get-task-allow = false`
- `beta-reports-active = true`
- `application-identifier = RNK5A8AP8B.com.milinkovic.watchd`

Tritt `get-task-allow = true` auf, wurde mit Development-Cert signiert — Distribution-Cert fehlt im Build-Environment (lokaler Mac ohne `Apple Distribution`-Cert oder GitHub-Secret nicht gesetzt). Tritt `aps-environment = development` auf, ist die Entitlements-Datei oder das Provisioning-Profile noch im alten Stand.

## 9. Lokale Archives auf Mac vs CI

Lokale Archives auf einem Mac ohne installiertes `Apple Distribution`-Certificate fallen still auf das Development-Cert zurück. Symptome:

- Archive enthält `get-task-allow = true`
- `aps-environment` bleibt auf dem Wert des Development-Profiles (typischerweise `development`)

Lösung: Entweder das Distribution-Cert via `Xcode → Settings → Accounts → Manage Certificates → + Apple Distribution` installieren, oder den Build über die GitHub-Action machen. Letzteres ist in diesem Projekt der vorgesehene Weg — der Mac muss kein Distribution-Cert lokal halten.

## 10. Rotation / Gerätewechsel Checkliste

Bei neuem Mac, neuem iPhone oder APNs-Key-Rotation diese Reihenfolge nutzen:

1. Apple Developer Login pruefen
2. Team ID und Bundle ID bestaetigen
3. APNs-Key neu erzeugen oder vorhandenen verifizieren
4. `.p8` base64-encoden
5. Railway-Variablen aktualisieren
6. Xcode `Signing & Capabilities` pruefen
7. App auf echtem Geraet installieren
8. Match-Push E2E testen

## Schnellcheck bei Incidents

Wenn "Match ja, Push nein" und Backend-Log zeigt `BadEnvironmentKeyInToken`:

1. **APNs-Key in Apple Portal prüfen** — `Keys` → den `APNS_KEY_ID`-Eintrag öffnen → Spalte `Services` muss `APNs` zeigen (nicht `Sign In with Apple`); `APNs Environment` muss `Sandbox & Production` sein (nicht `Sandbox`).
2. **Diagnostik-Log am Backend nutzen** — `apns.ts` loggt beim Provider-Init `production`, `endpoint`, `rawEnv`. In Railway-Logs nach `APNs provider initialized` suchen und Werte vergleichen.
3. **Device-Tokens vergleichen** — wenn nach jedem Re-Install dieselben Hex-Strings rauskommen, hat sich `aps-environment` faktisch nicht geändert. Token-Wechsel = Build-Environment-Wechsel.
4. **CI-Build-Output prüfen** — `Verify IPA Entitlements`-Step im neuesten Workflow-Run zeigt was wirklich im Binary war (siehe Abschnitt 8).
5. **Provisioning-Profile im GitHub-Secret aktuell halten** — nach Entitlement-Änderung im Apple Portal das Profile via `Edit → Save` regenerieren, neu base64-encoden, Secret aktualisieren.
6. **Build-Kanal abgleichen** — Debug-Build vs TestFlight; `aps-environment` und `APNS_PRODUCTION` müssen zueinander passen (siehe Abschnitt 6).
7. **Test-Geräte vollständig clean machen** — App löschen, iPhone neu starten, frisch aus TestFlight installieren; iOS cached APNs-State aggressiv.
