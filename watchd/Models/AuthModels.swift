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

struct User: Decodable, Identifiable {
    let id: Int
    let name: String
    let email: String?

    init(id: Int, name: String, email: String?) {
        self.id = id
        self.name = name
        self.email = email
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
