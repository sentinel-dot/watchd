import SwiftUI
import UIKit
import UserNotifications
import GoogleSignIn

@main
struct watchdApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var networkMonitor = NetworkMonitor()

    init() {
        FontRegistry.registerAll()
        Self.applyNavigationBarAppearance(for: .velvetHour)
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(clientID: APIConfig.googleClientId)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
                .environment(\.theme, .velvetHour)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    // Google Sign-In redirect (e.g. from the Google app)
                    if GIDSignIn.sharedInstance.handle(url) { return }
                    handleDeepLink(url)
                }
        }
    }

    private static func applyNavigationBarAppearance(for theme: Theme) {
        let accent = UIColor(theme.colors.accent)
        let base = UIColor(theme.colors.base)
        let text = UIColor(theme.colors.textPrimary)

        UINavigationBar.appearance().tintColor = accent
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: text]
        UINavigationBar.appearance().barTintColor = base
        UINavigationBar.appearance().backgroundColor = base
    }

    // Handles watchd:// custom URL scheme
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "watchd" else { return }

        if url.host == "reset-password", let token = url.queryParameters?["token"] {
            postResetPasswordNotification(token: token)
            return
        }

        if let code = addPartnerCode(from: url) {
            handleAddPartnerCode(code)
        }
    }

    private func postResetPasswordNotification(token: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name("showResetPassword"),
            object: nil,
            userInfo: ["token": token]
        )
    }

    private func handleAddPartnerCode(_ rawCode: String) {
        guard AppNavigation.normalizedShareCode(from: rawCode) != nil else { return }
        AppNavigation.queueAddPartnerCode(rawCode)
        if authViewModel.isAuthenticated {
            AppNavigation.openPartnersTab()
        }
    }

    private func addPartnerCode(from url: URL) -> String? {
        if url.scheme == "watchd" {
            guard url.host == "add" else { return nil }
            if let code = url.pathComponents.dropFirst().first, !code.isEmpty {
                return code
            }
            return url.queryParameters?["code"]
        }

        let parts = url.pathComponents.filter { $0 != "/" }
        guard parts.first == "add", parts.count >= 2 else { return nil }
        return parts[1]
    }
}

extension URL {
    var queryParameters: [String: String]? {
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else { return nil }
        var params = [String: String]()
        for item in queryItems {
            params[item.name] = item.value
        }
        return params
    }
}
