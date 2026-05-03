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
    let refreshToken: String?
    let user: User
}

struct AppleAuthRequest: Encodable {
    let identityToken: String
    let nonce: String
    let authorizationCode: String
    let name: String?
}

struct User: Decodable, Identifiable {
    let id: Int
    let name: String
    let email: String?
    let isPasswordResettable: Bool

    init(id: Int, name: String, email: String?, isPasswordResettable: Bool = true) {
        self.id = id
        self.name = name
        self.email = email
        self.isPasswordResettable = isPasswordResettable
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
