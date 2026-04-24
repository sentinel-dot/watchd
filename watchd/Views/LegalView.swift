import SwiftUI

// MARK: - Editorial Legal Page (shared chrome)

private struct LegalPage<Content: View>: View {
    @Environment(\.theme) private var theme
    let ordinal: String
    let title: String
    let lede: String?
    @ViewBuilder var content: () -> Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                masthead
                    .padding(.bottom, lede != nil ? 28 : 44)

                if let lede {
                    ledeQuote(lede)
                        .padding(.bottom, 44)
                }

                VStack(alignment: .leading, spacing: 32) {
                    content()
                }

                Spacer(minLength: 80)
            }
            .padding(.horizontal, 28)
            .padding(.top, 24)
            .padding(.bottom, 48)
        }
        .background(theme.colors.base.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(theme.colors.base, for: .navigationBar)
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(ordinal)
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.8)
                .foregroundColor(theme.colors.accent)

            Text(title)
                .font(theme.fonts.display(size: 32, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func ledeQuote(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Rectangle()
                .fill(theme.colors.accent)
                .frame(width: 2)
                .frame(minHeight: 42)
            Text(text)
                .font(theme.fonts.body(size: 16, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct LegalSection<Content: View>: View {
    @Environment(\.theme) private var theme
    let number: String
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline, spacing: 14) {
                Text(number)
                    .font(theme.fonts.display(size: 14, weight: .regular))
                    .italic()
                    .foregroundColor(theme.colors.accent)
                    .frame(width: 22, alignment: .leading)

                Text(title)
                    .font(theme.fonts.microCaption)
                    .textCase(.uppercase)
                    .tracking(1.6)
                    .foregroundColor(theme.colors.textTertiary)
            }

            content()
                .padding(.leading, 36)
        }
    }
}

private struct LegalProse: View {
    @Environment(\.theme) private var theme
    let text: String

    var body: some View {
        Text(text)
            .font(theme.fonts.body(size: 15, weight: .regular))
            .foregroundColor(theme.colors.textSecondary)
            .lineSpacing(4)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Datenschutzerklärung

struct PrivacyPolicyView: View {
    var body: some View {
        LegalPage(
            ordinal: "Nº 08 · Datenschutz",
            title: "Was wir sehen, was nicht.",
            lede: "Wir halten uns an das Nötige. Deine Filmwahl gehört dir."
        ) {
            LegalSection(number: "i", title: "Verantwortlicher") {
                LegalProse(text: """
                Watchd App
                E-Mail: datenschutz@watchd.app
                """)
            }

            LegalSection(number: "ii", title: "Erhobene Daten") {
                LegalProse(text: """
                Wir erheben und verarbeiten:
                · E-Mail-Adresse (bei Registrierung)
                · Benutzername
                · Swipe-Verhalten und Matches (zur App-Funktion)
                · Favoriten-Listen
                """)
            }

            LegalSection(number: "iii", title: "Zweck") {
                LegalProse(text: """
                Deine Daten werden ausschliesslich zur Bereitstellung der Watchd-Funktionen verarbeitet:
                · Authentifizierung und Kontoverwaltung
                · Abgleich von Film-Präferenzen in gemeinsamen Räumen
                · Benachrichtigungen über Matches
                """)
            }

            LegalSection(number: "iv", title: "Datenweitergabe") {
                LegalProse(text: "Wir geben deine Daten nicht an Dritte weiter. Zur Anzeige von Filminformationen nutzen wir die TMDB-API und JustWatch-API. Dabei werden keine personenbezogenen Daten übermittelt.")
            }

            LegalSection(number: "v", title: "Speicherdauer") {
                LegalProse(text: "Deine Daten werden so lange gespeichert, wie dein Konto aktiv ist. Nach Löschung deines Kontos werden alle personenbezogenen Daten unwiderruflich innerhalb von 30 Tagen gelöscht.")
            }

            LegalSection(number: "vi", title: "Deine Rechte (DSGVO)") {
                LegalProse(text: """
                Du hast das Recht auf:
                · Auskunft über deine gespeicherten Daten
                · Berichtigung unrichtiger Daten
                · Löschung deiner Daten („Recht auf Vergessenwerden")
                · Einschränkung der Verarbeitung
                · Datenübertragbarkeit
                · Widerspruch gegen die Verarbeitung

                Du kannst dein Konto jederzeit in den App-Einstellungen löschen. Alle deine Daten werden dabei vollständig entfernt.
                """)
            }

            LegalSection(number: "vii", title: "Kontakt") {
                LegalProse(text: """
                Bei Fragen zum Datenschutz:
                datenschutz@watchd.app
                """)
            }
        }
    }
}

// MARK: - Nutzungsbedingungen

struct TermsOfServiceView: View {
    var body: some View {
        LegalPage(
            ordinal: "Nº 09 · Nutzung",
            title: "Die Regeln des Abends.",
            lede: "Kurz gehalten. Damit der Abend euch gehört — und wir wissen, woran wir sind."
        ) {
            LegalSection(number: "i", title: "Geltungsbereich") {
                LegalProse(text: "Diese Bedingungen gelten für die Nutzung der Watchd-App. Mit der Registrierung stimmst du ihnen zu.")
            }

            LegalSection(number: "ii", title: "Leistung") {
                LegalProse(text: "Watchd ermöglicht es zwei Nutzern, gemeinsam Filme zu entdecken, indem sie in geteilten Räumen durch Filmvorschläge swipen. Bei Übereinstimmung entsteht ein Match.")
            }

            LegalSection(number: "iii", title: "Nutzerkonto") {
                LegalProse(text: """
                · Du bist für die Sicherheit deines Kontos verantwortlich.
                · Du darfst dein Konto nicht an Dritte weitergeben.
                · Falsche Angaben bei der Registrierung können zur Sperrung führen.
                """)
            }

            LegalSection(number: "iv", title: "Verbotene Nutzung") {
                LegalProse(text: """
                Es ist untersagt:
                · Die App für illegale Zwecke zu nutzen.
                · Automatisierte Zugriffe auf die API durchzuführen.
                · Die App-Infrastruktur zu stören oder zu überlasten.
                · Inhalte zu teilen, die gegen geltendes Recht verstossen.
                """)
            }

            LegalSection(number: "v", title: "Haftungsausschluss") {
                LegalProse(text: "Filminformationen und Streaming-Verfügbarkeiten werden von Drittanbietern (TMDB, JustWatch) bereitgestellt. Wir übernehmen keine Garantie für deren Richtigkeit oder Aktualität.")
            }

            LegalSection(number: "vi", title: "Kündigung") {
                LegalProse(text: "Du kannst dein Konto jederzeit löschen. Wir behalten uns das Recht vor, Konten bei Verstössen gegen diese Bedingungen zu sperren.")
            }

            LegalSection(number: "vii", title: "Änderungen") {
                LegalProse(text: "Wir behalten uns vor, diese Bedingungen jederzeit zu ändern. Über wesentliche Änderungen wirst du per E-Mail informiert.")
            }

            LegalSection(number: "viii", title: "Anwendbares Recht") {
                LegalProse(text: "Es gilt das Recht der Bundesrepublik Deutschland. Gerichtsstand ist der Sitz des Betreibers.")
            }
        }
    }
}

// MARK: - Impressum (TMG §5)

struct ImpressumView: View {
    var body: some View {
        LegalPage(
            ordinal: "Nº 10 · Impressum",
            title: "Wer hier schreibt.",
            lede: nil
        ) {
            LegalSection(number: "i", title: "Angaben gemäß § 5 TMG") {
                LegalProse(text: """
                Watchd App
                [Dein vollständiger Name / Firmenname]
                [Straße Hausnummer]
                [PLZ Ort]
                Deutschland
                """)
            }

            LegalSection(number: "ii", title: "Kontakt") {
                LegalProse(text: "E-Mail: kontakt@watchd.app")
            }

            LegalSection(number: "iii", title: "Verantwortlich nach § 55 Abs. 2 RStV") {
                LegalProse(text: """
                [Dein vollständiger Name]
                [Adresse wie oben]
                """)
            }

            LegalSection(number: "iv", title: "Haftungsausschluss") {
                LegalProse(text: """
                Die Inhalte dieser App wurden mit größtmöglicher Sorgfalt erstellt. Für die Richtigkeit, Vollständigkeit und Aktualität der Inhalte können wir jedoch keine Gewähr übernehmen.

                Als Diensteanbieter sind wir gemäß § 7 Abs. 1 TMG für eigene Inhalte nach den allgemeinen Gesetzen verantwortlich. Nach §§ 8 bis 10 TMG sind wir jedoch nicht verpflichtet, übermittelte oder gespeicherte fremde Informationen zu überwachen.
                """)
            }

            LegalSection(number: "v", title: "Streitschlichtung") {
                LegalProse(text: """
                Die Europäische Kommission stellt eine Plattform zur Online-Streitbeilegung bereit:
                https://ec.europa.eu/consumers/odr

                Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer Verbraucherschlichtungsstelle teilzunehmen.
                """)
            }
        }
    }
}

// MARK: - TMDB Attribution (required by TMDB API Terms of Use)

struct TMDBAttributionView: View {
    @Environment(\.theme) private var theme

    var body: some View {
        LegalPage(
            ordinal: "Nº 11 · Quellen",
            title: "Wem wir die Filme verdanken.",
            lede: "Watchd kuratiert, aber das Material stammt von zwei Datenbanken. Respekt an sie beide."
        ) {
            LegalSection(number: "i", title: "The Movie Database") {
                VStack(alignment: .leading, spacing: 16) {
                    LegalProse(text: "Dieses Produkt verwendet die TMDB API, ist jedoch nicht von TMDB unterstützt oder zertifiziert.")
                    LegalProse(text: "Filminformationen, Bewertungen und Poster stammen von The Movie Database (TMDB).")
                    externalLink(title: "TMDB besuchen", url: "https://www.themoviedb.org")
                }
            }

            LegalSection(number: "ii", title: "JustWatch") {
                VStack(alignment: .leading, spacing: 16) {
                    LegalProse(text: "Streaming-Verfügbarkeiten stammen von JustWatch. Alle Marken und Logos gehören ihren jeweiligen Eigentümern.")
                    externalLink(title: "JustWatch besuchen", url: "https://www.justwatch.com")
                }
            }
        }
    }

    private func externalLink(title: String, url: String) -> some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 8) {
                Text(title)
                    .font(theme.fonts.microCaption)
                    .textCase(.uppercase)
                    .tracking(1.4)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 10, weight: .regular))
            }
            .foregroundColor(theme.colors.accent)
        }
    }
}

#Preview("Datenschutz") {
    NavigationStack {
        PrivacyPolicyView()
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}

#Preview("Nutzungsbedingungen") {
    NavigationStack {
        TermsOfServiceView()
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}

#Preview("Impressum") {
    NavigationStack {
        ImpressumView()
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}

#Preview("Quellen") {
    NavigationStack {
        TMDBAttributionView()
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}
