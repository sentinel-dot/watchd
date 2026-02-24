import Foundation

struct Room: Decodable, Identifiable {
    let id: Int
    let code: String
    let createdBy: Int
    let createdAt: String
}

struct RoomMember: Decodable, Identifiable {
    let userId: Int
    let name: String
    let email: String
    let joinedAt: String

    var id: Int { userId }
}

struct RoomResponse: Decodable {
    let room: Room
}

struct RoomDetailResponse: Decodable {
    let room: Room
    let members: [RoomMember]
}

struct JoinRoomRequest: Encodable {
    let code: String
}
