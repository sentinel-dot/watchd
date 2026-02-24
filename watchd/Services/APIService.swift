import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(String)
    case decodingError(Error)
    case networkError(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:            return "Invalid URL"
        case .unauthorized:          return "Session expired. Please log in again."
        case .serverError(let msg):  return msg
        case .decodingError(let e):  return "Data error: \(e.localizedDescription)"
        case .networkError(let e):   return e.localizedDescription
        }
    }
}

final class APIService {
    static let shared = APIService()

    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        session = URLSession(configuration: config)

        decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        encoder = JSONEncoder()
    }

    // MARK: - Generic Request

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: APIConfig.baseURL + path) else {
            throw APIError.invalidURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token = KeychainHelper.load(forKey: KeychainHelper.tokenKey) {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            req.httpBody = try encoder.encode(body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: req)
        } catch {
            throw APIError.networkError(error)
        }

        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }

        if http.statusCode == 401 {
            throw APIError.unauthorized
        }

        guard (200...299).contains(http.statusCode) else {
            let errorBody = try? JSONDecoder().decode(ErrorResponse.self, from: data)
            let msg = errorBody?.message ?? errorBody?.error ?? "Server error (\(http.statusCode))"
            throw APIError.serverError(msg)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            print("❌ Decoding error for \(T.self) at \(path)")
            print("❌ Raw response: \(raw)")
            print("❌ Error: \(error)")
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Auth

    func register(name: String, email: String, password: String) async throws -> AuthResponse {
        let body = RegisterRequest(name: name, email: email, password: password)
        return try await request(path: "/auth/register", method: "POST", body: body, requiresAuth: false)
    }

    func login(email: String, password: String) async throws -> AuthResponse {
        let body = LoginRequest(email: email, password: password)
        return try await request(path: "/auth/login", method: "POST", body: body, requiresAuth: false)
    }

    // MARK: - Rooms

    func createRoom() async throws -> RoomResponse {
        return try await request(path: "/rooms", method: "POST")
    }

    func joinRoom(code: String) async throws -> RoomResponse {
        let body = JoinRoomRequest(code: code)
        return try await request(path: "/rooms/join", method: "POST", body: body)
    }

    func getRoom(id: Int) async throws -> RoomDetailResponse {
        return try await request(path: "/rooms/\(id)")
    }

    // MARK: - Movies

    func getMovieFeed(roomId: Int, page: Int = 1) async throws -> MovieFeedResponse {
        return try await request(path: "/movies/feed?roomId=\(roomId)&page=\(page)")
    }

    // MARK: - Swipes

    func submitSwipe(movieId: Int, roomId: Int, direction: String) async throws -> SwipeResponse {
        let body = SwipeRequest(movieId: movieId, roomId: roomId, direction: direction)
        return try await request(path: "/swipes", method: "POST", body: body)
    }

    // MARK: - Matches

    func getMatches(roomId: Int) async throws -> MatchesResponse {
        return try await request(path: "/matches/\(roomId)")
    }
}
