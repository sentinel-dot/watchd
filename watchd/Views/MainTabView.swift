import SwiftUI
import UIKit

// Root-Shell der authentifizierten App: drei Tabs (Räume / Favoriten / Profil),
// jeder mit eigener NavigationStack. Immersive Screens (SwipeView, MatchView)
// blenden die TabBar via `.toolbar(.hidden, for: .tabBar)` aus.

struct MainTabView: View {
    @Environment(\.theme) private var theme

    init() {
        Self.applyTabBarAppearance(for: .velvetHour)
    }

    var body: some View {
        TabView {
            NavigationStack {
                PartnersView()
            }
            .tabItem {
                Label("Partner", systemImage: "person.2.fill")
            }

            NavigationStack {
                FavoritesListView()
            }
            .tabItem {
                Label("Favoriten", systemImage: "star.fill")
            }

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.crop.circle.fill")
            }
        }
        .tint(theme.colors.accent)
    }

    private static func applyTabBarAppearance(for theme: Theme) {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(theme.colors.base).withAlphaComponent(0.85)
        appearance.shadowColor = UIColor(theme.colors.separator)

        let accent = UIColor(theme.colors.accent)
        let inactive = UIColor(theme.colors.textTertiary)

        appearance.stackedLayoutAppearance.normal.iconColor = inactive
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [.foregroundColor: inactive]
        appearance.stackedLayoutAppearance.selected.iconColor = accent
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [.foregroundColor: accent]

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

#Preview {
    MainTabView()
        .environmentObject(AuthViewModel.shared)
        .environmentObject(NetworkMonitor())
        .environment(\.theme, .velvetHour)
        .preferredColorScheme(.dark)
}
