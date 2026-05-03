import Foundation
import GoogleSignIn
import UIKit

// All GIDSignIn interaction is isolated here so the rest of the app
// never needs to import GoogleSignIn directly.
struct GoogleSignInHelper {

    // Returns (idToken, googleUserId) or nil if the user cancelled.
    // Throws GoogleSignInError on configuration or SDK failures.
    @MainActor
    static func signIn() async throws -> (idToken: String, googleUserId: String)? {
        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        else {
            throw GoogleSignInError.noRootViewController
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                throw GoogleSignInError.missingIdToken
            }
            let googleUserId = result.user.userID ?? ""
            // Sign out immediately — we manage sessions via JWT, not Google's session.
            GIDSignIn.sharedInstance.signOut()
            return (idToken: idToken, googleUserId: googleUserId)
        } catch let error as GIDSignInError where error.code == .canceled {
            return nil
        }
    }
}

enum GoogleSignInError: LocalizedError {
    case noRootViewController
    case missingIdToken

    var errorDescription: String? {
        switch self {
        case .noRootViewController:
            return "Google-Anmeldung fehlgeschlagen. Bitte versuche es erneut."
        case .missingIdToken:
            return "Google-Anmeldung fehlgeschlagen. Bitte versuche es erneut."
        }
    }
}
