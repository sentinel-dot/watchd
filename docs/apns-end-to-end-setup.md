# APNs End-to-End Setup

Diese Anleitung beschreibt die komplette Kette fuer Match-Pushes in Watchd: Apple Developer Portal -> Xcode -> Backend -> echter Geraetetest.

## Aktueller Projektstand

- Apple Developer Team ID: `RNK5A8AP8B`
- Bundle ID: `com.milinkovic.watchd`
- Entitlements-Datei: `watchd/watchd/watchd.entitlements`
- Aktueller `aps-environment`-Wert im Repo: `development`
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
5. Key anlegen und die `.p8`-Datei sofort herunterladen.

Wichtig:
- Die `.p8`-Datei kann spaeter nicht erneut heruntergeladen werden.
- Nach dem Anlegen die `Key ID` notieren.
- Die `Team ID` steht oben rechts im Developer Portal oder im Membership-Bereich. Fuer dieses Projekt ist sie aktuell `RNK5A8AP8B`.

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

Das ist der haeufigste Fehlerpfad.

- Xcode-Debug-Build auf echtem Geraet -> `APNS_PRODUCTION=false`
- TestFlight-Build -> `APNS_PRODUCTION=true`
- App-Store-Build -> `APNS_PRODUCTION=true`

Merksatz:
- Client-Build-Typ und Backend-Env muessen zusammenpassen.
- Bei `.p8`-Auth-Keys bleibt der Schluessel gleich; nur der APNs-Endpoint wechselt ueber `APNS_PRODUCTION`.
- Falsche Kombinationen schlagen typischerweise lautlos fehl: kein sichtbarer Client-Fehler, oft auch kein klarer Server-Fehler.

Der aktuelle Repo-Stand (`aps-environment = development`) passt zu lokalen Debug-Builds.

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

## 8. Rotation / Gerätewechsel Checkliste

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

Wenn "Match ja, Push nein":

1. `watchd/watchd/watchd.entitlements` auf `aps-environment` pruefen
2. `watchd/watchd/AppDelegate.swift` auf `didRegisterForRemoteNotificationsWithDeviceToken` pruefen
3. Backend-Env `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY`, `APNS_PRODUCTION` gegen Apple/Railway abgleichen
4. Testgeraet statt Simulator verwenden
5. Build-Kanal abgleichen: Debug vs TestFlight
