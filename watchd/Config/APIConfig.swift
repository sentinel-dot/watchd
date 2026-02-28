import Foundation

enum APIConfig {
    private static let backendBaseURL = "https://watchd.up.railway.app"

    static var baseURL: String { "\(backendBaseURL)/api" }
    static var socketURL: String { backendBaseURL }
    /// Basis-URL für statische Assets (z. B. Streaming-Icons unter /icons/).
    static var iconsBaseURL: String { backendBaseURL }
    /// w780 = 780px – schärfer auf Retina (Detail/ große Karten). TMDB: w92, w154, w185, w342, w500, w780, original
    static let tmdbImageBase = "https://image.tmdb.org/t/p/w780"
}
