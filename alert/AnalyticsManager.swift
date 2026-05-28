import Foundation
import FirebaseAnalytics

@MainActor
final class AnalyticsManager {
    static let shared = AnalyticsManager()
    private init() {}

    // MARK: - Identity

    func identifyUser(id: String, email: String?, isPremium: Bool) {
        Analytics.setUserID(id)
        if let email { Analytics.setUserProperty(email, forName: "user_email") }
        Analytics.setUserProperty(isPremium ? "premium" : "free", forName: "subscription_status")
    }

    func setUserMode(_ mode: String) {
        Analytics.setUserProperty(mode, forName: "user_mode")
    }

    func setSubscriptionStatus(isPremium: Bool) {
        Analytics.setUserProperty(isPremium ? "premium" : "free", forName: "subscription_status")
    }

    func clearUser() {
        Analytics.setUserID(nil)
    }

    // MARK: - Paywall

    func trackPaywallViewed() {
        Analytics.logEvent("paywall_viewed", parameters: nil)
    }

    func trackPaywallPlanSelected(planId: String) {
        Analytics.logEvent("paywall_plan_selected", parameters: ["plan_id": planId])
    }

    func trackPurchaseStarted(planId: String) {
        Analytics.logEvent("purchase_started", parameters: ["plan_id": planId])
    }

    func trackPurchaseCompleted(planId: String) {
        Analytics.logEvent(AnalyticsEventPurchase, parameters: [
            AnalyticsParameterItemID: planId,
            AnalyticsParameterCurrency: "BRL"
        ])
    }

    func trackPurchaseCancelled(planId: String) {
        Analytics.logEvent("purchase_cancelled", parameters: ["plan_id": planId])
    }

    func trackPurchaseFailed(planId: String, error: String) {
        Analytics.logEvent("purchase_failed", parameters: [
            "plan_id": planId,
            "error": error
        ])
    }

    // MARK: - Features

    func trackFeatureUsed(_ feature: Feature) {
        Analytics.logEvent("feature_used", parameters: ["feature_name": feature.rawValue])
    }

    // MARK: - Auth

    func trackLogin() {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [AnalyticsParameterMethod: "email"])
    }

    func trackRegister() {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [AnalyticsParameterMethod: "email"])
    }

    enum Feature: String {
        case createAlert = "create_alert"
        case viewChildLocation = "view_child_location"
        case aiChat = "ai_chat"
        case viewHistory = "view_history"
        case inviteGuardian = "invite_guardian"
        case inviteChild = "invite_child"
    }
}
