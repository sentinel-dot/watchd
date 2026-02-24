import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var viewModel = HomeViewModel()
    @State private var showJoinSheet = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.12), Color(red: 0.12, green: 0.04, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hi, \(authVM.currentUser?.name ?? "there") 👋")
                            .font(.title2.weight(.bold))
                            .foregroundColor(.white)
                        Text("Ready to find your next watch?")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Button {
                        authVM.logout()
                    } label: {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 32)

                if let room = viewModel.currentRoom {
                    InviteCodeCard(room: room) {
                        viewModel.startSwiping()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                VStack(spacing: 16) {
                    ActionCard(
                        icon: "plus.circle.fill",
                        iconColor: .pink,
                        title: "Create a Room",
                        subtitle: "Start a new session and invite a friend",
                        isLoading: viewModel.isLoading && viewModel.currentRoom == nil
                    ) {
                        Task { await viewModel.createRoom() }
                    }

                    ActionCard(
                        icon: "person.2.fill",
                        iconColor: .purple,
                        title: "Join a Room",
                        subtitle: "Enter an invite code from your friend",
                        isLoading: false
                    ) {
                        showJoinSheet = true
                    }
                }
                .padding(.horizontal, 24)

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
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "Something went wrong.")
        }
    }
}

// MARK: - Invite Code Card

private struct InviteCodeCard: View {
    let room: Room
    let onStart: () -> Void
    @State private var copied = false

    var body: some View {
        VStack(spacing: 16) {
            Text("Room Created!")
                .font(.headline)
                .foregroundColor(.white.opacity(0.8))

            Text(room.code)
                .font(.system(size: 44, weight: .black, design: .monospaced))
                .foregroundStyle(
                    LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                )
                .tracking(8)

            Text("Share this code with a friend")
                .font(.caption)
                .foregroundColor(.white.opacity(0.5))

            HStack(spacing: 12) {
                Button {
                    UIPasteboard.general.string = room.code
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { copied = false }
                } label: {
                    Label(copied ? "Copied!" : "Copy Code", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                ShareLink(item: "Join my Watchd room! Code: \(room.code)") {
                    Label("Share", systemImage: "square.and.arrow.up")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            Button(action: onStart) {
                Text("Start Swiping →")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
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
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 50, height: 50)
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(iconColor)
                    } else {
                        Image(systemName: icon)
                            .font(.title3)
                            .foregroundColor(iconColor)
                    }
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(18)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
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
                Color(red: 0.08, green: 0.08, blue: 0.14).ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                        .padding(.top, 20)

                    Text("Enter Invite Code")
                        .font(.title2.bold())
                        .foregroundColor(.white)

                    TextField("e.g. AB3X7Q", text: $viewModel.joinCode)
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.white.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .focused($focused)
                        .padding(.horizontal, 32)

                    PrimaryButton(title: "Join Room", isLoading: viewModel.isLoading) {
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
                            .font(.caption)
                            .foregroundColor(.red.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    Spacer()
                }
            }
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { isPresented = false }
                        .foregroundColor(.white.opacity(0.7))
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
