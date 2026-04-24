import SwiftUI

// MARK: - Shared filter content (used by RoomFiltersView and CreateRoomFiltersView)

struct FilterOptionsView: View {
    @Environment(\.theme) private var theme
    @Binding var filters: RoomFilters
    var showResetButton: Bool = true
    var onReset: (() -> Void)?

    private let yearOptions = [1900, 2000, 2010, 2015, 2020, 2022, 2024]
    private let ratingOptions: [(label: String, value: Double)] = [
        ("Alle", 0), ("5+", 5), ("6+", 6), ("6.5+", 6.5), ("7+", 7), ("7.5+", 7.5), ("8+", 8)
    ]
    private let runtimeOptions: [(label: String, value: Int)] = [
        ("Alle", 300), ("90 Min", 90), ("120 Min", 120), ("150 Min", 150)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                activeSummary

                genreSection
                streamingSection
                yearSection
                ratingSection
                runtimeSection

                if showResetButton, hasAnyFilter {
                    resetButton
                }
            }
            .padding(.horizontal, 28)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    private var activeSummary: some View {
        HStack(alignment: .top, spacing: 14) {
            Rectangle()
                .fill(theme.colors.accent)
                .frame(width: 2)
                .frame(minHeight: 42)

            VStack(alignment: .leading, spacing: 6) {
                Text("Aktive Auswahl")
                    .font(theme.fonts.microCaption)
                    .textCase(.uppercase)
                    .tracking(1.4)
                    .foregroundColor(theme.colors.textTertiary)

                if hasAnyFilter {
                    Text(summaryText)
                        .font(theme.fonts.body(size: 16, weight: .regular))
                        .italic()
                        .foregroundColor(theme.colors.textSecondary)
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    Text("Keine Filter. Alles bleibt offen.")
                        .font(theme.fonts.body(size: 16, weight: .regular))
                        .italic()
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
        }
    }

    private var summaryText: String {
        var parts: [String] = []
        if let g = filters.genres, !g.isEmpty { parts.append("\(g.count) Genre(s)") }
        if let s = filters.streamingServices, !s.isEmpty { parts.append("\(s.count) Streaming-Dienst(e)") }
        if let y = filters.yearFrom, y != 1900 { parts.append("Ab \(y)") }
        if let r = filters.minRating, r > 0 { parts.append("≥ \(r) ★") }
        if let rt = filters.maxRuntime, rt < 300 { parts.append("≤ \(rt) Min") }
        return parts.isEmpty ? "Keine" : parts.joined(separator: " · ")
    }

    private var hasAnyFilter: Bool {
        (filters.genres?.isEmpty == false) ||
        (filters.streamingServices?.isEmpty == false) ||
        (filters.yearFrom != nil && filters.yearFrom != 1900) ||
        (filters.minRating != nil && filters.minRating! > 0) ||
        (filters.maxRuntime != nil && filters.maxRuntime! < 300)
    }

    private var genreSection: some View {
        filterSection(title: "Genres") {
            FlowLayout(spacing: 8) {
                ForEach(GenreOption.allCases) { genre in
                    FilterChip(
                        title: genre.name,
                        isSelected: filters.genres?.contains(genre.id) == true
                    ) {
                        toggleGenre(genre.id)
                    }
                }
            }
        }
    }

    private var streamingSection: some View {
        filterSection(title: "Streaming-Dienste") {
            FlowLayout(spacing: 8) {
                ForEach(StreamingService.allCases) { service in
                    FilterChip(
                        title: service.name,
                        isSelected: filters.streamingServices?.contains(service.id) == true
                    ) {
                        toggleStreaming(service.id)
                    }
                }
            }
        }
    }

    private var yearSection: some View {
        filterSection(title: "Erscheinungsjahr") {
            FlowLayout(spacing: 8) {
                ForEach(yearOptions, id: \.self) { year in
                    FilterChip(
                        title: year == 1900 ? "Alle" : "Ab \(year)",
                        isSelected: (filters.yearFrom ?? 1900) == year
                    ) {
                        filters.yearFrom = year == 1900 ? nil : year
                    }
                }
            }
        }
    }

    private var ratingSection: some View {
        filterSection(title: "Mindestbewertung") {
            FlowLayout(spacing: 8) {
                ForEach(ratingOptions, id: \.value) { option in
                    FilterChip(
                        title: option.label,
                        isSelected: (filters.minRating ?? 0) == option.value
                    ) {
                        filters.minRating = option.value == 0 ? nil : option.value
                    }
                }
            }
        }
    }

    private var runtimeSection: some View {
        filterSection(title: "Max. Laufzeit") {
            FlowLayout(spacing: 8) {
                ForEach(runtimeOptions, id: \.value) { option in
                    FilterChip(
                        title: option.label,
                        isSelected: (filters.maxRuntime ?? 300) == option.value
                    ) {
                        filters.maxRuntime = option.value == 300 ? nil : option.value
                    }
                }
            }
        }
    }

    private var resetButton: some View {
        Button {
            resetFilters()
            onReset?()
        } label: {
            Text("Alles zurücksetzen")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundColor(theme.colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 8)
    }

    private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.6)
                .foregroundColor(theme.colors.textTertiary)
            content()
        }
    }

