import Foundation

@MainActor
final class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()
    
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    init() {
        setupUnauthorizedListener()
        loadSession()
    }
    
    private func loadSession() {
        guard let token = KeychainHelper.load(forKey: KeychainHelper.tokenKey),
              !token.isEmpty,
              let idStr = KeychainHelper.load(forKey: KeychainHelper.userIdKey),
              let id = Int(idStr),
              let name = KeychainHelper.load(forKey: KeychainHelper.userNameKey)
        else { return }

        let email = KeychainHelper.load(forKey: KeychainHelper.userEmailKey)
        let isGuestStr = KeychainHelper.load(forKey: KeychainHelper.isGuestKey) ?? "false"
        let isGuest = isGuestStr == "true"
        
        currentUser = User(id: id, name: name, email: email, isGuest: isGuest)
        isAuthenticated = true
    }
    
    private func setupUnauthorizedListener() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("unauthorizedError"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleUnauthorized()
        }
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
    
    func guestLogin() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.guestLogin()
            persistSession(response)
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func upgradeAccount(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.upgradeAccount(email: email, password: password)
            persistSession(response)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    func updateName(_ newName: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.updateUserName(name: newName)
            currentUser = response.user
            KeychainHelper.save(response.user.name, forKey: KeychainHelper.userNameKey)
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
    
    func handleUnauthorized() {
        logout()
        errorMessage = "Session expired. Please log in again."
    }

    private func persistSession(_ response: AuthResponse) {
        KeychainHelper.save(response.token, forKey: KeychainHelper.tokenKey)
        KeychainHelper.save(String(response.user.id), forKey: KeychainHelper.userIdKey)
        KeychainHelper.save(response.user.name, forKey: KeychainHelper.userNameKey)
        
        if let email = response.user.email {
            KeychainHelper.save(email, forKey: KeychainHelper.userEmailKey)
        } else {
            KeychainHelper.delete(forKey: KeychainHelper.userEmailKey)
        }
        
        KeychainHelper.save(response.user.isGuest ? "true" : "false", forKey: KeychainHelper.isGuestKey)
        currentUser = response.user
    }
}
