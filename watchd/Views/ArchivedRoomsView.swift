import SwiftUI

struct ArchivedRoomsView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var viewModel = ArchivedRoomsViewModel()

    var body: some View {
        ZStack {
            WatchdTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.archivedRooms.isEmpty {
                    LoadingView(message: "Archivierte Rooms werden geladen...")
                } else if viewModel.archivedRooms.isEmpty {
                    VStack(spacing: 24) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 56, weight: .light))
                            .foregroundColor(WatchdTheme.textTertiary)

                        VStack(spacing: 8) {
                            Text("Keine archivierten Rooms")
                                .font(WatchdTheme.titleSmall())
                                .foregroundColor(WatchdTheme.textPrimary)
                            Text("Beendete Rooms erscheinen hier")
                                .font(WatchdTheme.caption())
                                .foregroundColor(WatchdTheme.textSecondary)
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(viewModel.archivedRooms) { room in
                                ArchivedRoomCard(room: room)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle("Archivierte Rooms")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(WatchdTheme.background, for: .navigationBar)
        .task {
            await viewModel.loadArchivedRooms()
        }
        .refreshable {
            await viewModel.loadArchivedRooms()
        }
    }
}

@MainActor
final class ArchivedRoomsViewModel: ObservableObject {
    @Published var archivedRooms: [Room] = []
    @Published var isLoading = false

    func loadArchivedRooms() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await APIService.shared.getRooms()
            archivedRooms = response.rooms.filter { $0.status == "dissolved" }
        } catch {}
    }
}

private struct ArchivedRoomCard: View {
    let room: Room

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
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let name = room.name, !name.isEmpty {
                        Text(name)
                            .font(WatchdTheme.titleSmall())
                            .foregroundColor(WatchdTheme.textPrimary)
                    } else {
                        Text("Room #\(room.id)")
                            .font(WatchdTheme.titleSmall())
                            .foregroundColor(WatchdTheme.textPrimary)
                    }

                    Text("Code: \(room.code)")
                        .font(WatchdTheme.captionMedium())
                        .foregroundColor(WatchdTheme.textTertiary)

                    HStack(spacing: 4) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 11, weight: .medium))
                        Text("Archiviert")
                            .font(WatchdTheme.captionMedium())
                    }
                    .foregroundColor(WatchdTheme.textTertiary)
                    .padding(.top, 2)

                    if !formattedDate.isEmpty {
                        Text("Erstellt am \(formattedDate)")
                            .font(WatchdTheme.labelUppercase())
                            .foregroundColor(WatchdTheme.textTertiary)
                    }
                }

                Spacer()
            }

            NavigationLink {
                MatchesListView(roomId: room.id)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Matches anzeigen")
                        .font(WatchdTheme.captionMedium())
                }
                .foregroundColor(WatchdTheme.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(WatchdTheme.primary.opacity(0.2))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(18)
        .background(WatchdTheme.backgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(WatchdTheme.separator, lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        ArchivedRoomsView()
            .environmentObject(AuthViewModel())
    }
    .preferredColorScheme(.dark)
}
