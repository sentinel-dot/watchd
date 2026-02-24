import Foundation

struct Movie: Decodable, Identifiable {
    let id: Int
    let title: String
    let overview: String
    let posterPath: String?
    let releaseDate: String?
    let voteAverage: Double
    let streamingOptions: [StreamingOption]

    private enum CodingKeys: CodingKey {
        case id, title, overview, posterPath, releaseDate, voteAverage, streamingOptions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(Int.self,    forKey: .id)
        title            = try c.decode(String.self, forKey: .title)
        overview         = try c.decode(String.self, forKey: .overview)
        posterPath       = try c.decodeIfPresent(String.self, forKey: .posterPath)
        releaseDate      = try c.decodeIfPresent(String.self, forKey: .releaseDate)
        voteAverage      = try c.decode(Double.self, forKey: .voteAverage)
        streamingOptions = try c.decodeIfPresent([StreamingOption].self, forKey: .streamingOptions) ?? []
    }

    var posterURL: URL? {
        guard let path = posterPath else { return nil }
        return URL(string: APIConfig.tmdbImageBase + path)
    }

    var releaseYear: String? {
        guard let date = releaseDate, date.count >= 4 else { return nil }
        return String(date.prefix(4))
    }
}

struct StreamingOption: Decodable, Identifiable {
    let monetizationType: String
    let presentationType: String
    let package: StreamingPackage

    var id: String { package.clearName + monetizationType + presentationType }
}

struct StreamingPackage: Decodable {
    let clearName: String
    let icon: String

    var iconURL: URL? { URL(string: icon) }
}

struct MovieFeedResponse: Decodable {
    let page: Int
    let movies: [Movie]
}

struct SwipeRequest: Encodable {
    let movieId: Int
    let roomId: Int
    let direction: String
}

struct SwipeResponse: Decodable {
    let swipe: SwipeInfo
    let match: MatchInfo?
}

struct SwipeInfo: Decodable {
    let userId: Int
    let movieId: Int
    let roomId: Int
    let direction: String
}

struct MatchInfo: Decodable {
    let isMatch: Bool
    let matchId: Int?
    let movieId: Int?
    let movieTitle: String?
    let posterPath: String?
    let streamingOptions: [StreamingOption]?
}
