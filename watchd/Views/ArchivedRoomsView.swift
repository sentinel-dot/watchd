import SwiftUI

struct ArchivedRoomsView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var viewModel = ArchivedRoomsViewModel()
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.94),
                    Color(red: 0.96, green: 0.93, blue: 0.90)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                if viewModel.isLoading && viewModel.archivedRooms.isEmpty {
                    LoadingView(message: "Archivierte Rooms werden geladen...")
                } else if viewModel.archivedRooms.isEmpty {
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.9, green: 0.88, blue: 0.86))
                                .frame(width: 100, height: 100)
                            Image(systemName: "archivebox")
                                .font(.system(size: 44, weight: .light))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        }
                        
                        VStack(spacing: 6) {
                            Text("Keine archivierten Rooms")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                            Text("Beendete Rooms erscheinen hier")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        }
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.archivedRooms) { room in
                                ArchivedRoomCard(room: room)
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.top, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
        }
        .navigationTitle("Archivierte Rooms")
        .navigationBarTitleDisplayMode(.large)
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
        } catch {
            // Silent error for now
        }
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    if let name = room.name, !name.isEmpty {
                        Text(name)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    } else {
                        Text("Room #\(room.id)")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    }
                    
                    Text("Code: \(room.code)")
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    
                    HStack(spacing: 4) {
                        Image(systemName: "archivebox")
                            .font(.system(size: 11, weight: .medium))
                        Text("Archiviert")
                            .font(.system(size: 12, weight: .medium))
                    }
                    .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
                    .padding(.top, 2)
                    
                    if !formattedDate.isEmpty {
                        Text("Erstellt am \(formattedDate)")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Color(red: 0.6, green: 0.6, blue: 0.6))
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
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.6))
                .shadow(color: Color.black.opacity(0.04), radius: 12, y: 4)
        )
    }
}

#Preview {
    NavigationStack {
        ArchivedRoomsView()
            .environmentObject(AuthViewModel())
    }
}
