import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var showResetPassword = false
    @State private var resetToken: String?

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                NavigationStack {
                    HomeView()
                }
                .tint(WatchdTheme.primary)
                .transition(.opacity)
            } else {
                AuthView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("showResetPassword"))) { notification in
            if let token = notification.userInfo?["token"] as? String {
                resetToken = token
                showResetPassword = true
            }
        }
        .sheet(isPresented: $showResetPassword) {
            if let token = resetToken {
                ResetPasswordView(token: token)
            }
        }
    }
}
