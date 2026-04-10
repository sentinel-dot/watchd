import SwiftUI

// MARK: - Datenschutzerklärung

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    sectionHeader("1. Verantwortlicher")
                    sectionText("""
                    Watchd App
                    E-Mail: datenschutz@watchd.app
                    """)

                    sectionHeader("2. Erhobene Daten")
                    sectionText("""
                    Wir erheben und verarbeiten folgende personenbezogene Daten:
                    • E-Mail-Adresse (bei Registrierung)
                    • Benutzername
                    • Swipe-Verhalten und Matches (zur Bereitstellung der App-Funktion)
                    • Favoriten-Listen
                    """)

                    sectionHeader("3. Zweck der Datenverarbeitung")
                    sectionText("""
                    Deine Daten werden ausschliesslich zur Bereitstellung der Watchd-App-Funktionen verarbeitet:
                    • Authentifizierung und Kontoverwaltung
                    • Abgleich von Film-Präferenzen in gemeinsamen Rooms
                    • Benachrichtigungen über Matches
                    """)
                }

                Group {
                    sectionHeader("4. Datenweitergabe")
                    sectionText("""
                    Wir geben deine Daten nicht an Dritte weiter. \
                    Zur Anzeige von Filminformationen nutzen wir die TMDB-API und JustWatch-API. \
                    Dabei werden keine personenbezogenen Daten übermittelt.
                    """)

                    sectionHeader("5. Speicherdauer")
                    sectionText("""
                    Deine Daten werden so lange gespeichert, wie dein Konto aktiv ist. \
                    Nach Löschung deines Kontos werden alle personenbezogenen Daten \
                    unwiderruflich innerhalb von 30 Tagen gelöscht.
                    """)

                    sectionHeader("6. Deine Rechte (DSGVO)")
                    sectionText("""
                    Du hast das Recht auf:
                    • Auskunft über deine gespeicherten Daten
                    • Berichtigung unrichtiger Daten
                    • Löschung deiner Daten ("Recht auf Vergessenwerden")
                    • Einschränkung der Verarbeitung
                    • Datenübertragbarkeit
                    • Widerspruch gegen die Verarbeitung

                    Du kannst dein Konto jederzeit in den App-Einstellungen löschen. \
                    Alle deine Daten werden dabei vollständig entfernt.
                    """)

                    sectionHeader("7. Kontakt")
                    sectionText("""
                    Bei Fragen zum Datenschutz wende dich an:
                    datenschutz@watchd.app
                    """)
                }
            }
            .padding(20)
        }
        .background(WatchdTheme.background.ignoresSafeArea())
        .navigationTitle("Datenschutzerklärung")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(WatchdTheme.background, for: .navigationBar)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(WatchdTheme.titleMedium())
            .foregroundColor(WatchdTheme.textPrimary)
    }

    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(WatchdTheme.body())
            .foregroundColor(WatchdTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Nutzungsbedingungen

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Group {
                    sectionHeader("1. Geltungsbereich")
                    sectionText("""
                    Diese Nutzungsbedingungen gelten für die Nutzung der Watchd-App. \
                    Mit der Registrierung stimmst du diesen Bedingungen zu.
                    """)

                    sectionHeader("2. Leistungsbeschreibung")
                    sectionText("""
                    Watchd ermöglicht es Nutzern, gemeinsam Filme zu entdecken, \
                    indem sie in geteilten Rooms durch Filmvorschläge swipen. \
                    Bei Übereinstimmung wird ein Match erstellt.
                    """)

                    sectionHeader("3. Nutzerkonto")
                    sectionText("""
                    • Du bist für die Sicherheit deines Kontos verantwortlich
                    • Du darfst dein Konto nicht an Dritte weitergeben
                    • Falsche Angaben bei der Registrierung können zur Sperrung führen
                    """)
                }

                Group {
                    sectionHeader("4. Verbotene Nutzung")
                    sectionText("""
                    Es ist untersagt:
                    • Die App für illegale Zwecke zu nutzen
                    • Automatisierte Zugriffe auf die API durchzuführen
                    • Die App-Infrastruktur zu stören oder zu überlasten
                    • Inhalte zu teilen, die gegen geltendes Recht verstossen
                    """)

                    sectionHeader("5. Haftungsausschluss")
                    sectionText("""
                    Filminformationen und Streaming-Verfügbarkeiten werden von \
                    Drittanbietern (TMDB, JustWatch) bereitgestellt. \
                    Wir übernehmen keine Garantie für deren Richtigkeit oder Aktualität.
                    """)

                    sectionHeader("6. Kündigung")
                    sectionText("""
                    Du kannst dein Konto jederzeit löschen. \
                    Wir behalten uns das Recht vor, Konten bei Verstössen gegen \
                    diese Nutzungsbedingungen zu sperren.
                    """)

                    sectionHeader("7. Änderungen")
                    sectionText("""
                    Wir behalten uns vor, diese Nutzungsbedingungen jederzeit zu ändern. \
                    Über wesentliche Änderungen wirst du per E-Mail informiert.
                    """)

                    sectionHeader("8. Anwendbares Recht")
                    sectionText("""
                    Es gilt das Recht der Bundesrepublik Deutschland. \
                    Gerichtsstand ist der Sitz des Betreibers.
                    """)
                }
            }
            .padding(20)
        }
        .background(WatchdTheme.background.ignoresSafeArea())
        .navigationTitle("Nutzungsbedingungen")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(WatchdTheme.background, for: .navigationBar)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(WatchdTheme.titleMedium())
            .foregroundColor(WatchdTheme.textPrimary)
    }

    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(WatchdTheme.body())
            .foregroundColor(WatchdTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
    .preferredColorScheme(.dark)
}

