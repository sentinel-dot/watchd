import SwiftUI

struct RoomsView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var networkMonitor: NetworkMonitor
    @StateObject private var viewModel = HomeViewModel()
    @State private var showJoinSheet = false

    var body: some View {
        ZStack(alignment: .top) {
            theme.colors.base.ignoresSafeArea()

            VStack(spacing: 0) {
                header

                if viewModel.isLoading && viewModel.rooms.isEmpty && !viewModel.hasLoadedOnce {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(theme.colors.accent)
                        .scaleEffect(1.1)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if viewModel.rooms.isEmpty {
                                emptyRooms
                            } else {
                                ForEach(Array(viewModel.rooms.enumerated()), id: \.element.id) { index, room in
                                    RoomEditorialRow(
                                        room: room,
                                        ordinal: index + 1,
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

                                    if index < viewModel.rooms.count - 1 {
                                        Rectangle()
                                            .fill(theme.colors.separator)
                                            .frame(height: 1)
                                            .padding(.horizontal, 24)
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 200)
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
            if viewModel.roomToLeave?.status == "active" {
                Text("Dein Partner ist noch im Raum. Du kannst jederzeit über den Code oder Invite-Link zurückkommen.")
            } else {
                Text("Du bist alleine im Raum. Beim Verlassen wird er geschlossen — Matches und Favoriten bleiben im Archiv verfügbar.")
            }
        }
        .task {
            await viewModel.loadRooms()
        }
        .refreshable {
            await viewModel.loadRooms()
        }
    }

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

                if let user = authVM.currentUser, user.isGuest {
                    Text("Gast")
                        .font(theme.fonts.microCaption)
                        .tracking(1.2)
                        .textCase(.uppercase)
                        .foregroundColor(theme.colors.textTertiary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .overlay(
                            Capsule().stroke(theme.colors.separator, lineWidth: 1)
                        )
                }

                Spacer()
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 16)
        .padding(.bottom, 32)
    }

    private var emptyRooms: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Noch kein Abend geplant.")
                .font(theme.fonts.titleMedium)
                .foregroundColor(theme.colors.textPrimary)

            Text("Eröffne einen Raum oder tritt mit einem\nCode einem bestehenden bei.")
                .font(theme.fonts.bodyRegular)
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 48)
    }

    private var bottomActions: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [theme.colors.base.opacity(0), theme.colors.base],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 60)

            VStack(spacing: 14) {
                Button {
                    showJoinSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Bereits eingeladen?")
                            .font(theme.fonts.bodyRegular)
                            .foregroundColor(theme.colors.textSecondary)
                        Text("Code eingeben")
                            .font(theme.fonts.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                            .underline()
                    }
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.showCreateRoomSheet = true
                } label: {
                    HStack(spacing: 10) {
                        if viewModel.isLoading && viewModel.rooms.isEmpty {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(theme.colors.textOnAccent)
                                .scaleEffect(0.85)
                        } else {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        Text("Neuen Raum eröffnen")
                            .font(theme.fonts.bodyMedium)
                    }
                    .foregroundColor(theme.colors.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(theme.colors.primaryButtonGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading && viewModel.rooms.isEmpty)
                .accessibilityLabel("Neuen Raum eröffnen")
                .accessibilityAddTraits(.isButton)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 34)
            .background(theme.colors.base)
        }
    }
}

// MARK: - Editorial Room Row

private struct RoomEditorialRow: View {
    let room: Room
    let ordinal: Int
    let onTap: () -> Void
    let onEditFilters: () -> Void
    let onRename: () -> Void
    let onLeave: () -> Void

    @Environment(\.theme) private var theme

    private var isInactive: Bool {
        guard let lastActivity = room.lastActivityAt else { return false }
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: lastActivity) else { return false }
        return Date().timeIntervalSince(date) > 14 * 24 * 60 * 60
    }

    private var displayName: String {
        if let name = room.name, !name.isEmpty { return name }
        return "Unbenannter Raum"
    }

    private var statusLabel: String {
        switch room.status {
        case "active": return "Aktiv · zu zweit"
        case "waiting": return "Wartet auf Partner"
        case "dissolved": return "Archiviert"
        default: return room.status ?? ""
        }
    }

    private var statusColor: Color {
        switch room.status {
        case "active": return theme.colors.success
        case "waiting": return theme.colors.accent
        default: return theme.colors.textTertiary
        }
    }

    private var ordinalString: String {
        String(format: "Nº %02d", ordinal)
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
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 6, height: 6)
                        Text(statusLabel)
                            .font(theme.fonts.microCaption)
                            .tracking(1.0)
                            .textCase(.uppercase)
                            .foregroundColor(theme.colors.textSecondary)
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
            .opacity(isInactive ? 0.5 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(displayName), \(statusLabel)")
        .accessibilityAddTraits(.isButton)
        .contextMenu {
            Button {
                onRename()
            } label: {
                Label("Name ändern", systemImage: "pencil")
            }
            Button {
                onEditFilters()
            } label: {
                Label("Filter", systemImage: "slider.horizontal.3")
            }
            ShareLink(item: URL(string: "watchd://join/\(room.code)")!) {
                Label("Einladung teilen", systemImage: "square.and.arrow.up")
            }
            Button(role: .destructive) {
                onLeave()
            } label: {
                Label("Raum verlassen", systemImage: "rectangle.portrait.and.arrow.right")
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onLeave) {
                Label("Verlassen", systemImage: "rectangle.portrait.and.arrow.right")
            }
            Button(action: onEditFilters) {
                Label("Filter", systemImage: "slider.horizontal.3")
            }
            .tint(theme.colors.textSecondary)
        }
    }
}

