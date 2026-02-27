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
                .tint(Color(red: 0.85, green: 0.30, blue: 0.25))
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
