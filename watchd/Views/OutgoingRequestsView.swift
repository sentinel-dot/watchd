import SwiftUI

// Overflow: alle ausstehenden Partnerschafts-Anfragen, die du gesendet hast.

struct OutgoingRequestsView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var viewModel: PartnersViewModel

    var body: some View {
        ZStack {
            theme.colors.base.ignoresSafeArea()

            if viewModel.outgoing.isEmpty {
                VStack(spacing: 14) {
                    Text("Keine ausstehenden Anfragen.")
                        .font(theme.fonts.titleMedium)
                        .foregroundColor(theme.colors.textPrimary)
                    Text("Wenn du jemandem eine Anfrage schickst, siehst du sie hier bis sie angenommen wird.")
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
                        ForEach(Array(viewModel.outgoing.enumerated()), id: \.element.id) { index, partnership in
                            PendingRequestOutgoingCard(
                                partnership: partnership,
                                onCancel: {
                                    Task { await viewModel.cancelRequest(id: partnership.id) }
                                }
                            )

                            if index < viewModel.outgoing.count - 1 {
                                Rectangle()
                                    .fill(theme.colors.separator)
                                    .frame(height: 1)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                    .opacity(0.85)
                }
            }
        }
        .navigationTitle("Ausstehend")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(theme.colors.base, for: .navigationBar)
    }
}

#Preview {
    NavigationStack {
        OutgoingRequestsView(viewModel: PartnersViewModel())
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}