// MARK: - Rename Room Sheet

private struct RenameRoomSheet: View {
    let room: Room
    @Binding var name: String
    let onSave: () -> Void
    let onDismiss: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                VStack(spacing: 24) {
                    TextField("Raumname", text: $name, prompt: Text("Name des Raums").foregroundColor(theme.colors.textTertiary))
                        .font(theme.fonts.bodyRegular)
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(theme.colors.surfaceInput)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 24)
                        .padding(.top, 24)

                    Text("Der neue Name ist auch für deinen Partner sichtbar.")
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Name ändern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(theme.colors.base, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { onDismiss() }
                        .foregroundColor(theme.colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { onSave() }
                        .font(theme.fonts.bodyMedium)
                        .foregroundColor(theme.colors.accent)
                }
            }
        }
    }
}

// MARK: - Join Room Sheet

private struct JoinRoomSheet: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    @FocusState private var focused: Bool

    @Environment(\.theme) private var theme

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                VStack(spacing: 32) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Raum beitreten")
                            .font(theme.fonts.titleLarge)
                            .foregroundColor(theme.colors.textPrimary)

                        Text("Gib den sechsstelligen Code deines Partners ein.")
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)

                    VStack(spacing: 16) {
                        TextField("", text: $viewModel.joinCode, prompt: Text("CODE").foregroundColor(theme.colors.textTertiary))
                            .font(theme.fonts.display(size: 32, weight: .regular))
                            .tracking(8)
                            .multilineTextAlignment(.center)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .foregroundColor(theme.colors.textPrimary)
                            .padding(.vertical, 20)
                            .background(theme.colors.surfaceInput)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .focused($focused)
                            .padding(.horizontal, 28)

                        Button {
                            Task {
                                await viewModel.joinRoom()
                                if viewModel.selectedRoom != nil {
                                    isPresented = false
                                }
                            }
                        } label: {
                            HStack(spacing: 8) {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .tint(theme.colors.textOnAccent)
                                        .scaleEffect(0.85)
                                }
                                Text("Beitreten")
                                    .font(theme.fonts.bodyMedium)
                            }
                            .foregroundColor(theme.colors.textOnAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(theme.colors.primaryButtonGradient)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isLoading)
                        .padding(.horizontal, 28)

                        if let msg = viewModel.errorMessage {
                            Text(msg)
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.colors.error)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }
                    }

                    Spacer()
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { isPresented = false }
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .onAppear { focused = true }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    NavigationStack {
        RoomsView()
            .environmentObject(AuthViewModel.shared)
            .environmentObject(NetworkMonitor())
    }
    .preferredColorScheme(.dark)
}
