import SwiftUI

struct AddPartnerSheet: View {
    @Environment(\.theme) private var theme
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = AddPartnerViewModel()
    @FocusState private var focused: Bool

    let onSuccess: (Partnership) -> Void

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                theme.colors.base.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        editorialHeader
                            .padding(.bottom, 36)

                        codeField
                            .padding(.bottom, 18)

                        if let msg = viewModel.errorMessage {
                            Text(msg)
                                .font(theme.fonts.caption)
                                .foregroundColor(theme.colors.error)
                                .multilineTextAlignment(.leading)
                                .padding(.bottom, 12)
                        }

                        helperText
                            .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                primaryAction
                    .padding(.horizontal, 28)
                    .padding(.bottom, 24)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(theme.colors.base, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") { dismiss() }
                        .font(theme.fonts.microCaption)
                        .textCase(.uppercase)
                        .tracking(1.4)
                        .foregroundColor(theme.colors.textSecondary)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    focused = true
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var editorialHeader: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Nº 03 · Partner")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.8)
                .foregroundColor(theme.colors.accent)

            Text("Partner hinzufügen.")
                .font(theme.fonts.display(size: 32, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.textPrimary)
        }
    }

    private var codeField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Code")
                .font(theme.fonts.microCaption)
                .textCase(.uppercase)
                .tracking(1.4)
                .foregroundColor(theme.colors.textTertiary)

            TextField(
                "",
                text: Binding(
                    get: { viewModel.codeInput },
                    set: { viewModel.codeInput = AddPartnerViewModel.normalize($0) }
                ),
                prompt: Text("ABCD2345").foregroundColor(theme.colors.textTertiary)
            )
            .font(theme.fonts.display(size: 28, weight: .regular))
            .tracking(6)
            .multilineTextAlignment(.leading)
            .textInputAutocapitalization(.characters)
            .autocorrectionDisabled()
            .foregroundColor(theme.colors.textPrimary)
            .padding(.vertical, 14)
            .focused($focused)
            .overlay(
                Rectangle()
                    .fill(focused ? theme.colors.accent : theme.colors.separator)
                    .frame(height: 1)
                    .frame(maxWidth: .infinity, alignment: .bottom),
                alignment: .bottom
            )
            .animation(theme.motion.easeOutQuart, value: focused)
        }
    }

    private var helperText: some View {
        HStack(alignment: .top, spacing: 12) {
            Rectangle()
                .fill(theme.colors.accent)
                .frame(width: 2)
                .frame(minHeight: 38)

            Text("Gib den 8-stelligen Code deines Partners ein. Er bekommt eine Anfrage und kann sie bestätigen oder ablehnen.")
                .font(theme.fonts.body(size: 15, weight: .regular))
                .italic()
                .foregroundColor(theme.colors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var primaryAction: some View {
        Button {
            Task {
                await viewModel.submit { partnership in
                    onSuccess(partnership)
                    dismiss()
                }
            }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isSubmitting {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(theme.colors.textOnAccent)
                        .scaleEffect(0.85)
                }
                Text("Anfrage senden")
                    .font(theme.fonts.bodyMedium)
            }
            .foregroundColor(theme.colors.textOnAccent)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(theme.colors.primaryButtonGradient)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!viewModel.isValid || viewModel.isSubmitting)
        .opacity(viewModel.isValid ? 1.0 : 0.4)
    }
}

#Preview {
    AddPartnerSheet { _ in }
        .environment(\.theme, .velvetHour)
        .preferredColorScheme(.dark)
}
