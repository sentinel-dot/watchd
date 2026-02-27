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

struct UpgradeAccountRequest: Encodable {
    let email: String
    let password: String
}

struct ForgotPasswordRequest: Encodable {
    let email: String
}

struct ResetPasswordRequest: Encodable {
    let token: String
    let newPassword: String
}

struct UpdateUserNameRequest: Encodable {
    let name: String
}

struct AuthResponse: Decodable {
    let token: String
    let user: User
}

struct User: Decodable, Identifiable {
    let id: Int
    let name: String
    let email: String?
    let isGuest: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, name, email
        case isGuest = "isGuest"
    }
    
    init(id: Int, name: String, email: String?, isGuest: Bool) {
        self.id = id
        self.name = name
        self.email = email
        self.isGuest = isGuest
    }
}

struct UpdateUserResponse: Decodable {
    let user: User
}

struct MessageResponse: Decodable {
    let message: String
}

struct ErrorResponse: Decodable {
    let message: String?
    let error: String?
}
