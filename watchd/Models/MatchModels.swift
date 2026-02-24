import Foundation

struct Match: Decodable, Identifiable {
    let id: Int
    let roomId: Int
    let matchedAt: String
    let movie: MatchMovie
    let streamingOptions: [StreamingOption]
}

struct MatchMovie: Decodable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: APIConfig.tmdbImageBase + path)
    }

    var releaseYear: String? {
        guard let date = releaseDate, date.count >= 4 else { return nil }
        return String(date.prefix(4))
    }
}

struct MatchesResponse: Decodable {
    let matches: [Match]
}

struct SocketMatchEvent: Decodable, Identifiable {
    let movieId: Int
    let movieTitle: String
    let posterPath: String?
    let streamingOptions: [StreamingOption]

    var id: Int { movieId }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: APIConfig.tmdbImageBase + path)
    }
}
