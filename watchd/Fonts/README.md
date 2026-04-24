# Fonts

Lege hier die OFL-Font-Dateien ab. `FontRegistry.registerAll()` registriert
sie beim App-Launch programmatisch (kein Info.plist-Eintrag nötig — das
Target nutzt `GENERATE_INFOPLIST_FILE = YES`). Fehlen Dateien, fällt das
Theme auf Systemfonts zurück — **kein Crash**.

Xcode 16 `PBXFileSystemSynchronizedRootGroup` nimmt neue Dateien in diesem
Ordner automatisch ins Bundle auf — keinen Drag-to-Project-Schritt nötig.

## Velvet Hour (einziges Theme)

Benötigt für `Theme.velvetHour`:

| Dateiname                      | Format | Quelle                                                  | Lizenz |
| ------------------------------ | ------ | ------------------------------------------------------- | ------ |
| `BluuNext-Bold.otf`            | OTF    | <https://velvetyne.fr/fonts/bluu-next/>                 | OFL    |
| `BluuNext-BoldItalic.otf`      | OTF    | wie oben                                                | OFL    |
| `Manrope-Regular.ttf`          | TTF    | <https://fonts.google.com/specimen/Manrope>             | OFL    |
| `Manrope-Medium.ttf`           | TTF    | wie oben                                                | OFL    |
| `Manrope-SemiBold.ttf`         | TTF    | wie oben                                                | OFL    |
| `Manrope-Bold.ttf`             | TTF    | wie oben                                                | OFL    |

Dateinamen ohne Extension müssen dem **PostScript-Namen** entsprechen — sonst
greift `Font.custom(name:)` nicht. Nach dem Runterladen mit Font-Book
(macOS) oder `fc-query` verifizieren:

```sh
mdls -name kMDItemFSName -name kMDItemFonts BluuNext-Bold.otf
```

Bei Google-Fonts-Downloads (Manrope) enthält das ZIP eine statische Variante
und eine VariableFont-Variante — wir nutzen die statischen `.ttf`-Dateien
pro Weight.

## Verifikation

Nach Bundle-Einbindung im Xcode-Console-Log prüfen:

```
FontRegistry: 6 von 6 Fonts registriert.
```

Fehlt eine Datei, erscheint eine `notice`-Zeile — z. B.:

```
Font-File fehlt im Bundle: BluuNext-Bold.otf — Fallback auf Systemfont.
```

## Historie

Die ursprünglich geplanten Themes **Kino Noir** (Redaction + Geist) und
**Marquee Paper** (EB Garamond + Work Sans + Fragment Mono) wurden mit der
Theme-Vereinfachung am 2026-04-24 entfernt. Deren Font-Dateien sind nicht
mehr Teil des Bundles. Begründung steht in `.impeccable.md` → *Aesthetic
Direction → Warum nur ein Theme*.
