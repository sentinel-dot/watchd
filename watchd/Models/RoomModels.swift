import Foundation

struct Room: Identifiable {
    let id: Int
    let code: String
    let createdBy: Int
    let createdAt: String
    let status: String?
    let name: String?
    let filters: RoomFilters?
    let lastActivityAt: String?
}

extension Room: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, code, createdBy, createdAt, status, name, filters, lastActivityAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decode(Int.self, forKey: .id)
        code = try container.decode(String.self, forKey: .code)
        createdBy = try container.decode(Int.self, forKey: .createdBy)
        createdAt = try container.decode(String.self, forKey: .createdAt)
        status = try container.decodeIfPresent(String.self, forKey: .status)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        lastActivityAt = try container.decodeIfPresent(String.self, forKey: .lastActivityAt)
        
        // Handle filters - can be either a JSON string or an object
        if let filtersString = try? container.decode(String.self, forKey: .filters) {
            // Backend sent filters as JSON string
            if let data = filtersString.data(using: .utf8) {
                let jsonDecoder = JSONDecoder()
                jsonDecoder.keyDecodingStrategy = .convertFromSnakeCase
                filters = try? jsonDecoder.decode(RoomFilters.self, from: data)
            } else {
                filters = nil
            }
        } else {
            // Backend sent filters as object (or null)
            filters = try container.decodeIfPresent(RoomFilters.self, forKey: .filters)
        }
    }
}

struct RoomFilters: Codable {
    var genres: [Int]?
    var streamingServices: [String]?
    var yearFrom: Int?
    var minRating: Double?
    var maxRuntime: Int?
    var language: String?
}

struct RoomMember: Decodable, Identifiable {
    let userId: Int
    let name: String
    let email: String?
    let joinedAt: String
    let isActive: Bool?

    var id: Int { userId }
}

struct RoomResponse: Decodable {
    let room: Room
}

struct RoomDetailResponse: Decodable {
    let room: Room
    let members: [RoomMember]
}

struct RoomsListResponse: Decodable {
    let rooms: [Room]
}

struct LeaveRoomResponse: Decodable {
    let lastMember: Bool
}

struct JoinRoomRequest: Encodable {
    let code: String
}
