import SwiftUI
import UIKit
import UserNotifications

@main
struct watchdApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var networkMonitor = NetworkMonitor()

    init() {
        FontRegistry.registerAll()
        Self.applyNavigationBarAppearance(for: .velvetHour)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
                .environment(\.theme, .velvetHour)
                .preferredColorScheme(.dark)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    guard let url = activity.webpageURL else { return }
                    handleUniversalLink(url)
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

    // Handles watchd:// custom URL scheme (reset-password; add-partner kommt in Phase 8)
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "watchd" else { return }

        if url.host == "reset-password", let token = url.queryParameters?["token"] {
            postResetPasswordNotification(token: token)
        }
    }

    // Handles https:// Universal Links
    private func handleUniversalLink(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
        if components.path == "/reset-password",
           let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
           !token.isEmpty {
            postResetPasswordNotification(token: token)
        }
    }

    private func postResetPasswordNotification(token: String) {
        NotificationCenter.default.post(
            name: NSNotification.Name("showResetPassword"),
            object: nil,
            userInfo: ["token": token]
        )
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
