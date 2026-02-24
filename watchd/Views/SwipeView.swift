import SwiftUI

struct SwipeView: View {
    @StateObject private var viewModel: SwipeViewModel
    @EnvironmentObject private var authVM: AuthViewModel

    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 40
    private let cardHeight: CGFloat = UIScreen.main.bounds.height * 0.62

    init(room: Room) {
        _viewModel = StateObject(wrappedValue: SwipeViewModel(room: room))
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.06, blue: 0.12).ignoresSafeArea()

            VStack(spacing: 0) {
                cardStack
                    .padding(.top, 8)

                actionButtons
                    .padding(.top, 16)

                memberBar
                    .padding(.top, 12)
                    .padding(.bottom, 16)
            }
        }
        .navigationTitle("Watchd")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    MatchesListView(roomId: viewModel.room.id)
                } label: {
                    Label("Matches", systemImage: "heart.fill")
                        .foregroundColor(.pink)
                }
            }
        }
        .sheet(item: $viewModel.currentMatch) { match in
            MatchView(match: match, roomId: viewModel.room.id) {
                viewModel.currentMatch = nil
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.fetchFeed()
            await viewModel.fetchRoomMembers()
            viewModel.startSocket()
        }
    }

    // MARK: - Card Stack

    @ViewBuilder
    private var cardStack: some View {
        ZStack {
            if viewModel.isLoading && viewModel.movies.isEmpty {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                        .scaleEffect(1.5)
                    Text("Loading movies…")
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(width: cardWidth, height: cardHeight)
            } else if viewModel.movies.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.3))
                    Text("No more movies")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.5))
                    Text("Check back later for more")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.3))
                }
                .frame(width: cardWidth, height: cardHeight)
            } else {
                ForEach(Array(viewModel.movies.prefix(3).enumerated().reversed()), id: \.element.id) { index, movie in
                    let isTop = index == 0

                    MovieCardView(
                        movie: movie,
                        dragOffset: isTop ? viewModel.dragOffset : .zero,
                        isTopCard: isTop
                    )
                    .frame(width: cardWidth, height: cardHeight)
                    .scaleEffect(isTop ? 1.0 : 1.0 - CGFloat(index) * 0.03)
                    .offset(y: isTop ? 0 : CGFloat(index) * 10)
                    .rotationEffect(isTop ? .degrees(Double(viewModel.dragOffset.width) / 22) : .zero)
                    .offset(
                        x: isTop ? viewModel.dragOffset.width : 0,
                        y: isTop ? viewModel.dragOffset.height * 0.25 : 0
                    )
                    .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.65), value: viewModel.dragOffset)
                    .gesture(isTop ? swipeGesture : nil)
                    .zIndex(isTop ? 1 : 0)
                }
            }
        }
        .frame(width: cardWidth, height: cardHeight)
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture(minimumDistance: 4)
            .onChanged { value in
                viewModel.handleDragChange(value.translation)
            }
            .onEnded { value in
                Task { await viewModel.handleDragEnd(value.translation) }
            }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: 40) {
            // Pass
            CircleActionButton(icon: "xmark", color: .red, size: 56) {
                Task { await viewModel.handleDragEnd(CGSize(width: -150, height: 0)) }
            }
            .disabled(viewModel.movies.isEmpty)

            // Super Like placeholder (visual)
            CircleActionButton(icon: "star.fill", color: .blue, size: 44) {}
                .disabled(true)
                .opacity(0.4)

            // Like
            CircleActionButton(icon: "heart.fill", color: .green, size: 56) {
                Task { await viewModel.handleDragEnd(CGSize(width: 150, height: 0)) }
            }
            .disabled(viewModel.movies.isEmpty)
        }
    }

    // MARK: - Member Bar

    private var memberBar: some View {
        HStack(spacing: 12) {
            ForEach(viewModel.roomMembers) { member in
                MemberAvatar(name: member.name)
            }

            if viewModel.roomMembers.count < 2 {
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.4))
                    Text("Waiting for partner…")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.4))
                }
            } else {
                Text("Both in room")
                    .font(.caption)
                    .foregroundColor(.green.opacity(0.7))
            }

            Spacer()

            Text("Code: \(viewModel.room.code)")
                .font(.system(.caption, design: .monospaced).weight(.semibold))
                .foregroundColor(.white.opacity(0.4))
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Circle Button

private struct CircleActionButton: View {
    let icon: String
    let color: Color
    let size: CGFloat
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size * 0.4, weight: .bold))
                .foregroundColor(color)
                .frame(width: size, height: size)
                .background(color.opacity(0.12))
                .clipShape(Circle())
                .overlay(Circle().stroke(color.opacity(0.35), lineWidth: 2))
        }
    }
}

// MARK: - Member Avatar

private struct MemberAvatar: View {
    let name: String

    private var initials: String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map { String($0) } }
            .joined()
            .uppercased()
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 36, height: 36)
            Text(initials)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
