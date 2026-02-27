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
                Color(red: 0.98, green: 0.96, blue: 0.94).ignoresSafeArea()
                
                VStack(spacing: 24) {
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
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 40, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.top, 20)
                        
                        Text("Neuen Room erstellen")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                    }
                    
                    VStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Room-Name (optional)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                .padding(.leading, 4)
                            
                            TextField("", text: $roomName, prompt: Text("z.B. Filmabend mit Lisa").foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7)))
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.white)
                                        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                                )
                        }
                        .padding(.horizontal, 32)
                        
                        Button {
                            showFilters = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Filter")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                                    
                                    Text(filterSummary)
                                        .font(.system(size: 13, weight: .regular))
                                        .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(Color(red: 0.7, green: 0.7, blue: 0.7))
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
                            )
                        }
                        .padding(.horizontal, 32)
                        
                        PrimaryButton(title: "Room erstellen", isLoading: viewModel.isLoading) {
                            Task {
                                let finalFilters = hasAnyFilter ? filters : nil
                                await viewModel.createRoom(name: roomName, filters: finalFilters)
                                if viewModel.errorMessage == nil {
                                    isPresented = false
                                }
                            }
                        }
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                        
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
        if !hasAnyFilter {
            return "Keine Filter ausgewählt"
        }
        
        var parts: [String] = []
        
        if let genres = filters.genres, !genres.isEmpty {
            parts.append("\(genres.count) Genre(s)")
        }
        
        if let services = filters.streamingServices, !services.isEmpty {
            parts.append("\(services.count) Streaming-Dienst(e)")
        }
        
        if filters.yearFrom != nil {
            parts.append("Ab-Jahr gesetzt")
        }
        
        if filters.minRating != nil {
            parts.append("Min. Bewertung")
        }
        
        if filters.maxRuntime != nil {
            parts.append("Max. Laufzeit")
        }
        
        return parts.joined(separator: ", ")
    }
}

struct CreateRoomFiltersView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: RoomFilters
    
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
                            set: { filters.yearFrom = $0 == 1900 ? nil : $0 }
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
                    }
                    
                    Section("Laufzeit") {
                        Picker("Maximal", selection: Binding(
                            get: { filters.maxRuntime ?? 300 },
                            set: { filters.maxRuntime = $0 == 300 ? nil : $0 }
                        )) {
                            Text("Alle").tag(300)
                            Text("≤ 90 Min").tag(90)
                            Text("≤ 120 Min").tag(120)
                            Text("≤ 150 Min").tag(150)
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Filter auswählen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    CreateRoomSheet(viewModel: HomeViewModel(), isPresented: .constant(true))
}
