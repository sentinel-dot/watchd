import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.06, green: 0.06, blue: 0.12), Color(red: 0.12, green: 0.04, blue: 0.20)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 8) {
                    Text("🎬")
                        .font(.system(size: 64))
                    Text("Watchd")
                        .font(.system(size: 40, weight: .black, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
                        )
                    Text("Find your next watch together")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.bottom, 40)

                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        TabButton(title: "Login", isSelected: selectedTab == 0) { selectedTab = 0 }
                        TabButton(title: "Register", isSelected: selectedTab == 1) { selectedTab = 1 }
                    }
                    .padding(4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    if selectedTab == 0 {
                        LoginForm()
                            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
                    } else {
                        RegisterForm()
                            .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: selectedTab)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .padding(.horizontal, 20)

                Spacer()
                Spacer()
            }
        }
    }
}

// MARK: - Login Form

private struct LoginForm: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 16) {
            AuthField(icon: "envelope.fill", placeholder: "Email", text: $email, keyboardType: .emailAddress)
            AuthField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)

            if let msg = authVM.errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            PrimaryButton(title: "Log In", isLoading: authVM.isLoading) {
                Task { await authVM.login(email: email, password: password) }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }
}

// MARK: - Register Form

private struct RegisterForm: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""

    var body: some View {
        VStack(spacing: 16) {
            AuthField(icon: "person.fill", placeholder: "Name", text: $name)
            AuthField(icon: "envelope.fill", placeholder: "Email", text: $email, keyboardType: .emailAddress)
            AuthField(icon: "lock.fill", placeholder: "Password", text: $password, isSecure: true)

            if let msg = authVM.errorMessage {
                Text(msg)
                    .font(.caption)
                    .foregroundColor(.red.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            PrimaryButton(title: "Create Account", isLoading: authVM.isLoading) {
                Task { await authVM.register(name: name, email: email, password: password) }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 28)
    }
}

// MARK: - Shared Components

private struct TabButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? Color.purple.opacity(0.7) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 10))
        }
    }
}

struct AuthField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isSecure: Bool = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 20)

            if isSecure {
                SecureField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            } else {
                TextField(placeholder, text: $text)
                    .foregroundColor(.white)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(keyboardType == .emailAddress ? .never : .words)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct PrimaryButton: View {
    let title: String
    let isLoading: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(.circular)
                        .tint(.white)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(colors: [.pink, .purple], startPoint: .leading, endPoint: .trailing)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .disabled(isLoading)
    }
}

#Preview {
    AuthView()
        .environmentObject(AuthViewModel())
}
