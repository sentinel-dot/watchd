import SwiftUI

struct CreateRoomSheet: View {
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    @State private var roomName: String = ""
    @State private var filters = RoomFilters()
    @State private var showFilters = false

    var body: some View {
        NavigationStack {
            ZStack {
                WatchdTheme.background.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "plus.circle.fill")
                            .font(WatchdTheme.iconLarge())
                            .foregroundColor(WatchdTheme.primary)
                            .padding(.top, 20)

                        Text("Neuen Room erstellen")
                            .font(WatchdTheme.titleLarge())
                            .foregroundColor(WatchdTheme.textPrimary)
                    }

                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Room-Name (optional)")
                                .font(WatchdTheme.captionMedium())
                                .foregroundColor(WatchdTheme.textTertiary)
                                .padding(.leading, 4)

                            TextField("", text: $roomName, prompt: Text("z.B. Filmabend mit Lisa").foregroundColor(WatchdTheme.textTertiary))
                                .font(WatchdTheme.body())
                                .foregroundColor(WatchdTheme.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(WatchdTheme.backgroundInput)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .padding(.horizontal, 24)

                        Button {
                            showFilters = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Filter")
                                        .font(WatchdTheme.bodyMedium())
                                        .foregroundColor(WatchdTheme.textPrimary)

                                    Text(filterSummary)
                                        .font(WatchdTheme.caption())
                                        .foregroundColor(WatchdTheme.textTertiary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(WatchdTheme.chevron())
                                    .foregroundColor(WatchdTheme.textTertiary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(WatchdTheme.backgroundCard)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(WatchdTheme.separator, lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 24)

                        PrimaryButton(title: "Room erstellen", isLoading: viewModel.isLoading) {
                            Task {
                                let finalFilters = hasAnyFilter ? filters : nil
                                await viewModel.createRoom(name: roomName, filters: finalFilters)
                                if viewModel.errorMessage == nil {
                                    isPresented = false
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 8)

                        if let msg = viewModel.errorMessage {
                            Text(msg)
                                .font(WatchdTheme.caption())
                                .foregroundColor(WatchdTheme.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
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
            .sheet(isPresented: $showFilters) {
                CreateRoomFiltersView(filters: $filters)
            }
        }
        .presentationDetents([.large])
    }

    private var hasAnyFilter: Bool {
        (filters.genres?.isEmpty == false) ||
        (filters.streamingServices?.isEmpty == false) ||
        filters.yearFrom != nil ||
        filters.minRating != nil ||
        filters.maxRuntime != nil ||
        filters.language != nil
    }

    private var filterSummary: String {
        if !hasAnyFilter { return "Keine Filter ausgewählt" }

        var parts: [String] = []
        if let genres = filters.genres, !genres.isEmpty { parts.append("\(genres.count) Genre(s)") }
        if let services = filters.streamingServices, !services.isEmpty { parts.append("\(services.count) Streaming-Dienst(e)") }
        if filters.yearFrom != nil { parts.append("Ab-Jahr gesetzt") }
        if filters.minRating != nil { parts.append("Min. Bewertung") }
        if filters.maxRuntime != nil { parts.append("Max. Laufzeit") }
        return parts.joined(separator: ", ")
    }
}

struct CreateRoomFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: RoomFilters

    var body: some View {
        NavigationView {
            ZStack {
                WatchdTheme.background.ignoresSafeArea()
                FilterOptionsView(filters: $filters, showResetButton: true)
            }
            .navigationTitle("Filter auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(WatchdTheme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                        .foregroundColor(WatchdTheme.primary)
                }
            }
        }
    }
}

#Preview {
    CreateRoomSheet(viewModel: HomeViewModel(), isPresented: .constant(true))
        .preferredColorScheme(.dark)
}
