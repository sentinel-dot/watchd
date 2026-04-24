import SwiftUI

struct CreateRoomSheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var viewModel: HomeViewModel
    @Binding var isPresented: Bool
    @State private var roomName: String = ""
    @State private var filters = RoomFilters()
    @State private var showFilters = false
    @State private var isNameFocused = false

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        masthead
                            .padding(.bottom, 28)

                        tagline
                            .padding(.bottom, 44)

                        nameField
                            .padding(.bottom, 28)

                        filtersLink
                            .padding(.bottom, 28)

                        PrimaryButton(title: "Raum eröffnen", isLoading: viewModel.isLoading) {
                            Task {
                                let finalFilters = hasAnyFilter ? filters : nil
                                await viewModel.createRoom(name: roomName, filters: finalFilters)
                                if viewModel.errorMessage == nil {
                                    isPresented = false
                                }
                            }
                        }

                        if let msg = viewModel.errorMessage {
                            Text(msg)
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.colors.error)
                                .padding(.top, 14)
                        }

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 32)
                }
                .scrollDismissesKeyboard(.interactively)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(theme.colors.base, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { isPresented = false }) {
                        Text("Abbrechen")
                            .font(theme.fonts.microCaption)
                            .textCase(.uppercase)
                            .tracking(1.4)
                            .foregroundColor(theme.colors.textSecondary)
                    }
                }
            }
            .sheet(isPresented: $showFilters) {
                CreateRoomFiltersView(filters: $filters)
            }
        }
        .presentationDetents([.large])
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nº 07 · Neu")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.8)
                .foregroundColor(theme.colors.accent)

            Text("Einen Abend eröffnen.")
                .font(theme.fonts.display(size: 32, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.textPrimary)
        }
    }

    private var tagline: some View {
        HStack(alignment: .top, spacing: 14) {
            Rectangle()
                .fill(theme.colors.accent)
                .frame(width: 2, height: 42)

            Text("Gib dem Raum einen Namen — oder lass es offen.")
                .font(theme.fonts.body(size: 16, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(3)
        }
    }

    private var nameField: some View {
        AuthField(
            icon: "pencil",
            placeholder: "Name des Raums",
            text: $roomName,
            textContentType: .none,
            returnKeyType: .done,
            isFocused: $isNameFocused
        )
    }

    private var filtersLink: some View {
        Button(action: { showFilters = true }) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Filter")
                            .font(theme.fonts.microCaption)
                            .textCase(.uppercase)
                            .tracking(1.4)
                            .foregroundColor(theme.colors.textTertiary)

                        Text(filterSummary)
                            .font(theme.fonts.body(size: 16, weight: .regular))
                            .italic()
                            .foregroundColor(hasAnyFilter ? theme.colors.textPrimary : theme.colors.textTertiary)
                            .multilineTextAlignment(.leading)
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(theme.colors.textTertiary)
                }
                .padding(.vertical, 14)

                Rectangle()
                    .fill(theme.colors.separator)
                    .frame(height: 1)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
        if !hasAnyFilter { return "Alles offen. Keine Auswahl." }

        var parts: [String] = []
        if let genres = filters.genres, !genres.isEmpty { parts.append("\(genres.count) Genre(s)") }
        if let services = filters.streamingServices, !services.isEmpty { parts.append("\(services.count) Dienste") }
        if filters.yearFrom != nil { parts.append("Jahr") }
        if filters.minRating != nil { parts.append("Bewertung") }
        if filters.maxRuntime != nil { parts.append("Laufzeit") }
        return parts.joined(separator: " · ")
    }
}

struct CreateRoomFiltersView: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @Binding var filters: RoomFilters

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                VStack(spacing: 0) {
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
                    .padding(.horizontal, 28)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                    FilterOptionsView(filters: $filters, showResetButton: true)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(theme.colors.base, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: { dismiss() }) {
                        Text("Fertig")
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

#Preview {
    CreateRoomSheet(viewModel: HomeViewModel(), isPresented: .constant(true))
        .environment(\.theme, .velvetHour)
        .preferredColorScheme(.dark)
}
