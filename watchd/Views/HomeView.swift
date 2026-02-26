import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var showJoinSheet = false

    var body: some View {
        ZStack {
            // Sophisticated light gradient background
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
                        
                        Text("Bereit für euren nächsten Film?")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            .padding(.top, 4)
                    }
                    Spacer()
                    Button {
                        authVM.logout()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 44, height: 44)
                                .shadow(color: Color.black.opacity(0.08), radius: 12, y: 4)
                            
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                        }
                    }
                }
                .padding(.horizontal, 28)
                .padding(.top, 20)
                .padding(.bottom, 36)

                if let room = viewModel.currentRoom {
                    InviteCodeCard(room: room) {
                        viewModel.startSwiping()
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }

                VStack(spacing: 20) {
                    ActionCard(
                        icon: "plus.circle.fill",
                        iconColor: Color(red: 0.85, green: 0.30, blue: 0.25),
                        title: "Raum erstellen",
                        subtitle: "Neue Runde starten und jemanden einladen",
                        isLoading: viewModel.isLoading && viewModel.currentRoom == nil
                    ) {
                        Task { await viewModel.createRoom() }
                    }

                    ActionCard(
                        icon: "person.2.fill",
                        iconColor: Color(red: 0.20, green: 0.20, blue: 0.20),
                        title: "Raum beitreten",
                        subtitle: "Einladungscode von deinem Freund eingeben",
                        isLoading: false
                    ) {
                        showJoinSheet = true
                    }
                }
                .padding(.horizontal, 28)

                Spacer()
            }
        }
        .navigationTitle("")
        .navigationBarHidden(true)
        .navigationDestination(isPresented: $viewModel.navigateToSwipe) {
            if let room = viewModel.currentRoom {
                SwipeView(room: room)
            }
        }
        .sheet(isPresented: $showJoinSheet) {
            JoinRoomSheet(viewModel: viewModel, isPresented: $showJoinSheet)
        }
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "Etwas ist schiefgelaufen.")
        }
    }
}

// MARK: - Invite Code Card

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
                                if viewModel.currentRoom != nil {
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
