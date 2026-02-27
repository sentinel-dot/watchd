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
                            .font(.system(size: 44, weight: .medium))
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
                                    .font(.system(size: 14, weight: .semibold))
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

                Form {
                    Section {
                        ForEach(GenreOption.allCases) { genre in
                            Toggle(genre.name, isOn: Binding(
                                get: { filters.genres?.contains(genre.id) == true },
                                set: { isOn in
                                    if isOn {
                                        if filters.genres == nil { filters.genres = [] }
                                        filters.genres?.append(genre.id)
                                    } else {
                                        filters.genres?.removeAll { $0 == genre.id }
                                    }
                                }
                            ))
                            .tint(WatchdTheme.primary)
                        }
                    } header: { Text("Genres").foregroundColor(WatchdTheme.textSecondary) }

                    Section {
                        ForEach(StreamingService.allCases) { service in
                            Toggle(service.name, isOn: Binding(
                                get: { filters.streamingServices?.contains(service.id) == true },
                                set: { isOn in
                                    if isOn {
                                        if filters.streamingServices == nil { filters.streamingServices = [] }
                                        filters.streamingServices?.append(service.id)
                                    } else {
                                        filters.streamingServices?.removeAll { $0 == service.id }
                                    }
                                }
                            ))
                            .tint(WatchdTheme.primary)
                        }
                    } header: { Text("Streaming-Dienste").foregroundColor(WatchdTheme.textSecondary) }

                    Section {
                        Picker("Ab Jahr", selection: Binding(
                            get: { filters.yearFrom ?? 1900 },
                            set: { filters.yearFrom = $0 == 1900 ? nil : $0 }
                        )) {
                            Text("Alle").tag(1900)
                            ForEach([2000, 2010, 2015, 2020, 2022, 2024], id: \.self) { year in
                                Text("Ab \(year)").tag(year)
                            }
                        }
                        .tint(WatchdTheme.primary)
                    } header: { Text("Erscheinungsjahr").foregroundColor(WatchdTheme.textSecondary) }

                    Section {
                        Picker("Mindestens", selection: Binding(
                            get: { filters.minRating ?? 0.0 },
                            set: { filters.minRating = $0 == 0.0 ? nil : $0 }
                        )) {
                            Text("Alle").tag(0.0)
                            Text("≥ 5.0").tag(5.0)
                            Text("≥ 6.0").tag(6.0)
                            Text("≥ 6.5").tag(6.5)
                            Text("≥ 7.0").tag(7.0)
                            Text("≥ 7.5").tag(7.5)
                            Text("≥ 8.0").tag(8.0)
                        }
                        .tint(WatchdTheme.primary)
                    } header: { Text("Bewertung").foregroundColor(WatchdTheme.textSecondary) }

                    Section {
                        Picker("Maximal", selection: Binding(
                            get: { filters.maxRuntime ?? 300 },
                            set: { filters.maxRuntime = $0 == 300 ? nil : $0 }
                        )) {
                            Text("Alle").tag(300)
                            Text("≤ 90 Min").tag(90)
                            Text("≤ 120 Min").tag(120)
                            Text("≤ 150 Min").tag(150)
                        }
                        .tint(WatchdTheme.primary)
                    } header: { Text("Laufzeit").foregroundColor(WatchdTheme.textSecondary) }
                }
                .scrollContentBackground(.hidden)
                .foregroundColor(WatchdTheme.textPrimary)
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