    private func toggleGenre(_ id: Int) {
        if filters.genres == nil { filters.genres = [] }
        if filters.genres!.contains(id) {
            filters.genres!.removeAll { $0 == id }
        } else {
            filters.genres!.append(id)
        }
    }

    private func toggleStreaming(_ id: String) {
        if filters.streamingServices == nil { filters.streamingServices = [] }
        if filters.streamingServices!.contains(id) {
            filters.streamingServices!.removeAll { $0 == id }
        } else {
            filters.streamingServices!.append(id)
        }
    }

    private func resetFilters() {
        filters = RoomFilters()
    }
}

// MARK: - Filter chip (multi-select style)

private struct FilterChip: View {
    @Environment(\.theme) private var theme
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(theme.fonts.body(size: 14, weight: .regular))
                .foregroundColor(isSelected ? theme.colors.textOnAccent : theme.colors.textPrimary)
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(isSelected ? theme.colors.accent : Color.clear)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isSelected ? Color.clear : theme.colors.separator, lineWidth: 1)
                )
                .animation(theme.motion.easeOutQuart, value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Simple flow layout for wrapping chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, pos) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + pos.x, y: bounds.minY + pos.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}

// MARK: - Room filters (edit existing room)

struct RoomFiltersView: View {
    @Environment(\.theme) private var theme
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
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                VStack(spacing: 0) {
                    editorialHeader
                        .padding(.horizontal, 28)
                        .padding(.top, 12)
                        .padding(.bottom, 8)

                    FilterOptionsView(filters: $filters, showResetButton: true)

                    if let error = errorMessage {
                        Text(error)
                            .font(theme.fonts.caption)
                            .foregroundColor(theme.colors.error)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 12)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(theme.colors.base, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text("Abbrechen")
                            .font(theme.fonts.microCaption)
                            .textCase(.uppercase)
                            .tracking(1.4)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(theme.colors.accent)
                            .scaleEffect(0.9)
                    } else {
                        Button(action: { Task { await applyFilters() } }) {
                            Text("Anwenden")
                                .font(theme.fonts.microCaption)
                                .textCase(.uppercase)
                                .tracking(1.4)
                                .foregroundColor(theme.colors.accent)
                        }
                    }
                }
            }
        }
    }

    private var editorialHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nº 06 · Filter")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.8)
                .foregroundColor(theme.colors.accent)

            Text("Was heute Abend zählt.")
                .font(theme.fonts.display(size: 28, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func applyFilters() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            _ = try await APIService.shared.updateRoomFilters(roomId: roomId, filters: filters)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Enums (Genre & Streaming)

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
        case .prime: return "Prime Video"
        case .disneyPlus: return "Disney+"
        case .appleTv: return "Apple TV+"
        case .paramount: return "Paramount+"
        }
    }
}

// MARK: - Preview

#Preview {
    RoomFiltersView(roomId: 1, currentFilters: nil)
        .environment(\.theme, .velvetHour)
        .preferredColorScheme(.dark)
}
