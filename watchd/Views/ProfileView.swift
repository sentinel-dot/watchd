import SwiftUI
import UIKit

// Profile-Tab: Konto, Dein Code, Rechtliches, Session.
// List-basiert (iOS-typisches Profil-Pattern).

struct ProfileView: View {
    @Environment(\.theme) private var theme
    @EnvironmentObject private var authVM: AuthViewModel

    @State private var showRenameSheet = false
    @State private var draftName = ""
    @State private var showDeleteAccountAlert = false

    @State private var shareCode: String?
    @State private var isLoadingCode = false
    @State private var codeError: String?
    @State private var showRegenerateConfirm = false
    @State private var copyToastVisible = false

    var body: some View {
        ZStack(alignment: .top) {
            List {
                accountSection
                shareCodeSection
                legalSection
                sessionSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.colors.base)

            if copyToastVisible {
                CopyToast(label: "Code kopiert")
                    .padding(.top, 12)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(2)
            }
        }
        .navigationTitle("Profil")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(theme.colors.base, for: .navigationBar)
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
        .alert("Konto endgültig löschen?", isPresented: $showDeleteAccountAlert) {
            Button("Abbrechen", role: .cancel) {}
            Button("Konto löschen", role: .destructive) {
                Task { await authVM.deleteAccount() }
            }
        } message: {
            Text("Alle deine Daten, Partnerschaften, Matches und Favoriten werden unwiderruflich gelöscht. Diese Aktion kann nicht rückgängig gemacht werden.")
        }
        .alert("Code neu generieren?", isPresented: $showRegenerateConfirm) {
            Button("Abbrechen", role: .cancel) {}
            Button("Neu generieren", role: .destructive) {
                Task { await regenerateCode() }
            }
        } message: {
            Text("Dein alter Code wird sofort ungültig. Bestehende Partner bleiben unberührt.")
        }
        .task {
            await loadShareCode()
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
        } header: {
            Text("Konto")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundColor(theme.colors.textTertiary)
        }
    }

    // MARK: - Dein Code

    private var shareCodeSection: some View {
        Section {
            HStack(alignment: .center, spacing: 12) {
                if isLoadingCode {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(theme.colors.accent)
                        .scaleEffect(0.8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if let code = shareCode {
                    Text(code)
                        .font(theme.fonts.body(size: 22, weight: .semibold))
                        .tracking(4)
                        .foregroundColor(theme.colors.textPrimary)
                        .lineLimit(1)
                        .accessibilityLabel("Dein Code: \(code.map(String.init).joined(separator: " "))")

                    Spacer()

                    Button {
                        copyCode()
                    } label: {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(theme.colors.accent)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Code kopieren")
                } else if let err = codeError {
                    Text(err)
                        .font(theme.fonts.caption)
                        .foregroundColor(theme.colors.error)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 4)
            .listRowBackground(theme.colors.surfaceCard)

            Button {
                showRegenerateConfirm = true
            } label: {
                Label("Code erneuern", systemImage: "arrow.triangle.2.circlepath")
                    .foregroundColor(theme.colors.textPrimary)
            }
            .listRowBackground(theme.colors.surfaceCard)
            .disabled(isLoadingCode || shareCode == nil)
        } header: {
            Text("Dein Code")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundColor(theme.colors.textTertiary)
        } footer: {
            Text("Teile diesen Code mit deinem Partner — er kann dich darüber als Partner adden.")
                .font(theme.fonts.caption)
                .foregroundColor(theme.colors.textTertiary)
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
                authVM.logout()
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
        } footer: {
            HStack {
                Spacer()
                Text(appVersionLabel)
                    .font(theme.fonts.microCaption)
                    .tracking(1.0)
                    .textCase(.uppercase)
                    .foregroundColor(theme.colors.textTertiary)
                Spacer()
            }
            .padding(.top, 24)
        }
    }

    private var appVersionLabel: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "—"
        let build = info?["CFBundleVersion"] as? String ?? "—"
        return "Watchd \(version) (\(build))"
    }

    // MARK: - Share-Code Loading

    private func loadShareCode() async {
        isLoadingCode = true
        defer { isLoadingCode = false }
        do {
            let response = try await APIService.shared.fetchShareCode()
            shareCode = response.shareCode
            codeError = nil
        } catch {
            codeError = error.localizedDescription
        }
    }

    private func regenerateCode() async {
        isLoadingCode = true
        defer { isLoadingCode = false }
        do {
            let response = try await APIService.shared.regenerateShareCode()
            shareCode = response.shareCode
            codeError = nil
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        } catch {
            codeError = error.localizedDescription
        }
    }

    private func copyCode() {
        guard let code = shareCode else { return }
        UIPasteboard.general.string = code
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        withAnimation(.easeOut(duration: 0.2)) {
            copyToastVisible = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            await MainActor.run {
                withAnimation(.easeIn(duration: 0.2)) {
                    copyToastVisible = false
                }
            }
        }
    }
}

// MARK: - Copy-Toast

private struct CopyToast: View {
    @Environment(\.theme) private var theme
    let label: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 14, weight: .medium))
            Text(label)
                .font(theme.fonts.body(size: 14, weight: .medium))
        }
        .foregroundColor(theme.colors.textOnAccent)
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .background(theme.colors.accent)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.3), radius: 12, y: 6)
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

                    Text("So sieht dich dein Partner.")
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
