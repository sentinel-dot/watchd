import Foundation

enum APIConfig {
    /// Auf Simulator: localhost. Auf echtem Gerät: lokale IP deines Macs (gleiches WLAN).
    private static let backendHost: String = {
        #if targetEnvironment(simulator)
        return "localhost"
        #else
        return "192.168.178.37"
        #endif
    }()

    static var baseURL: String { "http://\(backendHost):3000/api" }
    static var socketURL: String { "http://\(backendHost):3000" }
    /// Basis-URL für statische Assets (z. B. Streaming-Icons unter /icons/).
    static var iconsBaseURL: String { "http://\(backendHost):3000" }
    /// w780 = 780px – schärfer auf Retina (Detail/ große Karten). TMDB: w92, w154, w185, w342, w500, w780, original
    static let tmdbImageBase = "https://image.tmdb.org/t/p/w780"
}
