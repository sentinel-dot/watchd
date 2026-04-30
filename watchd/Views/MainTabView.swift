import SwiftUI
import UIKit

// Root-Shell der authentifizierten App: drei Tabs (Räume / Favoriten / Profil),
// jeder mit eigener NavigationStack. Immersive Screens (SwipeView, MatchView)
// blenden die TabBar via `.toolbar(.hidden, for: .tabBar)` aus.

struct MainTabView: View {
    @Environment(\.theme) private var theme
    @State private var selectedTab: MainTab = .partners
    @State private var partnerTabNeedsAttention = false

    init() {
        Self.applyTabBarAppearance(for: .velvetHour)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PartnersView()
            }
            .tabItem {
                Label("Partner", systemImage: "person.2.fill")
            }
            .badge(partnerTabNeedsAttention ? Text("!") : nil)
            .tag(MainTab.partners)

            NavigationStack {
                FavoritesListView()
            }
            .tabItem {
                Label("Favoriten", systemImage: "star.fill")
            }
            .tag(MainTab.favorites)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profil", systemImage: "person.crop.circle.fill")
            }
            .tag(MainTab.profile)
        }
        .tint(theme.colors.accent)
        .onAppear {
            AppNavigation.consumePendingNavigation()
        }
        .onChange(of: selectedTab) { _, tab in
            if tab == .partners {
                partnerTabNeedsAttention = false
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchdOpenPartnersTab)) { notification in
            let shouldMark = notification.userInfo?["markNeedsAttention"] as? Bool ?? false
            let wasShowingPartners = selectedTab == .partners
            selectedTab = .partners
            partnerTabNeedsAttention = shouldMark && !wasShowingPartners
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchdPartnersTabNeedsAttention)) { _ in
            if selectedTab != .partners {
                partnerTabNeedsAttention = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .watchdOpenPartnership)) { _ in
            selectedTab = .partners
        }
    }

    private enum MainTab: Hashable {
        case partners
        case favorites
        case profile
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
