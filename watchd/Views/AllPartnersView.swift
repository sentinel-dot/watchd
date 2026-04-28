import SwiftUI

// Overflow: alle aktiven Partner als kompakte Liste mit Tap-to-Swipe.

struct AllPartnersView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var viewModel: PartnersViewModel

    @State private var partnershipForFilters: Partnership?
    @State private var partnershipToDelete: Partnership?
    @State private var navigationPartnership: Partnership?
    @State private var showRemoveConfirm = false

    var body: some View {
        ZStack {
            theme.colors.base.ignoresSafeArea()

            if viewModel.active.isEmpty {
                VStack(spacing: 14) {
                    Text("Noch keinen Partner.")
                        .font(theme.fonts.titleMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Teile deinen Code im Profil oder gib den Code von jemand anderem ein.")
                        .font(theme.fonts.bodyRegular)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.active.enumerated()), id: \.element.id) { index, partnership in
                            PartnerCard(
                                partnership: partnership,
                                ordinal: index + 1,
                                onTap: { navigationPartnership = partnership },
                                onEditFilters: { partnershipForFilters = partnership },
                                onRemove: {
                                    partnershipToDelete = partnership
                                    showRemoveConfirm = true
                                }
                            )

                            if index < viewModel.active.count - 1 {
                                Rectangle()
                                    .fill(theme.colors.separator)
                                    .frame(height: 1)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Partner")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(theme.colors.base, for: .navigationBar)
        .navigationDestination(item: $navigationPartnership) { partnership in
            SwipeView(partnership: partnership)
        }
        .sheet(item: $partnershipForFilters) { partnership in
            PartnerFiltersView(
                partnershipId: partnership.id,
                partnerName: partnership.partner?.name ?? "Partner",
                currentFilters: partnership.filters
            )
        }
        .alert(
            "Partner entfernen?",
            isPresented: $showRemoveConfirm,
            presenting: partnershipToDelete
        ) { partnership in
            Button("Abbrechen", role: .cancel) {}
            Button("Entfernen", role: .destructive) {
                Task { await viewModel.deletePartnership(id: partnership.id) }
            }
        } message: { partnership in
            Text("Wenn du \(partnership.partner?.name ?? "diesen Partner") entfernst, gehen eure gemeinsamen Matches verloren. Favoriten bleiben dir erhalten.")
        }
    }
}

#Preview {
    NavigationStack {
        AllPartnersView(viewModel: PartnersViewModel())
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}
