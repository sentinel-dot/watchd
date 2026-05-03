import Foundation

enum APIConfig {
    // Release-Builds (TestFlight, App Store) → immer Production-URL.
    // Debug-Builds → lokale Entwicklung. Bei Tests auf physischem Gerät
    // die LAN-IP des Macs eintragen (z. B. "http://192.168.1.42:3000").
    #if DEBUG
    private static let backendBaseURL = "http://localhost:3000"
    #else
    private static let backendBaseURL = "http://192.168.178.33:3000"
    #endif

    static var baseURL: String { "\(backendBaseURL)/api" }
    static var socketURL: String { backendBaseURL }
    /// Basis-URL für statische Assets (z. B. Streaming-Icons unter /icons/).
    static var iconsBaseURL: String { backendBaseURL }
    /// w780 = 780px – schärfer auf Retina (Detail/ große Karten). TMDB: w92, w154, w185, w342, w500, w780, original
    static let tmdbImageBase = "https://image.tmdb.org/t/p/w780"

    // Google Sign-In iOS OAuth 2.0 Client ID.
    // Obtain from: console.cloud.google.com → APIs & Services → Credentials
    // → Create credentials → OAuth 2.0 Client ID → iOS.
    // Replace the placeholder with your real client ID before shipping.
    static let googleClientId = "600845465744-4cjhu5pv0fnslqfbmtjf8r4tcm54buki.apps.googleusercontent.com"
}
