import Foundation
import Combine
import UserNotifications
import UIKit

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized = false
    @Published var deviceToken: String?

    private var api: APIService?

    private override init() {
        super.init()	
    }

    func configure(with api: APIService) {
        self.api = api
    }

    func requestPermission() async {
        let center = UNUserNotificationCenter.current()

        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted

            if granted {
                await registerForRemoteNotifications()
            }
        } catch {
            print("[Notifications] Error requesting permission: \(error)")
        }
    }

    func checkAuthorizationStatus() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        isAuthorized = settings.authorizationStatus == .authorized

        if isAuthorized {
            await registerForRemoteNotifications()
        }
    }

    private func registerForRemoteNotifications() async {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }

    func handleDeviceToken(_ tokenData: Data) {
        let token = tokenData.map { String(format: "%02.2hhx", $0) }.joined()
        deviceToken = token
        print("[Notifications] Device token: \(token)")

        Task {
            await registerTokenWithBackend(token)
        }
    }

    func handleRegistrationError(_ error: Error) {
        print("[Notifications] Failed to register: \(error.localizedDescription)")
    }

    private func registerTokenWithBackend(_ token: String) async {
        guard let api = api else {
            print("[Notifications] API not configured")
            return
        }

        do {
            try await api.registerPushToken(token)
            print("[Notifications] Token registered with backend")
        } catch {
            print("[Notifications] Failed to register token with backend: \(error)")
        }
    }

    func unregisterToken() async {
        guard let api = api, let token = deviceToken else { return }

        do {
            try await api.removePushToken(token)
            print("[Notifications] Token unregistered from backend")
        } catch {
            print("[Notifications] Failed to unregister token: \(error)")
        }
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo

        // Handle notification tap
        if let type = userInfo["type"] as? String {
            Task { @MainActor in
                handleNotificationTap(type: type, userInfo: userInfo)
            }
        }

        completionHandler()
    }

    @MainActor
    private func handleNotificationTap(type: String, userInfo: [AnyHashable: Any]) {
        // Post notification to navigate to relevant screen
        switch type {
        case "arrival", "departure", "late_arrival", "late_departure":
            if let childId = userInfo["childId"] as? String {
                NotificationCenter.default.post(
                    name: .didReceiveGeofenceNotification,
                    object: nil,
                    userInfo: ["childId": childId]
                )
            }
        case "invite_accepted":
            NotificationCenter.default.post(
                name: .didReceiveInviteNotification,
                object: nil
            )
        case "location_paused", "location_resumed":
            if let childId = userInfo["childId"] as? String {
                NotificationCenter.default.post(
                    name: .didReceiveLocationStatusNotification,
                    object: nil,
                    userInfo: ["childId": childId]
                )
            }
        default:
            break
        }
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let didReceiveGeofenceNotification = Notification.Name("didReceiveGeofenceNotification")
    static let didReceiveInviteNotification = Notification.Name("didReceiveInviteNotification")
    static let didReceiveLocationStatusNotification = Notification.Name("didReceiveLocationStatusNotification")
}
