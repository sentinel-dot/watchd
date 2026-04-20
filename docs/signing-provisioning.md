# iOS Signing und Provisioning

Diese Notiz haelt die Watchd-spezifischen Xcode- und Apple-Developer-Einstellungen fest, damit Mac-Wechsel, Team-Wechsel oder Bundle-ID-Aenderungen nicht in Trial-and-Error enden.

## Aktueller Projektstand

- Xcode-Projekt: `watchd/watchd.xcodeproj`
- Target: `watchd`
- Development Team: `RNK5A8AP8B`
- Bundle Identifier: `com.milinkovic.watchd`
- Code Signing Style: `Automatic`
- Entitlements-Datei: `watchd/watchd/watchd.entitlements`

Im Projektfile ist das aktuell fuer Debug und Release hinterlegt:

- `DEVELOPMENT_TEAM = RNK5A8AP8B`
- `PRODUCT_BUNDLE_IDENTIFIER = com.milinkovic.watchd`
- `CODE_SIGN_ENTITLEMENTS = watchd/watchd.entitlements`

## Capabilities, die im Blick bleiben muessen

Die Entitlements-Datei enthaelt derzeit:

- `aps-environment`
- `com.apple.developer.associated-domains`

Praktisch bedeutet das:

- Push Notifications muessen im Target aktiv bleiben
- Associated Domains muessen fuer `applinks:watchd.up.railway.app` erhalten bleiben

Wenn nach einem Team- oder Bundle-ID-Wechsel Capabilities neu gesetzt werden, diese beiden Eintraege anschliessend immer gegen `watchd/watchd/watchd.entitlements` verifizieren.

## Standard-Setup auf einem neuen Mac

1. Mit derselben Apple-ID in Xcode anmelden:
   - `Xcode` -> `Settings` -> `Accounts`
2. Projekt `watchd/watchd.xcodeproj` oeffnen
3. Target `watchd` -> `Signing & Capabilities`
4. `Automatically manage signing` aktiviert lassen
5. Als Team `RNK5A8AP8B` auswaehlen
6. Bundle Identifier `com.milinkovic.watchd` verifizieren
7. Ein echtes Geraet auswaehlen und einmal bauen

Ziel:
- Xcode soll das passende Development Provisioning Profile selbst neu erzeugen oder aktualisieren.

## Provisioning Profile erneuern

Wenn Xcode ueber fehlende oder abgelaufene Provisioning Profiles stolpert:

1. In Xcode `Signing & Capabilities` oeffnen
2. `Automatically manage signing` aktiv lassen
3. Team und Bundle ID bestaetigen
4. Build fuer ein echtes Geraet erneut starten
5. Falls noetig in den Apple-Developer-Bereich `Profiles` wechseln und alte/kaputte Profile entfernen

Faustregel:
- Fuer dieses Projekt nicht manuell mit fest verdrahteten Profiles arbeiten, solange kein sehr spezieller Release-Prozess das verlangt.
- Das Projekt ist auf automatisches Signing ausgelegt.

## Was bei Bundle-ID-Aenderungen mitzuziehen ist

Eine neue Bundle ID ist kein isolierter Xcode-Change. Danach muessen mindestens diese Punkte geprueft werden:

1. `PRODUCT_BUNDLE_IDENTIFIER` im Xcode-Projekt
2. App ID im Apple Developer Portal
3. Push Notifications Capability fuer die neue App ID
4. Associated Domains / Universal Links
5. Provisioning Profile fuer die neue App ID
6. Installation auf echtem Testgeraet

Wichtig:
- Wenn die Bundle ID geaendert wird, koennen bestehende APNs-/Entitlement-Annahmen brechen.
- Danach immer auch die APNs-Doku in `docs/apns-end-to-end-setup.md` erneut durchgehen.

## Typische Fehlerbilder

### "No profiles found" / Signing failed

Meistens:
- falsches Team gewaehlt
- Apple-Account in Xcode nicht mehr eingeloggt
- Bundle ID existiert fuer das Team nicht

### App baut, aber Push kommt nicht an

Meistens kein reines Signing-Problem, sondern einer dieser Punkte:

- Push Capability nach Team-/Profile-Wechsel verloren
- `aps-environment` fehlt oder passt nicht
- Backend nutzt falsches `APNS_PRODUCTION`

### Universal Links oder Deep Links verhalten sich ploetzlich anders

Pruefen:
- `com.apple.developer.associated-domains` noch vorhanden?
- Domain noch `applinks:watchd.up.railway.app`?

## Release-/TestFlight-Hinweise

Vor TestFlight oder spaeterem App-Store-Release:

1. Release-Build einmal lokal archivieren
2. Team und Bundle ID im Archive gegenpruefen
3. Push-Setup mit `APNS_PRODUCTION=true` gegen einen echten Distribution-Build testen

Der aktuelle Repo-Stand mit `aps-environment = development` ist fuer lokale Entwicklung erwartbar. Vor echtem Distribution-Testing immer den gesamten Push-Pfad gegen den vorgesehenen Build-Kanal pruefen.

## Schnelle Verifikation nach Xcode- oder Mac-Wechsel

1. Projekt oeffnet ohne Signing-Warnungen
2. Team steht auf `RNK5A8AP8B`
3. Bundle ID ist `com.milinkovic.watchd`
4. `watchd/watchd/watchd.entitlements` enthaelt weiter `aps-environment` und `associated-domains`
5. Debug-Build laeuft auf echtem Geraet
6. Match-Push laesst sich mit der APNs-E2E-Doku verifizieren
