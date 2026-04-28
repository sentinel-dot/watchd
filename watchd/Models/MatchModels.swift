import Foundation

struct Match: Decodable, Identifiable, Equatable {
    let id: Int
    let partnershipId: Int
    let matchedAt: String
    let watched: Bool?
    let movie: MatchMovie
    let streamingOptions: [StreamingOption]

    var isWatched: Bool { watched ?? false }

    static func == (lhs: Match, rhs: Match) -> Bool {
        lhs.id == rhs.id && lhs.watched == rhs.watched
    }
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

struct PaginationInfo: Decodable {
    let total: Int
    let limit: Int
    let offset: Int
    let hasMore: Bool
}

struct MatchesResponse: Decodable {
    let matches: [Match]
    let pagination: PaginationInfo?
}

struct UpdateMatchResponse: Decodable {
    let message: String
    let matchId: Int
    let watched: Bool
}

struct Favorite: Decodable, Identifiable {
    let id: Int
    let createdAt: String
    let movie: MatchMovie
    let streamingOptions: [StreamingOption]
}

struct FavoritesResponse: Decodable {
    let favorites: [Favorite]
    let pagination: PaginationInfo?
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
