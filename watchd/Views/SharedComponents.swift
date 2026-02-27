import SwiftUI

struct LoadingView: View {
    var message: String = "Lädt..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(Color(red: 0.85, green: 0.30, blue: 0.25))
                .scaleEffect(1.2)
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.96, blue: 0.94))
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?
    
    var body: some View {
        VStack(spacing: 20) {
            Text(icon)
                .font(.system(size: 72))
                .padding(.bottom, 8)
            
            Text(title)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
            
            Text(message)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 0.5, green: 0.5, blue: 0.5))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.85, green: 0.30, blue: 0.25),
                                    Color(red: 0.90, green: 0.40, blue: 0.35)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color(red: 0.85, green: 0.30, blue: 0.25).opacity(0.3), radius: 12, y: 6)
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.98, green: 0.96, blue: 0.94))
    }
}

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 16, weight: .semibold))
            
            Text("Keine Internetverbindung")
                .font(.system(size: 14, weight: .medium))
            
            Spacer()
        }
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(red: 0.85, green: 0.30, blue: 0.25))
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

#Preview("Loading") {
    LoadingView()
}

#Preview("Empty State") {
    EmptyStateView(
        icon: "film",
        title: "Keine Matches",
        message: "Swipe durch Filme und finde gemeinsame Favoriten mit deinem Partner",
        actionTitle: "Los geht's",
        action: {}
    )
}

#Preview("Offline Banner") {
    VStack {
        OfflineBanner()
        Spacer()
    }
}
