import SwiftUI

struct RoomFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    let roomId: Int
    @State private var filters: RoomFilters
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    init(roomId: Int, currentFilters: RoomFilters?) {
        self.roomId = roomId
        self._filters = State(initialValue: currentFilters ?? RoomFilters())
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color(red: 0.98, green: 0.96, blue: 0.94)
                    .ignoresSafeArea()
                
                Form {
                    Section("Genres") {
                        ForEach(GenreOption.allCases) { genre in
                            Toggle(genre.name, isOn: Binding(
                                get: { filters.genres?.contains(genre.id) == true },
                                set: { isOn in
                                    if isOn {
                                        if filters.genres == nil {
                                            filters.genres = []
                                        }
                                        filters.genres?.append(genre.id)
                                    } else {
                                        filters.genres?.removeAll { $0 == genre.id }
                                    }
                                }
                            ))
                        }
                    }
                    
                    Section("Streaming-Dienste") {
                        ForEach(StreamingService.allCases) { service in
                            Toggle(service.name, isOn: Binding(
                                get: { filters.streamingServices?.contains(service.id) == true },
                                set: { isOn in
                                    if isOn {
                                        if filters.streamingServices == nil {
                                            filters.streamingServices = []
                                        }
                                        filters.streamingServices?.append(service.id)
                                    } else {
                                        filters.streamingServices?.removeAll { $0 == service.id }
                                    }
                                }
                            ))
                        }
                    }
                    
                    Section("Erscheinungsjahr") {
                        Picker("Ab Jahr", selection: Binding(
                            get: { filters.yearFrom ?? 1900 },
                            set: { filters.yearFrom = $0 }
                        )) {
                            Text("Alle").tag(1900)
                            ForEach([2000, 2010, 2015, 2020, 2022, 2024], id: \.self) { year in
                                Text("Ab \(year)").tag(year)
                            }
                        }
                    }
                    
                    Section("Bewertung") {
                        Picker("Mindestens", selection: Binding(
                            get: { filters.minRating ?? 0.0 },
                            set: { filters.minRating = $0 }
                        )) {
                            Text("Alle").tag(0.0)
                            Text("≥ 5.0").tag(5.0)
                            Text("≥ 6.0").tag(6.0)
                            Text("≥ 6.5").tag(6.5)
                            Text("≥ 7.0").tag(7.0)
                            Text("≥ 7.5").tag(7.5)
                            Text("≥ 8.0").tag(8.0)
                        }
                    }
                    
                    Section("Laufzeit") {
                        Picker("Maximal", selection: Binding(
                            get: { filters.maxRuntime ?? 300 },
                            set: { filters.maxRuntime = $0 }
                        )) {
                            Text("Alle").tag(300)
                            Text("≤ 90 Min").tag(90)
                            Text("≤ 120 Min").tag(120)
                            Text("≤ 150 Min").tag(150)
                        }
                    }
                    
                    if let error = errorMessage {
                        Section {
                            Text(error)
                                .foregroundColor(.red)
                                .font(.system(size: 13))
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Anwenden") {
                        Task { await applyFilters() }
                    }
                    .disabled(isLoading)
                }
            }
        }
    }
    
    private func applyFilters() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let _ = try await APIService.shared.updateRoomFilters(roomId: roomId, filters: filters)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

enum GenreOption: Int, CaseIterable, Identifiable {
    case action = 28
    case adventure = 12
    case comedy = 35
    case crime = 80
    case documentary = 99
    case drama = 18
    case family = 10751
    case fantasy = 14
    case horror = 27
    case mystery = 9648
    case romance = 10749
    case sciFi = 878
    case thriller = 53
    case war = 10752
    case western = 37
    
    var id: Int { rawValue }
    
    var name: String {
        switch self {
        case .action: return "Action"
        case .adventure: return "Abenteuer"
        case .comedy: return "Komödie"
        case .crime: return "Krimi"
        case .documentary: return "Dokumentation"
        case .drama: return "Drama"
        case .family: return "Familie"
        case .fantasy: return "Fantasy"
        case .horror: return "Horror"
        case .mystery: return "Mystery"
        case .romance: return "Romantik"
        case .sciFi: return "Science-Fiction"
        case .thriller: return "Thriller"
        case .war: return "Kriegsfilm"
        case .western: return "Western"
        }
    }
}

enum StreamingService: String, CaseIterable, Identifiable {
    case netflix
    case prime
    case disneyPlus = "disney+"
    case appleTv = "apple-tv"
    case paramount = "paramount+"
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .netflix: return "Netflix"
        case .prime: return "Amazon Prime"
        case .disneyPlus: return "Disney+"
        case .appleTv: return "Apple TV+"
        case .paramount: return "Paramount+"
        }
    }
}

#Preview {
    RoomFiltersView(roomId: 1, currentFilters: nil)
}
