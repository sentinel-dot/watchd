import SwiftUI

struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var successMessage: String?
    
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
                
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("🔐")
                            .font(.system(size: 60))
                        Text("Passwort vergessen?")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                        Text("Wir senden dir einen Link zum Zurücksetzen")
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 12)
                    
                    VStack(spacing: 18) {
                        AuthField(icon: "envelope.fill", placeholder: "E-Mail", text: $email, keyboardType: .emailAddress)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                                .multilineTextAlignment(.center)
                        }
                        
                        if let success = successMessage {
                            Text(success)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.2, green: 0.7, blue: 0.3))
                                .multilineTextAlignment(.center)
                        }
                        
                        PrimaryButton(title: "Link senden", isLoading: isLoading) {
                            Task { await sendResetLink() }
                        }
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.top, 60)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
    
    private func sendResetLink() async {
        guard !email.isEmpty else {
            errorMessage = "Bitte E-Mail eingeben"
            return
        }
        
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }
        
        do {
            let _ = try await APIService.shared.forgotPassword(email: email)
            successMessage = "Falls diese E-Mail registriert ist, wurde ein Reset-Link gesendet."
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                dismiss()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

struct ResetPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    let token: String
    
    @State private var newPassword = ""
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
                
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Text("🔑")
                            .font(.system(size: 60))
                        Text("Neues Passwort")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                        Text("Wähle ein sicheres Passwort")
                            .font(.system(size: 15))
                            .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                    }
                    .padding(.bottom, 12)
                    
                    VStack(spacing: 18) {
                        AuthField(icon: "lock.fill", placeholder: "Neues Passwort", text: $newPassword, isSecure: true)
                        AuthField(icon: "lock.fill", placeholder: "Passwort bestätigen", text: $confirmPassword, isSecure: true)
                        
                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(Color(red: 0.85, green: 0.30, blue: 0.25))
                                .multilineTextAlignment(.center)
                        }
                        
                        PrimaryButton(title: "Passwort ändern", isLoading: isLoading) {
                            Task { await resetPassword() }
                        }
                    }
                    .padding(28)
                    .background(
                        RoundedRectangle(cornerRadius: 28)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.08), radius: 24, y: 12)
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .padding(.top, 60)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Abbrechen") { dismiss() }
                }
            }
        }
    }
    
    private func resetPassword() async {
        guard newPassword.count >= 8 else {
            errorMessage = "Passwort muss mindestens 8 Zeichen lang sein"
            return
        }
        
        guard newPassword == confirmPassword else {
            errorMessage = "Passwörter stimmen nicht überein"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            let _ = try await APIService.shared.resetPassword(token: token, newPassword: newPassword)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview("Forgot Password") {
    ForgotPasswordView()
}

#Preview("Reset Password") {
    ResetPasswordView(token: "test-token")
}
