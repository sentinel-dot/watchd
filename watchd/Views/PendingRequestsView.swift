import SwiftUI

// Overflow: alle eingehenden Partnerschaft-Anfragen.

struct PendingRequestsView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var viewModel: PartnersViewModel

    var body: some View {
        ZStack {
            theme.colors.base.ignoresSafeArea()

            if viewModel.incoming.isEmpty {
                VStack(spacing: 14) {
                    Text("Keine offenen Anfragen.")
                        .font(theme.fonts.titleMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Sobald jemand deinen Code eingibt, taucht die Anfrage hier auf.")
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
                        ForEach(Array(viewModel.incoming.enumerated()), id: \.element.id) { index, partnership in
                            PendingRequestIncomingCard(
                                partnership: partnership,
                                onAccept: {
                                    Task { await viewModel.acceptRequest(id: partnership.id) }
                                },
                                onDecline: {
                                    Task { await viewModel.declineRequest(id: partnership.id) }
                                }
                            )

                            if index < viewModel.incoming.count - 1 {
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
        .navigationTitle("Anfragen")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(theme.colors.base, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        PendingRequestsView(viewModel: PartnersViewModel())
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}
