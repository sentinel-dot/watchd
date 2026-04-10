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

    /// Whether a token refresh is currently in-flight (prevents parallel refreshes).
    private var isRefreshing = false

    private func request<T: Decodable>(
        path: String,
        method: String = "GET",
        body: Encodable? = nil,
        requiresAuth: Bool = true,
        isRetryAfterRefresh: Bool = false
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

        // Auto-refresh: on 401, try to refresh the access token once
        if http.statusCode == 401 && requiresAuth && !isRetryAfterRefresh {
            let refreshed = await attemptTokenRefresh()
            if refreshed {
                return try await request(path: path, method: method, body: body, requiresAuth: true, isRetryAfterRefresh: true)
            }
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("unauthorizedError"), object: nil)
            }
            throw APIError.unauthorized
        }

        if http.statusCode == 401 {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NSNotification.Name("unauthorizedError"), object: nil)
            }
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
            throw APIError.decodingError(error)
        }
    }

    /// Attempts to refresh the access token using the stored refresh token.
    private func attemptTokenRefresh() async -> Bool {
        guard !isRefreshing else { return false }
        guard let refreshToken = KeychainHelper.load(forKey: KeychainHelper.refreshTokenKey) else { return false }

        isRefreshing = true
        defer { isRefreshing = false }

        do {
            struct RefreshBody: Encodable { let refreshToken: String }
            struct RefreshResponse: Decodable { let token: String; let refreshToken: String; let user: User }

            let body = RefreshBody(refreshToken: refreshToken)
            guard let url = URL(string: APIConfig.baseURL + "/auth/refresh") else { return false }

            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.httpBody = try encoder.encode(body)

            let (data, response) = try await session.data(for: req)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else { return false }

            let refreshResponse = try decoder.decode(RefreshResponse.self, from: data)
            KeychainHelper.save(refreshResponse.token, forKey: KeychainHelper.tokenKey)
            KeychainHelper.save(refreshResponse.refreshToken, forKey: KeychainHelper.refreshTokenKey)
            return true
        } catch {
            return false
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
    
    func guestLogin() async throws -> AuthResponse {
        return try await request(path: "/auth/guest", method: "POST", requiresAuth: false)
    }
    
    func upgradeAccount(email: String, password: String) async throws -> AuthResponse {
        let body = UpgradeAccountRequest(email: email, password: password)
        return try await request(path: "/auth/upgrade", method: "POST", body: body)
    }
    
    func forgotPassword(email: String) async throws -> MessageResponse {
        let body = ForgotPasswordRequest(email: email)
        return try await request(path: "/auth/forgot-password", method: "POST", body: body, requiresAuth: false)
    }
    
    func resetPassword(token: String, newPassword: String) async throws -> MessageResponse {
        let body = ResetPasswordRequest(token: token, newPassword: newPassword)
        return try await request(path: "/auth/reset-password", method: "POST", body: body, requiresAuth: false)
    }
    
    // MARK: - Users
    
    func updateUserName(name: String) async throws -> UpdateUserResponse {
        let body = UpdateUserNameRequest(name: name)
        return try await request(path: "/users/me", method: "PATCH", body: body)
    }

    // MARK: - Rooms

    func createRoom(name: String? = nil, filters: RoomFilters? = nil) async throws -> RoomResponse {
        struct CreateRoomBody: Encodable {
            let name: String?
            let filters: RoomFilters?
        }
        let body = CreateRoomBody(name: name, filters: filters)
        return try await request(path: "/rooms", method: "POST", body: body)
    }

    func joinRoom(code: String) async throws -> RoomResponse {
        let body = JoinRoomRequest(code: code)
        return try await request(path: "/rooms/join", method: "POST", body: body)
    }

    func getRoom(id: Int) async throws -> RoomDetailResponse {
        return try await request(path: "/rooms/\(id)")
    }
    
    func getRooms() async throws -> RoomsListResponse {
        return try await request(path: "/rooms")
    }
    
    func updateRoomName(roomId: Int, name: String) async throws -> RoomResponse {
        struct UpdateNameBody: Encodable {
            let name: String
        }
        let body = UpdateNameBody(name: name)
        return try await request(path: "/rooms/\(roomId)", method: "PATCH", body: body)
    }
    
    func updateRoomFilters(roomId: Int, filters: RoomFilters) async throws -> RoomResponse {
        struct UpdateFiltersBody: Encodable {
            let filters: RoomFilters
        }
        let body = UpdateFiltersBody(filters: filters)
        return try await request(path: "/rooms/\(roomId)/filters", method: "PATCH", body: body)
    }
    
    func leaveRoom(roomId: Int) async throws -> LeaveRoomResponse {
        return try await request(path: "/rooms/\(roomId)/leave", method: "DELETE")
    }

    func deleteFromArchive(roomId: Int) async throws {
        struct DeleteArchiveResponse: Decodable { let deleted: Bool }
        let _: DeleteArchiveResponse = try await request(path: "/rooms/\(roomId)/archive", method: "DELETE")
    }

    // MARK: - Movies

    func getMovieFeed(roomId: Int, page: Int = 1) async throws -> MovieFeedResponse {
        return try await request(path: "/movies/feed?roomId=\(roomId)&page=\(page)")
    }
    
    func getNextMovie(roomId: Int) async throws -> NextMovieResponse {
        return try await request(path: "/movies/rooms/\(roomId)/next-movie")
    }

    // MARK: - Swipes

    func submitSwipe(movieId: Int, roomId: Int, direction: String) async throws -> SwipeResponse {
        let body = SwipeRequest(movieId: movieId, roomId: roomId, direction: direction)
        return try await request(path: "/swipes", method: "POST", body: body)
    }

    // MARK: - Matches

    func getMatches(roomId: Int, limit: Int = 20, offset: Int = 0) async throws -> MatchesResponse {
        return try await request(path: "/matches/\(roomId)?limit=\(limit)&offset=\(offset)")
    }
    
    func updateMatchWatched(matchId: Int, watched: Bool) async throws -> UpdateMatchResponse {
        struct UpdateWatchedBody: Encodable {
            let watched: Bool
        }
        let body = UpdateWatchedBody(watched: watched)
        return try await request(path: "/matches/\(matchId)", method: "PATCH", body: body)
    }
    
    // MARK: - Favorites
    
    func addFavorite(movieId: Int) async throws -> MessageResponse {
        struct AddFavoriteBody: Encodable {
            let movieId: Int
        }
        let body = AddFavoriteBody(movieId: movieId)
        return try await request(path: "/matches/favorites", method: "POST", body: body)
    }
    
    func removeFavorite(movieId: Int) async throws -> MessageResponse {
        return try await request(path: "/matches/favorites/\(movieId)", method: "DELETE")
    }
    
    func getFavorites(limit: Int = 20, offset: Int = 0) async throws -> FavoritesResponse {
        return try await request(path: "/matches/favorites/list?limit=\(limit)&offset=\(offset)")
    }

    // MARK: - Account Management

    func serverLogout() async {
        guard let refreshToken = KeychainHelper.load(forKey: KeychainHelper.refreshTokenKey) else { return }
        struct LogoutBody: Encodable { let refreshToken: String }
        let body = LogoutBody(refreshToken: refreshToken)
        let _: MessageResponse? = try? await request(path: "/auth/logout", method: "POST", body: body, requiresAuth: false)
    }

    func deleteAccount() async throws -> MessageResponse {
        return try await request(path: "/auth/delete-account", method: "DELETE")
    }
}
