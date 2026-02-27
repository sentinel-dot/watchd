import SwiftUI

struct UpgradeAccountView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authVM: AuthViewModel
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.96, blue: 0.94),
                        Color(red: 0.96, green: 0.93, blue: 0.90)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        VStack(spacing: 12) {
                            Text("⬆️")
                                .font(.system(size: 60))
                            Text("Konto erstellen")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                            Text("Sichere deine Daten mit einem Konto")
                                .font(.system(size: 15))
                                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 40)
                        .padding(.bottom, 12)
                        
                        VStack(spacing: 18) {
                            AuthField(icon: "envelope.fill", placeholder: "E-Mail", text: $email, keyboardType: .emailAddress)
                            AuthField(icon: "lock.fill", placeholder: "Passwort", text: $password, isSecure: true)
                            AuthField(icon: "lock.fill", placeholder: "Passwort bestätigen", text: $confirmPassword, isSecure: true)
                            
                            if let error = errorMessage {
                                Text(error)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                                    .multilineTextAlignment(.center)
                            }
                            
                            PrimaryButton(title: "Konto erstellen", isLoading: isLoading) {
                                Task { await upgradeAccount() }
                            }
                            .padding(.top, 4)
                        }
                        .padding(28)
                        .background(
                            RoundedRectangle(cornerRadius: 28)
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
                        )
                        .padding(.horizontal, 24)
                        
                        VStack(spacing: 12) {
                            Text("Deine Vorteile:")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                            
                            VStack(alignment: .leading, spacing: 10) {
                                BenefitRow(icon: "lock.shield.fill", text: "Deine Rooms und Matches bleiben erhalten")
                                BenefitRow(icon: "arrow.triangle.2.circlepath", text: "Passwort zurücksetzen möglich")
                                BenefitRow(icon: "iphone.and.arrow.forward", text: "Auf mehreren Geräten nutzbar")
                            }
                            .padding(.horizontal, 32)
                        }
                        .padding(.top, 8)
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
    
    private func upgradeAccount() async {
        guard !email.isEmpty else {
            errorMessage = "Bitte E-Mail eingeben"
            return
        }
        
        guard password.count >= 8 else {
            errorMessage = "Passwort muss mindestens 8 Zeichen lang sein"
            return
        }
        
        guard password == confirmPassword else {
            errorMessage = "Passwörter stimmen nicht überein"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        await authVM.upgradeAccount(email: email, password: password)
        
        if authVM.errorMessage == nil {
            dismiss()
        } else {
            errorMessage = authVM.errorMessage
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(Color(red: 0.3, green: 0.3, blue: 0.3))
            
            Spacer()
        }
    }
}

#Preview {
    UpgradeAccountView()
        .environmentObject(AuthViewModel.shared)
}
