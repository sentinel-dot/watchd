import SwiftUI
import UIKit

@main
struct watchdApp: App {
    @StateObject private var authViewModel = AuthViewModel.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var pendingRoomCode: String?

    init() {
        UINavigationBar.appearance().tintColor = UIColor(red: 0.85, green: 0.30, blue: 0.25, alpha: 1)
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)]
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .environmentObject(networkMonitor)
                .preferredColorScheme(.light)
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }
    
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
            NotificationCenter.default.post(
                name: NSNotification.Name("showResetPassword"),
                object: nil,
                userInfo: ["token": token]
            )
        }
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
