import Foundation
import UIKit
import UserNotifications

@MainActor
final class AuthViewModel: ObservableObject {
    static let shared = AuthViewModel()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {
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
        currentUser = User(id: id, name: name, email: email)
        isAuthenticated = true
        requestPushPermissionIfNeeded()
        SocketService.shared.connect(token: token, partnershipId: nil)
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

    func signInWithApple(
        identityToken: String,
        nonce: String,
        authorizationCode: String,
        name: String?
    ) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let response = try await APIService.shared.appleSignIn(
                identityToken: identityToken,
                nonce: nonce,
                authorizationCode: authorizationCode,
                name: name
            )
            if let appleUserId = KeychainHelper.load(forKey: KeychainHelper.appleUserIdKey) {
                // Already stored — keep it (re-sign-in)
                _ = appleUserId
            }
            persistSession(response)
            isAuthenticated = true
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
        Task {
            await APIService.shared.serverLogout()
        }
        SocketService.shared.disconnect()
        KeychainHelper.clearAll()
        currentUser = nil
        isAuthenticated = false
    }

    func deleteAccount() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await APIService.shared.deleteAccount()
            SocketService.shared.disconnect()
            KeychainHelper.clearAll()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func handleUnauthorized() {
        SocketService.shared.disconnect()
        KeychainHelper.clearAll()
        currentUser = nil
        isAuthenticated = false
        errorMessage = "Sitzung abgelaufen. Bitte melde dich erneut an."
    }

    private func persistSession(_ response: AuthResponse) {
        KeychainHelper.save(response.token, forKey: KeychainHelper.tokenKey)

        if let refreshToken = response.refreshToken {
            KeychainHelper.save(refreshToken, forKey: KeychainHelper.refreshTokenKey)
        }

        KeychainHelper.save(String(response.user.id), forKey: KeychainHelper.userIdKey)
        KeychainHelper.save(response.user.name, forKey: KeychainHelper.userNameKey)

        if let email = response.user.email {
            KeychainHelper.save(email, forKey: KeychainHelper.userEmailKey)
        } else {
            KeychainHelper.delete(forKey: KeychainHelper.userEmailKey)
        }

        currentUser = response.user
        requestPushPermissionIfNeeded()
        SocketService.shared.connect(token: response.token, partnershipId: nil)
    }

    private func requestPushPermissionIfNeeded() {
        Task {
            let center = UNUserNotificationCenter.current()
            let settings = await center.notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            case .notDetermined:
                let granted = try? await center.requestAuthorization(options: [.alert, .badge, .sound])
                if granted == true {
                    await MainActor.run {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            default:
                break
            }
        }
    }
}
