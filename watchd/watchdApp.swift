import SwiftUI
import UIKit

@main
struct watchdApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    init() {
        UINavigationBar.appearance().tintColor = UIColor(red: 0.85, green: 0.30, blue: 0.25, alpha: 1)
        UINavigationBar.appearance().titleTextAttributes = [.foregroundColor: UIColor(red: 0.15, green: 0.15, blue: 0.15, alpha: 1)]
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.light)
        }
    }
}
