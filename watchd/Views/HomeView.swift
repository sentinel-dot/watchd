import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @StateObject private var viewModel = HomeViewModel()
    @State private var showJoinSheet = false

    var body: some View {
        ZStack(alignment: .top) {
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
                // Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hallo,")
                            .font(.system(size: 32, weight: .light))
                            .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                        
                        Text(authVM.currentUser?.name ?? "du")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                        
                        if let user = authVM.currentUser, user.isGuest {
                            Text("Gast-Modus")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
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
                            ArchivedRoomsView()
                        } label: {
                            Label("Archivierte Rooms", systemImage: "archivebox")
                        }
                        Button(action: { authVM.logout() }) {
                            Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
                            
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 24)

                if viewModel.isLoading && viewModel.rooms.isEmpty {
                    Spacer()
                    LoadingView(message: "Rooms werden geladen...")
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            if viewModel.rooms.isEmpty {
                                VStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 0.9, green: 0.88, blue: 0.86))
                                            .frame(width: 100, height: 100)
                                        Image(systemName: "popcorn")
                                            .font(.system(size: 44, weight: .light))
                                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                    }
                                    
                                    VStack(spacing: 6) {
                                        Text("Keine Rooms")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                                        Text("Erstelle einen neuen Room oder\ntritt einem bestehenden bei")
                                            .font(.system(size: 14, weight: .regular))
                                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                            .multilineTextAlignment(.center)
                                    }
                                }
                                .padding(.top, 100)
                            } else {
                                ForEach(Array(viewModel.rooms.enumerated()), id: \.element.id) { index, room in
                                    RoomCard(
                                        room: room,
                                        userRoomNumber: index + 1,
                                        onTap: { viewModel.selectRoom(room) },
                                        onEditFilters: { viewModel.showFiltersForRoom = room },
                                        onLeave: {
                                            viewModel.roomToLeave = room
                                            viewModel.showLeaveConfirmation = true
                                        }
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 180)
                    }
                }
            }
            
            if !networkMonitor.isConnected {
                OfflineBanner()
                    .animation(.spring(), value: networkMonitor.isConnected)
            }
            
            VStack {
                Spacer()
                
                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [
                            Color(red: 0.98, green: 0.96, blue: 0.94).opacity(0),
                            Color(red: 0.98, green: 0.96, blue: 0.94)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)
                    
                    HStack(spacing: 12) {
                        FloatingActionButton(
                            icon: "plus.circle.fill",
                            title: "Erstellen",
                            isLoading: viewModel.isLoading && viewModel.rooms.isEmpty
                        ) {
                            viewModel.showCreateRoomSheet = true
                        }
                        
                        FloatingActionButton(
                            icon: "person.2.fill",
                            title: "Beitreten",
                            isLoading: false
                        ) {
                            showJoinSheet = true
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 32)
                    .background(Color(red: 0.98, green: 0.96, blue: 0.94))
                }
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
}

// MARK: - Room Card

private struct RoomCard: View {
    let room: Room
    let userRoomNumber: Int
    let onTap: () -> Void
    let onEditFilters: () -> Void
    let onLeave: () -> Void
    @State private var copied = false
    @State private var showSettingsMenu = false
    
    private var isInactive: Bool {
        guard let lastActivity = room.lastActivityAt else { return false }
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: lastActivity) else { return false }
        return Date().timeIntervalSince(date) > 14 * 24 * 60 * 60
    }
    
    private var displayName: String {
        if let name = room.name, !name.isEmpty {
            return name
        }
        return "Room #\(userRoomNumber)"
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName)
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                        
                        Text("Code: \(room.code)")
                            .font(.system(size: 13, weight: .medium, design: .monospaced))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        
                        if let status = room.status {
                            Text(status == "active" ? "Aktiv" : status == "waiting" ? "Wartet auf Partner" : "Archiviert")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(status == "active" ? Color(red: 0.2, green: 0.7, blue: 0.3) : Color(red: 0.5, green: 0.5, blue: 0.5))
                                .padding(.top, 2)
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                        .frame(width: 32, height: 32)
                }
                
                HStack(spacing: 8) {
                    ShareLink(item: URL(string: "watchd://join/\(room.code)")!) {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11, weight: .semibold))
                            Text("Teilen")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(Color(red: 0.9, green: 0.88, blue: 0.86))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Menu {
                        Button {
                            onEditFilters()
                        } label: {
                            Label("Filter", systemImage: "slider.horizontal.3")
                        }
                        
                        Button(role: .destructive) {
                            onLeave()
                        } label: {
                            Label("Verlassen", systemImage: "rectangle.portrait.and.arrow.right")
                        }
                    } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 16, y: 6)
            )
            .opacity(isInactive ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Floating Action Button

private struct FloatingActionButton: View {
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
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.85, green: 0.30, blue: 0.25),
                        Color(red: 0.90, green: 0.40, blue: 0.35)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.3), radius: 16, y: 8)
        }
        .disabled(isLoading)
    }
}

// MARK: - Invite Code Card (legacy - kept for compatibility)

private struct InviteCodeCard: View {
    let room: Room
    let onStart: () -> Void
    @State private var copied = false

    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Raum erstellt")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    .textCase(.uppercase)
                    .tracking(1)

                Text(room.code)
                    .font(.system(size: 56, weight: .black, design: .monospaced))
                    .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                    .tracking(12)

                Text("Teile diesen Code mit einem Freund")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
            }
            .padding(.top, 8)

            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = room.code
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 14, weight: .semibold))
                        Text(copied ? "Kopiert!" : "Kopieren")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
                }

                ShareLink(item: "Tritt meinem Watchd-Raum bei! Code: \(room.code)") {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Teilen")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
                }
            }

            Button(action: onStart) {
                Text("Swipen starten")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.30, blue: 0.25),
                                Color(red: 0.90, green: 0.40, blue: 0.35)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.3), radius: 16, y: 8)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 20, y: 10)
        )
    }
}

// MARK: - Action Card

private struct ActionCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(iconColor)
                    } else {
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(iconColor)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                        .multilineTextAlignment(.leading)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.06), radius: 16, y: 6)
            )
        }
        .disabled(isLoading)
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
                Color(red: 0.98, green: 0.96, blue: 0.94).ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(red: 0.85, green: 0.30, blue: 0.25),
                                            Color(red: 0.90, green: 0.40, blue: 0.35)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .shadow(color: Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.3), radius: 20, y: 10)
                            
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)

                        Text("Raum beitreten")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    }

                    VStack(spacing: 16) {
                        TextField("", text: $viewModel.joinCode, prompt: Text("CODE").foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7)))
                            .font(.system(size: 32, weight: .bold, design: .monospaced))
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                            .padding(.vertical, 20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                            )
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
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
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
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
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
    }
}
