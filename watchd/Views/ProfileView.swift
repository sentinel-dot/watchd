import SwiftUI

// Profile-Tab: Konto, Archiv, Rechtliches, Session.
// List-basiert (iOS-typisches Profil-Pattern).

struct ProfileView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var showUpgradeSheet = false
    @State private var showRenameSheet = false
    @State private var draftName = ""
    @State private var showGuestLogoutAlert = false
    @State private var showDeleteAccountAlert = false

    var body: some View {
        List {
            accountSection
            archiveSection
            legalSection
            sessionSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.colors.base)
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(theme.colors.base, for: .navigationBar)
        .sheet(isPresented: $showUpgradeSheet) {
            UpgradeAccountView()
        }
        .sheet(isPresented: $showRenameSheet) {
            ProfileNameEditSheet(
                name: $draftName,
                isPresented: $showRenameSheet,
                onSave: {
                    let trimmed = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }
                    Task { await authVM.updateName(trimmed) }
                    showRenameSheet = false
                }
            )
        }
        .alert("Als Gast abmelden?", isPresented: $showGuestLogoutAlert) {
            Button("Konto sichern") { showUpgradeSheet = true }
            Button("Trotzdem abmelden", role: .destructive) { authVM.logout() }
            Button("Abbrechen", role: .cancel) {}
        } message: {
            Text("Du bist als Gast eingeloggt. Beim Abmelden verlierst du alle Matches, Favoriten und Räume unwiderruflich. Sichere dein Konto in 20 Sekunden mit Email + Passwort.")
        }
        .alert("Konto endgültig löschen?", isPresented: $showDeleteAccountAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Konto löschen", role: .destructive) {
                Task { await authVM.deleteAccount() }
            }
        } message: {
            Text("Alle deine Daten, Räume, Matches und Favoriten werden unwiderruflich gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.")
        }
    }

    // MARK: - Konto

    private var accountSection: some View {
        Section {
            Button {
                draftName = authVM.currentUser?.name ?? ""
                showRenameSheet = true
            } label: {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Name")
                            .font(theme.fonts.microCaption)
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .foregroundColor(theme.colors.textTertiary)
                        Text(authVM.currentUser?.name ?? "—")
                            .font(theme.fonts.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(theme.colors.textTertiary)
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(theme.colors.surfaceCard)

            if let email = authVM.currentUser?.email, !email.isEmpty {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("E-Mail")
                            .font(theme.fonts.microCaption)
                            .textCase(.uppercase)
                            .tracking(1.2)
                            .foregroundColor(theme.colors.textTertiary)
                        Text(email)
                            .font(theme.fonts.bodyMedium)
                            .foregroundColor(theme.colors.textPrimary)
                    }
                    Spacer()
                }
                .listRowBackground(theme.colors.surfaceCard)
            }

            if authVM.currentUser?.isGuest == true {
                Button {
                    showUpgradeSheet = true
                } label: {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(theme.colors.accent)
                        Text("Konto sichern")
                            .font(theme.fonts.bodyMedium)
                            .foregroundColor(theme.colors.accent)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(theme.colors.textTertiary)
                    }
                }
                .buttonStyle(.plain)
                .listRowBackground(theme.colors.surfaceCard)
            }
        } header: {
            Text("Konto")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundColor(theme.colors.textTertiary)
        } footer: {
            if authVM.currentUser?.isGuest == true {
                Text("Als Gast ist dein Konto an dieses Gerät gebunden. Füge Email + Passwort hinzu, um deine Matches und Favoriten zu sichern.")
                    .font(theme.fonts.caption)
                    .foregroundColor(theme.colors.textTertiary)
            }
        }
    }

    // MARK: - Archiv

    private var archiveSection: some View {
        Section {
            NavigationLink {
                ArchivedRoomsView()
            } label: {
                Label("Archivierte Räume", systemImage: "archivebox")
                    .foregroundColor(theme.colors.textPrimary)
            }
            .listRowBackground(theme.colors.surfaceCard)
        }
    }

    // MARK: - Rechtliches

    private var legalSection: some View {
        Section {
            NavigationLink {
                PrivacyPolicyView()
            } label: {
                Label("Datenschutz", systemImage: "hand.raised")
                    .foregroundColor(theme.colors.textPrimary)
            }
            .listRowBackground(theme.colors.surfaceCard)

            NavigationLink {
                TermsOfServiceView()
            } label: {
                Label("Nutzungsbedingungen", systemImage: "doc.text")
                    .foregroundColor(theme.colors.textPrimary)
            }
            .listRowBackground(theme.colors.surfaceCard)

            NavigationLink {
                ImpressumView()
            } label: {
                Label("Impressum", systemImage: "building.columns")
                    .foregroundColor(theme.colors.textPrimary)
            }
            .listRowBackground(theme.colors.surfaceCard)

            NavigationLink {
                TMDBAttributionView()
            } label: {
                Label("Datenquellen", systemImage: "info.circle")
                    .foregroundColor(theme.colors.textPrimary)
            }
            .listRowBackground(theme.colors.surfaceCard)
        } header: {
            Text("Rechtliches")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundColor(theme.colors.textTertiary)
        }
    }

    // MARK: - Session

    private var sessionSection: some View {
        Section {
            Button {
                if authVM.currentUser?.isGuest == true {
                    showGuestLogoutAlert = true
                } else {
                    authVM.logout()
                }
            } label: {
                Label("Abmelden", systemImage: "rectangle.portrait.and.arrow.right")
                    .foregroundColor(theme.colors.textPrimary)
            }
            .listRowBackground(theme.colors.surfaceCard)

            Button(role: .destructive) {
                showDeleteAccountAlert = true
            } label: {
                Label("Konto löschen", systemImage: "trash")
            }
            .listRowBackground(theme.colors.surfaceCard)
        }
    }
}

// MARK: - Inline Name Edit Sheet

private struct ProfileNameEditSheet: View {
    @Environment(\.theme) private var theme
    @Binding var name: String
    @Binding var isPresented: Bool
    let onSave: () -> Void
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                theme.colors.base.ignoresSafeArea()

                VStack(spacing: 24) {
                    TextField("Name", text: $name, prompt: Text("Dein Name").foregroundColor(theme.colors.textTertiary))
                        .font(theme.fonts.bodyRegular)
                        .foregroundColor(theme.colors.textPrimary)
                        .padding(.vertical, 16)
                        .padding(.horizontal, 16)
                        .background(theme.colors.surfaceInput)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.horizontal, 24)
                        .padding(.top, 24)
                        .focused($focused)

                    Text("So sehen dich andere im Raum.")
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 24)

                    Spacer()
                }
            }
            .navigationTitle("Name ändern")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(theme.colors.base, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { isPresented = false }
                        .foregroundColor(theme.colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Speichern") { onSave() }
                        .font(theme.fonts.bodyMedium)
                        .foregroundColor(theme.colors.accent)
                }
            }
            .onAppear { focused = true }
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView()
            .environmentObject(AuthViewModel.shared)
    }
    .environment(\.theme, .velvetHour)
    .preferredColorScheme(.dark)
}
