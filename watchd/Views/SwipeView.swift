import SwiftUI

struct SwipeView: View {
    @StateObject private var viewModel: SwipeViewModel
    @EnvironmentObject private var authVM: AuthViewModel

    private let cardWidth: CGFloat = UIScreen.main.bounds.width - 48
    private let cardHeight: CGFloat = UIScreen.main.bounds.height * 0.65

    init(room: Room) {
        _viewModel = StateObject(wrappedValue: SwipeViewModel(room: room))
    }

    var body: some View {
        ZStack {
            // Sophisticated gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.98, green: 0.96, blue: 0.94),
                    Color(red: 0.95, green: 0.93, blue: 0.90),
                    Color(red: 0.92, green: 0.88, blue: 0.85)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 40)
                
                cardStack
                
                Spacer(minLength: 20)

                actionButtons
                    .padding(.horizontal, 24)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("watchd")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    MatchesListView(roomId: viewModel.room.id)
                } label: {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.85, green: 0.30, blue: 0.25))
                            .frame(width: 36, height: 36)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
        }
        .sheet(item: $viewModel.currentMatch) { match in
            MatchView(match: match, roomId: viewModel.room.id) {
                viewModel.currentMatch = nil
            }
        }
        .alert("Fehler", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .task {
            await viewModel.fetchFeed()
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
                        .tint(Color(red: 0.85, green: 0.30, blue: 0.25))
                        .scaleEffect(1.5)
                    Text("Filme werden geladen…")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 0.4, green: 0.4, blue: 0.4))
                }
                .frame(width: cardWidth, height: cardHeight)
            } else if viewModel.movies.isEmpty {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.9, green: 0.88, blue: 0.86))
                            .frame(width: 100, height: 100)
                        Image(systemName: "film.stack")
                            .font(.system(size: 44, weight: .light))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                    
                    VStack(spacing: 6) {
                        Text("Keine weiteren Filme")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                        Text("Schau später nochmal vorbei")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
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
                    .scaleEffect(isTop ? 1.0 : 1.0 - CGFloat(index) * 0.04)
                    .offset(y: isTop ? 0 : CGFloat(index) * 12)
                    .rotationEffect(isTop ? .degrees(Double(viewModel.dragOffset.width) / 25) : .zero)
                    .offset(
                        x: isTop ? viewModel.dragOffset.width : 0,
                        y: isTop ? viewModel.dragOffset.height * 0.2 : 0
                    )
                    .animation(.interactiveSpring(response: 0.4, dampingFraction: 0.7), value: viewModel.dragOffset)
                    .gesture(isTop ? swipeGesture : nil)
                    .zIndex(isTop ? 1 : 0)
                    .shadow(color: Color.black.opacity(isTop ? 0.15 : 0.08), radius: isTop ? 24 : 12, y: isTop ? 12 : 6)
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
        HStack(spacing: 0) {
            // Pass Button
            Button {
                Task { await viewModel.handleDragEnd(CGSize(width: -150, height: 0)) }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
                        .fill(Color.white)
                        .frame(width: 72, height: 72)
                        .shadow(color: Color.black.opacity(0.1), radius: 20, y: 8)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                }
            }
            .disabled(viewModel.movies.isEmpty)
            .opacity(viewModel.movies.isEmpty ? 0.4 : 1.0)

            Spacer()
            
            // Like Button
            Button {
                Task { await viewModel.handleDragEnd(CGSize(width: 150, height: 0)) }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 28)
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
                        .frame(width: 72, height: 72)
                        .shadow(color: Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.3), radius: 20, y: 8)
                    
                    Image(systemName: "heart.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .disabled(viewModel.movies.isEmpty)
            .opacity(viewModel.movies.isEmpty ? 0.4 : 1.0)
        }
    }
}
