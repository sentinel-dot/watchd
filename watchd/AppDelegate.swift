import UIKit
import UserNotifications
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    // Called when APNs successfully registers and returns a device token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task {
            do {
                try await APIService.shared.registerDeviceToken(token)
            } catch {
                // Non-fatal: push notifications simply won't arrive
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Expected in Simulator — ignore silently
    }

    // Google Sign-In: handle the OAuth redirect URL when the Google app is installed
    // and redirects back via custom URL scheme.
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }

    // Universal Links (https://watchd.up.railway.app/...).
    // Handled here instead of SwiftUI's onContinueUserActivity — AppDelegate is more reliable
    // and mirrors the push-notification routing pattern that already works.
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else { return false }

        Task { @MainActor in
            let parts = url.pathComponents.filter { $0 != "/" }

            if parts.first == "add", let rawCode = parts.dropFirst().first, !rawCode.isEmpty {
                guard AuthViewModel.shared.isAuthenticated else {
                    AppNavigation.queueAddPartnerCode(rawCode)
                    return
                }
                // Queue first, then switch tab — MainTabView.onChange consumes the queue
                // once the Partners tab is active, avoiding any tab-animation timing issues.
                AppNavigation.queueAddPartnerCode(rawCode)
                AppNavigation.openPartnersTab()
                return
            }

            if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
               components.path == "/reset-password",
               let token = components.queryItems?.first(where: { $0.name == "token" })?.value,
               !token.isEmpty {
                NotificationCenter.default.post(
                    name: NSNotification.Name("showResetPassword"),
                    object: nil,
                    userInfo: ["token": token]
                )
            }
        }
        return true
    }

    // Show notification banner even when app is in foreground
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        handleForegroundNotification(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            AppNavigation.routeNotificationTap(userInfo: userInfo)
        }
        completionHandler()
    }

    private func handleForegroundNotification(_ userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "partnership_request", "partnership_accepted":
            Task { @MainActor in
                AppNavigation.markPartnersTabNeedsAttention()
            }
        default:
            break
        }
    }
}
