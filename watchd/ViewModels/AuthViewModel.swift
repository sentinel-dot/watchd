import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        guard let token = KeychainHelper.load(forKey: KeychainHelper.tokenKey),
              !token.isEmpty,
              let idStr = KeychainHelper.load(forKey: KeychainHelper.userIdKey),
              let id = Int(idStr),
              let name = KeychainHelper.load(forKey: KeychainHelper.userNameKey),
              let email = KeychainHelper.load(forKey: KeychainHelper.userEmailKey)
        else { return }

        currentUser = User(id: id, name: name, email: email)
        isAuthenticated = true
    }

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.login(email: email, password: password)
            persistSession(response)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func register(name: String, email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.register(name: name, email: email, password: password)
            persistSession(response)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func logout() {
        SocketService.shared.disconnect()
        KeychainHelper.clearAll()
        currentUser = nil
        isAuthenticated = false
    }

    private func persistSession(_ response: AuthResponse) {
        KeychainHelper.save(response.token, forKey: KeychainHelper.tokenKey)
        KeychainHelper.save(String(response.user.id), forKey: KeychainHelper.userIdKey)
        KeychainHelper.save(response.user.name, forKey: KeychainHelper.userNameKey)
        KeychainHelper.save(response.user.email, forKey: KeychainHelper.userEmailKey)
        currentUser = response.user
    }
}