// MARK: - Impressum (TMG §5)

struct ImpressumView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                sectionHeader("Angaben gemäß § 5 TMG")
                sectionText("""
                Watchd App
                [Dein vollständiger Name / Firmenname]
                [Straße Hausnummer]
                [PLZ Ort]
                Deutschland
                """)

                sectionHeader("Kontakt")
                sectionText("""
                E-Mail: kontakt@watchd.app
                """)

                sectionHeader("Verantwortlich für den Inhalt nach § 55 Abs. 2 RStV")
                sectionText("""
                [Dein vollständiger Name]
                [Adresse wie oben]
                """)

                sectionHeader("Haftungsausschluss")
                sectionText("""
                Die Inhalte dieser App wurden mit größtmöglicher Sorgfalt erstellt. \
                Für die Richtigkeit, Vollständigkeit und Aktualität der Inhalte \
                können wir jedoch keine Gewähr übernehmen.

                Als Diensteanbieter sind wir gemäß § 7 Abs.1 TMG für eigene \
                Inhalte in dieser App nach den allgemeinen Gesetzen verantwortlich. \
                Nach §§ 8 bis 10 TMG sind wir als Diensteanbieter jedoch nicht \
                verpflichtet, übermittelte oder gespeicherte fremde Informationen \
                zu überwachen.
                """)

                sectionHeader("Streitschlichtung")
                sectionText("""
                Die Europäische Kommission stellt eine Plattform zur \
                Online-Streitbeilegung (OS) bereit: \
                https://ec.europa.eu/consumers/odr

                Wir sind nicht bereit oder verpflichtet, an \
                Streitbeilegungsverfahren vor einer \
                Verbraucherschlichtungsstelle teilzunehmen.
                """)
            }
            .padding(20)
        }
        .background(WatchdTheme.background.ignoresSafeArea())
        .navigationTitle("Impressum")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(WatchdTheme.background, for: .navigationBar)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(WatchdTheme.titleMedium())
            .foregroundColor(WatchdTheme.textPrimary)
    }

    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(WatchdTheme.body())
            .foregroundColor(WatchdTheme.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - TMDB Attribution (required by TMDB API Terms of Use)

struct TMDBAttributionView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // TMDB Logo placeholder – replace with actual TMDB logo asset
                VStack(spacing: 12) {
                    Image(systemName: "film.circle.fill")
                        .font(.system(size: 64, weight: .light))
                        .foregroundColor(Color(red: 0.01, green: 0.81, blue: 0.48))

                    Text("TMDB")
                        .font(WatchdTheme.titleLarge())
                        .foregroundColor(Color(red: 0.01, green: 0.81, blue: 0.48))
                }
                .padding(.top, 32)

                VStack(alignment: .leading, spacing: 16) {
                    Text("Dieses Produkt verwendet die TMDB API, ist jedoch nicht von TMDB unterstützt oder zertifiziert.")
                        .font(WatchdTheme.body())
                        .foregroundColor(WatchdTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Filminformationen, Bewertungen und Poster werden von The Movie Database (TMDB) bereitgestellt.")
                        .font(WatchdTheme.body())
                        .foregroundColor(WatchdTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Streaming-Verfügbarkeiten werden von JustWatch bereitgestellt. Alle Marken und Logos gehören ihren jeweiligen Eigentümern.")
                        .font(WatchdTheme.body())
                        .foregroundColor(WatchdTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Divider()
                        .background(WatchdTheme.separator)

                    Link(destination: URL(string: "https://www.themoviedb.org")!) {
                        HStack {
                            Text("TMDB besuchen")
                                .font(WatchdTheme.bodyMedium())
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(WatchdTheme.iconSmall())
                        }
                        .foregroundColor(WatchdTheme.primary)
                    }

                    Link(destination: URL(string: "https://www.justwatch.com")!) {
                        HStack {
                            Text("JustWatch besuchen")
                                .font(WatchdTheme.bodyMedium())
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(WatchdTheme.iconSmall())
                        }
                        .foregroundColor(WatchdTheme.primary)
                    }
                }
                .padding(.horizontal, 24)

                Spacer()
            }
        }
        .background(WatchdTheme.background.ignoresSafeArea())
        .navigationTitle("Datenquellen")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(WatchdTheme.background, for: .navigationBar)
    }
}

#Preview("Impressum") {
    NavigationStack {
        ImpressumView()
    }
    .preferredColorScheme(.dark)
}

#Preview("TMDB Attribution") {
    NavigationStack {
        TMDBAttributionView()
    }
    .preferredColorScheme(.dark)
}
