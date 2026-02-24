import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authVM: AuthViewModel

    var body: some View {
        Group {
            if authVM.isAuthenticated {
                NavigationStack {
                    HomeView()
                }
                .transition(.opacity)
            } else {
                AuthView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authVM.isAuthenticated)
    }
}
