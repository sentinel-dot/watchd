# GitHub Actions — iOS Release CI/CD

Dieses Dokument beschreibt den vollständigen Aufbau der GitHub Actions Pipeline für iOS-Releases von Watchd. Die Pipeline archiviert, signiert und lädt die App automatisch in App Store Connect hoch.

---

## Hintergrund

Das Entwicklungs-MacBook Pro (15", 2019) läuft auf macOS Sequoia und unterstützt kein macOS 26 (Tahoe). Apple verlangt ab 2026 Xcode 26 (iOS 26 SDK) für alle App Store Uploads — die Pipeline löst dieses Problem durch einen GitHub Actions Runner, der Xcode 26 bereitstellt.

---

## Voraussetzungen

Bevor die Pipeline eingerichtet werden kann, müssen folgende Dinge existieren:

1. **Bundle ID** `com.milinkovic.watchd` im Apple Developer Portal registriert (Explicit, nicht Wildcard) mit Push Notifications + Sign In with Apple + Associated Domains
2. **App in App Store Connect** angelegt (Platform iOS, Name Watchd, Bundle ID wie oben)
3. **Apple Distribution Certificate** erstellt und im lokalen Keychain vorhanden
4. **App Store Provisioning Profile** erstellt
5. **App Store Connect API Key** mit Rolle App Manager

---

## Einmalige Einrichtung

### 1. App Store Connect API Key erstellen

appstoreconnect.apple.com → Users and Access → Integrations → App Store Connect API → Teamschlüssel → **+**

- Name: `GitHub Actions`
- Role: **App Manager**
- `.p8`-Datei herunterladen (nur einmal möglich)
- **Issuer ID** und **Key ID** notieren

### 2. Apple Distribution Certificate erstellen

Das Zertifikat muss Cert + Private Key zusammen enthalten — nur so lässt es sich als `.p12` exportieren.

**In Xcode:**
1. Xcode → Settings → Accounts → Apple Account → **Manage Certificates**
2. **+** → **Apple Distribution**
3. Xcode erstellt Certificate und Private Key und verknüpft sie automatisch

**In Schlüsselbundverwaltung:**
1. `Apple Distribution` suchen
2. Das **Zertifikat** auswählen (der Private Key erscheint als ausgeklapptes Kind-Element darunter — das ist das Zeichen, dass beide verknüpft sind)
3. Rechtsklick auf das Zertifikat → **Exportieren** → Format `.p12` → Passwort vergeben

> Wichtig: Wenn unter dem Zertifikat kein Private Key als Kind-Element erscheint, ist das Zertifikat nicht mit dem Key verknüpft — dann muss in Xcode ein neues erstellt werden.

**Als Base64 enkodieren:**
```bash
base64 -i ~/path/to/apple_distribution.p12 | pbcopy
```

### 3. App Store Provisioning Profile erstellen

developer.apple.com → Certificates, Identifiers & Profiles → Profiles → **+**

- Type: **App Store Connect** (unter Distribution)
- App ID: `com.milinkovic.watchd`
- Certificate: das neu erstellte Apple Distribution Certificate
- Name: `watchd AppStore`
- Downloaden (`.mobileprovision`)

**Als Base64 enkodieren:**
```bash
base64 -i ~/path/to/watchd_AppStore.mobileprovision | pbcopy
```

### 4. GitHub Secrets hinterlegen

GitHub Repo → Settings → Secrets and variables → Actions → **New repository secret**

| Secret Name | Inhalt |
|-------------|--------|
| `ASC_API_KEY_ID` | Key ID aus Schritt 1 |
| `ASC_API_ISSUER_ID` | Issuer ID aus Schritt 1 |
| `ASC_API_KEY_P8` | Vollständiger Inhalt der `.p8`-Datei (inkl. `-----BEGIN PRIVATE KEY-----`) |
| `DISTRIBUTION_CERT_P12` | Base64-enkodiertes `.p12` (aus Schritt 2) |
| `DISTRIBUTION_CERT_PASSWORD` | Passwort des `.p12`-Exports |
| `PROVISIONING_PROFILE` | Base64-enkodiertes `.mobileprovision` (aus Schritt 3) |

---

## Workflow-Datei

Liegt unter `.github/workflows/ios-release.yml`. Wird manuell über GitHub Actions → **Run workflow** ausgelöst.

```yaml
name: iOS Release

on:
  workflow_dispatch:

jobs:
  build-and-upload:
    runs-on: macos-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Select Xcode 26
        run: |
          sudo xcode-select -s /Applications/Xcode_26.0.app/Contents/Developer
          xcodebuild -version

      - name: Install Apple Distribution Certificate
        uses: apple-actions/import-codesign-certs@v3
        with:
          p12-file-base64: ${{ secrets.DISTRIBUTION_CERT_P12 }}
          p12-password: ${{ secrets.DISTRIBUTION_CERT_PASSWORD }}

      - name: Install Provisioning Profile
        env:
          PROFILE_BASE64: ${{ secrets.PROVISIONING_PROFILE }}
        run: |
          PROFILE_PATH=$RUNNER_TEMP/watchd.mobileprovision
          echo "$PROFILE_BASE64" | base64 --decode -o $PROFILE_PATH
          mkdir -p ~/Library/MobileDevice/Provisioning\ Profiles
          cp $PROFILE_PATH ~/Library/MobileDevice/Provisioning\ Profiles/

      - name: Set up App Store Connect API Key
        env:
          ASC_API_KEY_P8: ${{ secrets.ASC_API_KEY_P8 }}
          ASC_API_KEY_ID: ${{ secrets.ASC_API_KEY_ID }}
        run: |
          mkdir -p ~/.appstoreconnect/private_keys
          echo "$ASC_API_KEY_P8" > ~/.appstoreconnect/private_keys/AuthKey_$ASC_API_KEY_ID.p8

      - name: Archive
        env:
          ASC_API_KEY_ID: ${{ secrets.ASC_API_KEY_ID }}
          ASC_API_ISSUER_ID: ${{ secrets.ASC_API_ISSUER_ID }}
        run: |
          xcodebuild archive \
            -project watchd.xcodeproj \
            -scheme watchd \
            -configuration Release \
            -destination generic/platform=iOS \
            -archivePath $RUNNER_TEMP/watchd.xcarchive \
            -allowProvisioningUpdates \
            -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_$ASC_API_KEY_ID.p8 \
            -authenticationKeyID $ASC_API_KEY_ID \
            -authenticationKeyIssuerID $ASC_API_ISSUER_ID \
            DEVELOPMENT_TEAM=RNK5A8AP8B

      - name: Export IPA
        run: |
          cat > $RUNNER_TEMP/ExportOptions.plist << EOF
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
          <dict>
            <key>method</key>
            <string>app-store-connect</string>
            <key>signingStyle</key>
            <string>manual</string>
            <key>signingCertificate</key>
            <string>Apple Distribution</string>
            <key>provisioningProfiles</key>
            <dict>
              <key>com.milinkovic.watchd</key>
              <string>watchd AppStore</string>
            </dict>
          </dict>
          </plist>
          EOF
          xcodebuild -exportArchive \
            -archivePath $RUNNER_TEMP/watchd.xcarchive \
            -exportOptionsPlist $RUNNER_TEMP/ExportOptions.plist \
            -exportPath $RUNNER_TEMP/export

      - name: Upload to App Store Connect
        env:
          ASC_API_KEY_ID: ${{ secrets.ASC_API_KEY_ID }}
          ASC_API_ISSUER_ID: ${{ secrets.ASC_API_ISSUER_ID }}
        run: |
          xcrun altool --upload-app \
            -f $RUNNER_TEMP/export/watchd.ipa \
            --type ios \
            --apiKey $ASC_API_KEY_ID \
            --apiIssuer $ASC_API_ISSUER_ID
```

---

## Neuen Build hochladen

1. Code committen und pushen
2. GitHub → Actions → **iOS Release** → **Run workflow** → **Run workflow**
3. ~10–15 min warten
4. App Store Connect → TestFlight → Build erscheint mit Status „Abgeschlossen"

---

## Nach dem Upload: TestFlight freischalten

**Intern (sofort verfügbar):**
- App Store Connect → TestFlight → Interne Gruppe → Build zuweisen
- Tester brauchen eine App Store Connect Rolle (z. B. Developer)

**Extern (Beta App Review ~1 Tag):**
- App Store Connect → TestFlight → Externe Gruppen → Neue Gruppe → Build hinzufügen → E-Mail-Einladungen

---

## App Store Release

1. App Store Connect → deine App → **+** (neue Version) → Versionsnummer (z. B. `1.0`)
2. Screenshots hochladen (mind. 6,5" + 5,5" iPhone)
3. Beschreibung, Keywords, Support-URL ausfüllen
4. Build auswählen (den aus TestFlight)
5. **Add for Review** → Apple prüft ~1–3 Tage
6. Veröffentlichung: **Manually release** (du drückst selbst auf Release) oder **Automatically release** (sofort nach Genehmigung)

---

## Bekannte Fallstricke

| Problem | Ursache | Lösung |
|---------|---------|--------|
| `SecItemCopyMatching: item not found` | `.p12` enthält nur Zertifikat oder nur Key, nicht beide zusammen | In Xcode neu erstellen (Manage Certificates → + → Apple Distribution), dann erneut exportieren |
| SPM-Packages: `does not support provisioning profiles` | `PROVISIONING_PROFILE_SPECIFIER` wird global auf alle Targets angewendet | Archive-Schritt ohne `PROVISIONING_PROFILE_SPECIFIER` — Signing nur im Export-Schritt via ExportOptions.plist |
| `No Team Found in Archive` | `CODE_SIGNING_ALLOWED=NO` entfernt Team-Metadaten aus dem Archive | `-allowProvisioningUpdates` + API Key statt `CODE_SIGNING_ALLOWED=NO` |
| `Cloud signing permission error` | `destination=upload` in ExportOptions triggert Apple Cloud Signing | Lokal exportieren (kein `destination`-Key), dann separat via `altool` hochladen |
| iOS 18.x SDK rejected | `macos-latest` Runner hat Xcode 16.x | `xcode-select -s /Applications/Xcode_26.0.app` vor dem Build-Schritt |
| Passwort mit Sonderzeichen (z. B. `?`) in Shell | zsh interpretiert `?` als Glob | Passwort in Anführungszeichen: `"pass:MeinPasswort?"` |

---

## Zertifikat erneuern (jährlich)

Apple Distribution Certificates sind 1 Jahr gültig.

1. In Xcode → Manage Certificates → altes Apple Distribution Certificate löschen → neu erstellen
2. Neues `.p12` exportieren und base64-enkodieren
3. GitHub Secret `DISTRIBUTION_CERT_P12` und `DISTRIBUTION_CERT_PASSWORD` aktualisieren
4. Neues Provisioning Profile im Apple Developer Portal erstellen (altes referenziert das abgelaufene Cert)
5. GitHub Secret `PROVISIONING_PROFILE` aktualisieren
