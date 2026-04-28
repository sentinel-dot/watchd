import SwiftUI

// Partners-Tab (ehemals RoomsView). Section-List:
//   • Eingehende Anfragen (cond)
//   • Partner (immer, mit Empty-State)
//   • Ausstehende Anfragen (cond, gedimmt)

struct PartnersView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @StateObject private var viewModel = PartnersViewModel()

    @State private var showAddPartnerSheet = false
    @State private var partnershipForFilters: Partnership?
    @State private var partnershipToDelete: Partnership?
    @State private var navigationPartnership: Partnership?
    @State private var showRemoveConfirm = false

    var body: some View {
        ZStack(alignment: .top) {
            theme.colors.base.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading && !viewModel.hasLoadedOnce {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(theme.colors.accent)
                        .scaleEffect(1.1)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if !viewModel.incoming.isEmpty {
                                incomingSection
                                    .padding(.bottom, 32)
                            }

                            partnersSection
                                .padding(.bottom, 32)

                            if !viewModel.outgoing.isEmpty {
                                outgoingSection
                                    .padding(.bottom, 32)
                            }
                        }
                        .padding(.bottom, 200)
                    }
                    .refreshable {
                        await viewModel.loadPartnerships()
                    }
                }
            }

            if !networkMonitor.isConnected {
                OfflineBanner()
                    .animation(.spring(), value: networkMonitor.isConnected)
            }

            VStack {
                Spacer()
                bottomActions
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .navigationDestination(item: $navigationPartnership) { partnership in
            SwipeView(partnership: partnership)
        }
        .sheet(isPresented: $showAddPartnerSheet) {
            AddPartnerSheet { _ in
                Task { await viewModel.loadPartnerships(animated: false) }
            }
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
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "Etwas ist schiefgelaufen.")
        }
        .task {
            await viewModel.loadPartnerships()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Guten Abend,")
                .font(theme.fonts.bodyRegular)
                .foregroundColor(theme.colors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(authVM.currentUser?.name ?? "du")
                    .font(theme.fonts.displayHero)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }

    // MARK: - Incoming Section

    private var incomingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Eingehende Anfragen", count: viewModel.incoming.count)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.incoming.prefix(3).enumerated()), id: \.element.id) { index, partnership in
                    PendingRequestIncomingCard(
                        partnership: partnership,
                        onAccept: {
                            Task { await viewModel.acceptRequest(id: partnership.id) }
                        },
                        onDecline: {
                            Task { await viewModel.declineRequest(id: partnership.id) }
                        }
                    )

                    if index < min(viewModel.incoming.count, 3) - 1 {
                        Rectangle()
                            .fill(theme.colors.separator)
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                    }
                }
            }

            if viewModel.incoming.count > 3 {
                NavigationLink {
                    PendingRequestsView(viewModel: viewModel)
                } label: {
                    overflowLink(text: "Alle \(viewModel.incoming.count) anzeigen")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Partners Section

    private var partnersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Partner", count: viewModel.active.count)

            if viewModel.active.isEmpty {
                emptyPartnersState
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(viewModel.active.prefix(3).enumerated()), id: \.element.id) { index, partnership in
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

                        if index < min(viewModel.active.count, 3) - 1 {
                            Rectangle()
                                .fill(theme.colors.separator)
                                .frame(height: 1)
                                .padding(.horizontal, 24)
                        }
                    }
                }

                if viewModel.active.count > 3 {
                    NavigationLink {
                        AllPartnersView(viewModel: viewModel)
                    } label: {
                        overflowLink(text: "Alle \(viewModel.active.count) anzeigen")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var emptyPartnersState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Noch keinen Partner.")
                .font(theme.fonts.titleMedium)
                .foregroundColor(theme.colors.textPrimary)

            Text("Teile deinen Code im Profil oder gib den Code von jemand anderem ein.")
                .font(theme.fonts.bodyRegular)
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    // MARK: - Outgoing Section

    private var outgoingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader(title: "Ausstehend", count: viewModel.outgoing.count, dimmed: true)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.outgoing.prefix(3).enumerated()), id: \.element.id) { index, partnership in
                    PendingRequestOutgoingCard(
                        partnership: partnership,
                        onCancel: {
                            Task { await viewModel.cancelRequest(id: partnership.id) }
                        }
                    )

                    if index < min(viewModel.outgoing.count, 3) - 1 {
                        Rectangle()
                            .fill(theme.colors.separator)
                            .frame(height: 1)
                            .padding(.horizontal, 24)
                    }
                }
            }
            .opacity(0.7)

            if viewModel.outgoing.count > 3 {
                NavigationLink {
                    OutgoingRequestsView(viewModel: viewModel)
                } label: {
                    overflowLink(text: "Alle \(viewModel.outgoing.count) anzeigen")
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Section Helpers

    private func sectionHeader(title: String, count: Int, dimmed: Bool = false) -> some View {
        HStack(spacing: 10) {
            Text(title)
                .font(theme.fonts.microCaption)
                .tracking(1.6)
                .textCase(.uppercase)
                .foregroundColor(dimmed ? theme.colors.textTertiary : theme.colors.textSecondary)
            if count > 0 {
                Text("\(count)")
                    .font(theme.fonts.microCaption)
                    .tracking(1.0)
                    .foregroundColor(theme.colors.textTertiary)
            }
        }
        .padding(.horizontal, 24)
    }

    private func overflowLink(text: String) -> some View {
        HStack(spacing: 6) {
            Text(text)
                .font(theme.fonts.body(size: 13, weight: .medium))
                .foregroundColor(theme.colors.textSecondary)
            Image(systemName: "arrow.right")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(theme.colors.textTertiary)
        }
        .padding(.horizontal, 24)
        .padding(.top, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bottom CTA

    private var bottomActions: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [theme.colors.base.opacity(0), theme.colors.base],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)

            Button {
                showAddPartnerSheet = true
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Partner hinzufügen")
                        .font(theme.fonts.bodyMedium)
                }
                .foregroundColor(theme.colors.textOnAccent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(theme.colors.primaryButtonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
            .background(theme.colors.base)
        }
    }
}

// MARK: - Partner Card (active)

struct PartnerCard: View {
    @Environment(\.theme) private var theme
    let partnership: Partnership
    let ordinal: Int
    let onTap: () -> Void
    let onEditFilters: () -> Void
    let onRemove: () -> Void

    private var displayName: String {
        partnership.partner?.name ?? "Partner"
    }

    private var ordinalString: String {
        String(format: "Nº %02d", ordinal)
    }

    private var lastActivityLabel: String {
        guard let lastActivity = partnership.lastActivityAt,
              let date = ISO8601DateFormatter().date(from: lastActivity) else {
            return "Noch keine Aktivität"
        }
        let interval = Date().timeIntervalSince(date)
        switch interval {
        case ..<60: return "gerade aktiv"
        case 60..<3600: return "vor \(Int(interval / 60)) Min"
        case 3600..<86_400: return "vor \(Int(interval / 3600)) Std"
        case 86_400..<604_800: return "vor \(Int(interval / 86_400)) T"
        default: return "länger inaktiv"
        }
    }

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 18) {
                Text(ordinalString)
                    .font(theme.fonts.display(size: 22, weight: .regular))
                    .foregroundColor(theme.colors.textTertiary)
                    .frame(minWidth: 48, alignment: .leading)
                    .padding(.top, 4)

                VStack(alignment: .leading, spacing: 8) {
                    Text(displayName)
                        .font(theme.fonts.titleMedium)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(theme.colors.success)
                            .frame(width: 6, height: 6)
                        Text(lastActivityLabel)
                            .font(theme.fonts.microCaption)
                            .tracking(1.0)
                            .textCase(.uppercase)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(displayName), aktiv")
        .accessibilityAddTraits(.isButton)
        .contextMenu {
            Button {
                onEditFilters()
            } label: {
                Label("Filter ändern", systemImage: "slider.horizontal.3")
            }
            Button(role: .destructive) {
                onRemove()
            } label: {
                Label("Partner entfernen", systemImage: "person.crop.circle.badge.xmark")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onRemove) {
                Label("Entfernen", systemImage: "person.crop.circle.badge.xmark")
            }
            Button(action: onEditFilters) {
                Label("Filter", systemImage: "slider.horizontal.3")
            }
            .tint(theme.colors.textSecondary)
        }
    }
}

// MARK: - Pending Request Cards

struct PendingRequestIncomingCard: View {
    @Environment(\.theme) private var theme
    let partnership: Partnership
    let onAccept: () -> Void
    let onDecline: () -> Void

    private var name: String { partnership.partner?.name ?? "Unbekannt" }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(theme.fonts.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(1)

                Text("möchte dich als Partner adden")
                    .font(theme.fonts.microCaption)
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundColor(theme.colors.textTertiary)
            }

            Spacer(minLength: 8)

            HStack(spacing: 10) {
                Button(action: onDecline) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .overlay(
                            Circle().stroke(theme.colors.separator, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ablehnen")

                Button(action: onAccept) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(theme.colors.textOnAccent)
                        .frame(width: 36, height: 36)
                        .background(theme.colors.accent)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Annehmen")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }
}

struct PendingRequestOutgoingCard: View {
    @Environment(\.theme) private var theme
    let partnership: Partnership
    let onCancel: () -> Void

    private var name: String { partnership.partner?.name ?? "Unbekannt" }

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(name)
                    .font(theme.fonts.bodyMedium)
                    .foregroundColor(theme.colors.textPrimary)
                    .lineLimit(1)

                Text("wartet auf Antwort")
                    .font(theme.fonts.microCaption)
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundColor(theme.colors.textTertiary)
            }

            Spacer(minLength: 8)

            Button(action: onCancel) {
                Text("Zurückziehen")
                    .font(theme.fonts.microCaption)
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundColor(theme.colors.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .overlay(
                        Capsule().stroke(theme.colors.separator, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Anfrage zurückziehen")
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 18)
    }
}

#Preview {
    NavigationStack {
        PartnersView()
            .environmentObject(AuthViewModel.shared)
            .environmentObject(NetworkMonitor())
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}
