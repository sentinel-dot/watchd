import Foundation

struct Partnership: Identifiable, Decodable, Hashable {
    let id: Int
    let status: String              // "pending" | "active"
    let requesterId: Int?
    let addresseeId: Int?
    let filters: PartnershipFilters?
    let partner: PartnerUser?
    let createdAt: String?
    let acceptedAt: String?
    let lastActivityAt: String?

    static func == (lhs: Partnership, rhs: Partnership) -> Bool {
        lhs.id == rhs.id && lhs.status == rhs.status
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(status)
    }
}

struct PartnerUser: Identifiable, Decodable, Equatable {
    let id: Int
    let name: String
}

struct PartnershipFilters: Codable, Equatable {
    var genres: [Int]?
    var streamingServices: [String]?
    var yearFrom: Int?
    var minRating: Double?
    var maxRuntime: Int?
    var language: String?
}

struct PartnershipsListResponse: Decodable {
    let incoming: [Partnership]
    let outgoing: [Partnership]
    let active: [Partnership]
}

struct PartnershipDetailResponse: Decodable {
    let partnership: Partnership
}

struct PartnershipFiltersResponse: Decodable {
    let partnershipId: Int
    let filters: PartnershipFilters?
}

struct PartnershipDeletedResponse: Decodable {
    let deleted: Bool
}

struct AddPartnerRequest: Encodable {
    let shareCode: String
}

struct ShareCodeResponse: Decodable {
    let shareCode: String
}

struct PartnershipRequestSocketEvent: Decodable {
    let partnershipId: Int
    let requester: PartnerUser
}

struct PartnershipAcceptedSocketEvent: Decodable {
    let partnershipId: Int
    let partner: PartnerUser
}

struct PartnershipEndedSocketEvent: Decodable {
    let partnershipId: Int
}
