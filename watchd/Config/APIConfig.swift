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
    static let tmdbImageBase = "https://image.tmdb.org/t/p/w500"
}
