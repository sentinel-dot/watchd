import SwiftUI

struct ArchivedRoomsView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var viewModel = ArchivedRoomsViewModel()

    var body: some View {
        ZStack {
            theme.colors.base.ignoresSafeArea()

            if viewModel.isLoading && viewModel.archivedRooms.isEmpty && !viewModel.hasLoadedOnce {
                ProgressView()
                    .progressViewStyle(.circular)
                    .tint(theme.colors.accent)
                    .scaleEffect(1.1)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.archivedRooms.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(Array(viewModel.archivedRooms.enumerated()), id: \.element.id) { index, room in
                            ArchivedRoomRow(
                                room: room,
                                ordinal: index + 1,
                                onDelete: {
                                    Task { await viewModel.deleteFromArchive(room: room) }
                                }
                            )

                            if index < viewModel.archivedRooms.count - 1 {
                                Rectangle()
                                    .fill(theme.colors.separator)
                                    .frame(height: 1)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.bottom, 40)
                }
            }
        }
        .navigationTitle("Archiv")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(theme.colors.base, for: .navigationBar)
        .task {
            await viewModel.loadArchivedRooms()
        }
        .refreshable {
            await viewModel.loadArchivedRooms()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Noch kein Archiv.")
                .font(theme.fonts.titleMedium)
                .foregroundColor(theme.colors.textPrimary)

            Text("Räume, die du beendet hast,\nlegen sich hier ab.")
                .font(theme.fonts.bodyRegular)
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 28)
        .padding(.top, 48)
    }
}

@MainActor
final class ArchivedRoomsViewModel: ObservableObject {
    @Published var archivedRooms: [Room] = []
    @Published var isLoading = false
    @Published var hasLoadedOnce = false

    func loadArchivedRooms() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await APIService.shared.getRooms()
            archivedRooms = response.rooms.filter { $0.status == "dissolved" }
            hasLoadedOnce = true
        } catch is CancellationError {
            return
        } catch let error as URLError where error.code == .cancelled {
            return
        } catch {
            hasLoadedOnce = true
        }
    }

    func deleteFromArchive(room: Room) async {
        archivedRooms.removeAll { $0.id == room.id }
        do {
            try await APIService.shared.deleteFromArchive(roomId: room.id)
        } catch {
            archivedRooms.insert(room, at: 0)
        }
    }
}

// MARK: - Editorial archived row

private struct ArchivedRoomRow: View {
    @Environment(\.theme) private var theme
    let room: Room
    let ordinal: Int
    let onDelete: () -> Void

    @State private var showDeleteConfirm = false

    private var displayName: String {
        if let name = room.name, !name.isEmpty { return name }
        return "Unbenannter Raum"
    }

    private var ordinalString: String {
        String(format: "Nº %02d", ordinal)
    }

    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: room.createdAt) else { return "" }
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .none
        displayFormatter.locale = Locale(identifier: "de_DE")
        return displayFormatter.string(from: date)
    }

    var body: some View {
        NavigationLink {
            MatchesListView(roomId: room.id)
        } label: {
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
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(theme.colors.textTertiary)
                            .frame(width: 6, height: 6)
                        Text("Archiviert")
                            .font(theme.fonts.microCaption)
                            .tracking(1.0)
                            .textCase(.uppercase)
                            .foregroundColor(theme.colors.textSecondary)

                        if !formattedDate.isEmpty {
                            Text("·")
                                .foregroundColor(theme.colors.textTertiary)
                            Text(formattedDate)
                                .font(theme.fonts.microCaption)
                                .tracking(1.0)
                                .textCase(.uppercase)
                                .foregroundColor(theme.colors.textTertiary)
                        }
                    }

                    HStack(spacing: 6) {
                        Text("Code")
                            .font(theme.fonts.microCaption)
                            .tracking(1.0)
                            .textCase(.uppercase)
                            .foregroundColor(theme.colors.textTertiary)
                        Text(room.code)
                            .font(theme.fonts.body(size: 13, weight: .semibold))
                            .tracking(1.4)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 22)
            .contentShape(Rectangle())
            .opacity(0.75)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(displayName), archiviert")
        .accessibilityAddTraits(.isButton)
        .contextMenu {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Aus Archiv löschen", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Löschen", systemImage: "trash")
            }
        }
        .confirmationDialog(
            "Aus Archiv löschen?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Löschen", role: .destructive) { onDelete() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Der Raum verschwindet aus deiner Archivliste. Die Matches bleiben.")
        }
    }
}

#Preview {
    NavigationStack {
        ArchivedRoomsView()
            .environmentObject(AuthViewModel.shared)
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}
