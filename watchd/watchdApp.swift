import SwiftUI
import UIKit
import UserNotifications

@main
struct watchdApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var pendingRoomCode: String?

    init() {
        let netflixRed = UIColor(red: 0.898, green: 0.035, blue: 0.078, alpha: 1)
        UINavigationBar.appearance().tintColor = netflixRed
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().barTintColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
        UINavigationBar.appearance().backgroundColor = UIColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
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

    // Handles watchd:// custom URL scheme (join links, legacy reset-password links)
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "watchd" else { return }

        if url.host == "join" || url.pathComponents.contains("join") {
            let code = url.pathComponents.last?.uppercased() ?? ""
            if !code.isEmpty && code.count == 6 {
                if authViewModel.isAuthenticated {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("joinRoomFromDeepLink"),
                        object: nil,
                        userInfo: ["code": code]
                    )
                } else {
                    pendingRoomCode = code
                }
            }
        } else if url.host == "reset-password", let token = url.queryParameters?["token"] {
            postResetPasswordNotification(token: token)
        }
    }

    // Handles https:// Universal Links (e.g. https://watchd.up.railway.app/reset-password?token=…)
    // iOS intercepts these before opening Safari when the Associated Domains entitlement is configured.
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
