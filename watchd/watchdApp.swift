import SwiftUI

@main
struct watchdApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
