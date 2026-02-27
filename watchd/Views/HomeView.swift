import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @StateObject private var viewModel = HomeViewModel()
    @State private var showJoinSheet = false

    var body: some View {
        ZStack(alignment: .top) {
            WatchdTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading && viewModel.rooms.isEmpty {
                    Spacer()
                    LoadingView(message: "Rooms werden geladen...")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            if viewModel.rooms.isEmpty {
                                emptyRooms
                            } else {
                                ForEach(Array(viewModel.rooms.enumerated()), id: \.element.id) { index, room in
                                    RoomCard(
                                        room: room,
                                        userRoomNumber: index + 1,
                                        onTap: { viewModel.selectRoom(room) },
                                        onEditFilters: { viewModel.showFiltersForRoom = room },
                                        onRename: {
                                            viewModel.roomToRename = room
                                            viewModel.renameRoomName = room.name ?? ""
                                        },
                                        onLeave: {
                                            viewModel.roomToLeave = room
                                            viewModel.showLeaveConfirmation = true
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 160)
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
        .navigationDestination(isPresented: $viewModel.navigateToSwipe) {
            if let room = viewModel.selectedRoom {
                SwipeView(room: room)
            }
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinRoomSheet(viewModel: viewModel, isPresented: $showJoinSheet)
        }
        .sheet(isPresented: $viewModel.showCreateRoomSheet) {
            CreateRoomSheet(viewModel: viewModel, isPresented: $viewModel.showCreateRoomSheet)
        }
        .sheet(isPresented: $viewModel.showUpgradeAccount) {
            UpgradeAccountView()
        }
        .sheet(isPresented: Binding(
            get: { viewModel.showFiltersForRoom != nil },
            set: { if !$0 { viewModel.showFiltersForRoom = nil } }
        )) {
            if let room = viewModel.showFiltersForRoom {
                RoomFiltersView(roomId: room.id, currentFilters: room.filters)
            }
        }
        .sheet(isPresented: Binding(
            get: { viewModel.roomToRename != nil },
            set: { if !$0 { viewModel.roomToRename = nil } }
        )) {
            if let room = viewModel.roomToRename {
                RenameRoomSheet(
                    room: room,
                    name: $viewModel.renameRoomName,
                    onSave: {
                        Task {
                            await viewModel.updateRoomName(roomId: room.id, name: viewModel.renameRoomName.trimmingCharacters(in: .whitespacesAndNewlines))
                        }
                    },
                    onDismiss: {
                        viewModel.roomToRename = nil
                        viewModel.renameRoomName = ""
                    }
                )
            }
        }
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "Etwas ist schiefgelaufen.")
        }
        .alert("Room verlassen?", isPresented: $viewModel.showLeaveConfirmation) {
            Button("Abbrechen", role: .cancel) {}
            Button("Verlassen", role: .destructive) {
                if let room = viewModel.roomToLeave {
                    Task {
                        await viewModel.leaveRoom(room)
                    }
                }
            }
        } message: {
            Text("Du kannst jederzeit über den Code oder Invite-Link zurückkommen.")
        }
        .task {
            await viewModel.loadRooms()
        }
        .refreshable {
            await viewModel.loadRooms()
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Hallo,")
                    .font(WatchdTheme.body())
                    .foregroundColor(WatchdTheme.textSecondary)

                Text(authVM.currentUser?.name ?? "du")
                    .font(WatchdTheme.titleLarge())
                    .foregroundColor(WatchdTheme.textPrimary)

                if let user = authVM.currentUser, user.isGuest {
                    Text("Gast-Modus")
                        .font(WatchdTheme.captionMedium())
                        .foregroundColor(WatchdTheme.primary)
                        .padding(.top, 2)
                }
            }
            Spacer()

            Menu {
                if let user = authVM.currentUser, user.isGuest {
                    Button(action: { viewModel.showUpgradeAccount = true }) {
                        Label("Konto erstellen", systemImage: "arrow.up.circle")
                    }
                }
                NavigationLink {
                    FavoritesListView()
                } label: {
                    Label("Favoriten", systemImage: "star")
                }
                NavigationLink {
                    ArchivedRoomsView()
                } label: {
                    Label("Archivierte Rooms", systemImage: "archivebox")
                }
                Button(action: { authVM.logout() }) {
                    Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(WatchdTheme.textPrimary)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 24)
    }

    private var emptyRooms: some View {
        VStack(spacing: 24) {
            Image(systemName: "popcorn")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(WatchdTheme.textTertiary)

            VStack(spacing: 8) {
                Text("Keine Rooms")
                    .font(WatchdTheme.titleSmall())
                    .foregroundColor(WatchdTheme.textPrimary)
                Text("Erstelle einen neuen Room oder\ntritt einem bestehenden bei")
                    .font(WatchdTheme.caption())
                    .foregroundColor(WatchdTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 80)
    }

    private var bottomActions: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [WatchdTheme.background.opacity(0), WatchdTheme.background],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 50)

            HStack(spacing: 12) {
                NetflixPrimaryButton(
                    icon: "plus",
                    title: "Erstellen",
                    isLoading: viewModel.isLoading && viewModel.rooms.isEmpty
                ) {
                    viewModel.showCreateRoomSheet = true
                }

                NetflixSecondaryButton(icon: "person.2", title: "Beitreten") {
                    showJoinSheet = true
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
            .background(WatchdTheme.background)
        }
    }
}

// MARK: - Room Card (Netflix-style)

private struct RoomCard: View {
    let room: Room
    let userRoomNumber: Int
    let onTap: () -> Void
    let onEditFilters: () -> Void
    let onRename: () -> Void
    let onLeave: () -> Void
    @State private var copied = false

    private var isInactive: Bool {
        guard let lastActivity = room.lastActivityAt else { return false }
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: lastActivity) else { return false }
        return Date().timeIntervalSince(date) > 14 * 24 * 60 * 60
    }

    private var displayName: String {
        if let name = room.name, !name.isEmpty { return name }
        return "Room #\(userRoomNumber)"
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(WatchdTheme.titleSmall())
                            .foregroundColor(WatchdTheme.textPrimary)

                        Text("Code: \(room.code)")
                            .font(WatchdTheme.captionMedium())
                            .foregroundColor(WatchdTheme.textTertiary)

                        if let status = room.status {
                            Text(status == "active" ? "Aktiv" : status == "waiting" ? "Wartet auf Partner" : "Archiviert")
                                .font(WatchdTheme.labelUppercase())
                                .foregroundColor(status == "active" ? WatchdTheme.success : WatchdTheme.textTertiary)
                                .padding(.top, 2)
                        }
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(WatchdTheme.textTertiary)
                }

                HStack(spacing: 8) {
                    ShareLink(item: URL(string: "watchd://join/\(room.code)")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Teilen")
                                .font(WatchdTheme.captionMedium())
                        }
                        .foregroundColor(WatchdTheme.textSecondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(WatchdTheme.backgroundInput)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Menu {
                        Button { onRename() } label: {
                            Label("Name ändern", systemImage: "pencil")
                        }
                        Button { onEditFilters() } label: {
                            Label("Filter", systemImage: "slider.horizontal.3")
                        }
                        Button(role: .destructive) { onLeave() } label: {
                            Label("Verlassen", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(WatchdTheme.textSecondary)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(18)
            .background(WatchdTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(WatchdTheme.separator, lineWidth: 1)
            )
            .opacity(isInactive ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Rename Room Sheet

private struct RenameRoomSheet: View {
    let room: Room
    @Binding var name: String
    let onSave: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                WatchdTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    TextField("Raumname", text: $name, prompt: Text("Name des Rooms").foregroundColor(WatchdTheme.textTertiary))
                        .font(WatchdTheme.body())
                        .foregroundColor(WatchdTheme.textPrimary)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(WatchdTheme.backgroundInput)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    Text("Der neue Name wird auch für deinen Partner sichtbar.")
                        .font(WatchdTheme.caption())
                        .foregroundColor(WatchdTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Name ändern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(WatchdTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onDismiss() }
                        .foregroundColor(WatchdTheme.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { onSave() }
                        .fontWeight(.semibold)
                        .foregroundColor(WatchdTheme.primary)
                }
            }
        }
    }
}

// MARK: - Netflix-style action buttons

private struct NetflixPrimaryButton: View {
    let icon: String
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(0.9)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(WatchdTheme.bodyMedium())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(WatchdTheme.primaryButtonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .disabled(isLoading)
    }
}

private struct NetflixSecondaryButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                Text(title)
                    .font(WatchdTheme.bodyMedium())
            }
            .foregroundColor(WatchdTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(WatchdTheme.backgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(WatchdTheme.separator, lineWidth: 1)
            )
        }
    }
}

// MARK: - Join Room Sheet

private struct JoinRoomSheet: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                WatchdTheme.background.ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.fill")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundColor(WatchdTheme.primary)
                            .padding(.top, 20)

                        Text("Raum beitreten")
                            .font(WatchdTheme.titleLarge())
                            .foregroundColor(WatchdTheme.textPrimary)
                    }

                    VStack(spacing: 16) {
                        TextField("", text: $viewModel.joinCode, prompt: Text("CODE").foregroundColor(WatchdTheme.textTertiary))
                            .font(.system(size: 28, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .foregroundColor(WatchdTheme.textPrimary)
                            .padding(.vertical, 20)
                            .background(WatchdTheme.backgroundInput)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .focused($focused)
                            .padding(.horizontal, 32)

                        PrimaryButton(title: "Raum beitreten", isLoading: viewModel.isLoading) {
                            Task {
                                await viewModel.joinRoom()
                                if viewModel.selectedRoom != nil {
                                    isPresented = false
                                }
                            }
                        }
                        .padding(.horizontal, 32)

                        if let msg = viewModel.errorMessage {
                            Text(msg)
                                .font(WatchdTheme.caption())
                                .foregroundColor(WatchdTheme.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { isPresented = false }
                        .foregroundColor(WatchdTheme.textSecondary)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(AuthViewModel())
            .environmentObject(NetworkMonitor())
    }
    .preferredColorScheme(.dark)
}
