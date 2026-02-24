import Foundation

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct RegisterRequest: Encodable {
    let name: String
    let email: String
    let password: String
}

struct AuthResponse: Decodable {
    let token: String
    let user: User
}

struct User: Decodable, Identifiable {
    let id: Int
    let name: String
    let email: String
}

struct ErrorResponse: Decodable {
    let message: String?
    let error: String?
}
