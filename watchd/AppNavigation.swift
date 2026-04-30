import Foundation

@MainActor
enum AppNavigation {
    private static let pendingAddPartnerCodeKey = "pending_add_partner_code"
    private static let pendingPartnershipIdKey = "pending_partnership_id"

    static func normalizedShareCode(from raw: String) -> String? {
        let code = AddPartnerViewModel.normalize(raw)
        return code.count == AddPartnerViewModel.codeLength ? code : nil
    }

    static func queueAddPartnerCode(_ raw: String) {
        guard let code = normalizedShareCode(from: raw) else { return }
        UserDefaults.standard.set(code, forKey: pendingAddPartnerCodeKey)
    }

    static func queuePartnership(id: Int) {
        UserDefaults.standard.set(id, forKey: pendingPartnershipIdKey)
    }

    static func clearQueuedPartnership(id: Int) {
        guard UserDefaults.standard.integer(forKey: pendingPartnershipIdKey) == id else { return }
        UserDefaults.standard.removeObject(forKey: pendingPartnershipIdKey)
    }

    @MainActor
    static func openAddPartner(rawCode: String) {
        guard let code = normalizedShareCode(from: rawCode) else { return }
        NotificationCenter.default.post(
            name: .watchdOpenAddPartner,
            object: nil,
            userInfo: ["code": code]
        )
    }

    @MainActor
    static func openPartnersTab(markNeedsAttention: Bool = false) {
        NotificationCenter.default.post(
            name: .watchdOpenPartnersTab,
            object: nil,
            userInfo: ["markNeedsAttention": markNeedsAttention]
        )
    }

    @MainActor
    static func openPartnership(id: Int) {
        NotificationCenter.default.post(
            name: .watchdOpenPartnership,
            object: nil,
            userInfo: ["partnershipId": id]
        )
    }

    @MainActor
    static func markPartnersTabNeedsAttention() {
        NotificationCenter.default.post(name: .watchdPartnersTabNeedsAttention, object: nil)
    }

    @MainActor
    static func consumePendingNavigation() {
        if let code = UserDefaults.standard.string(forKey: pendingAddPartnerCodeKey) {
            UserDefaults.standard.removeObject(forKey: pendingAddPartnerCodeKey)
            openPartnersTab()
            openAddPartner(rawCode: code)
        }

        if UserDefaults.standard.object(forKey: pendingPartnershipIdKey) != nil {
            let id = UserDefaults.standard.integer(forKey: pendingPartnershipIdKey)
            openPartnersTab()
            openPartnership(id: id)
        }
    }

    @MainActor
    static func routeNotificationTap(userInfo: [AnyHashable: Any]) {
        guard let type = userInfo["type"] as? String else { return }

        switch type {
        case "partnership_request":
            openPartnersTab()
        case "partnership_accepted", "match":
            if let partnershipId = partnershipId(from: userInfo) {
                queuePartnership(id: partnershipId)
                openPartnersTab()
                openPartnership(id: partnershipId)
            } else {
                openPartnersTab()
            }
        default:
            break
        }
    }

    private static func partnershipId(from userInfo: [AnyHashable: Any]) -> Int? {
        if let id = userInfo["partnershipId"] as? Int {
            return id
        }
        if let id = userInfo["partnershipId"] as? String {
            return Int(id)
        }
        return nil
    }
}

extension Notification.Name {
    static let watchdOpenAddPartner = Notification.Name("watchdOpenAddPartner")
    static let watchdOpenPartnersTab = Notification.Name("watchdOpenPartnersTab")
    static let watchdOpenPartnership = Notification.Name("watchdOpenPartnership")
    static let watchdPartnersTabNeedsAttention = Notification.Name("watchdPartnersTabNeedsAttention")
}
