//
//  alertApp.swift
//  alert
//
//  Created by user289963 on 1/6/26.
//

import SwiftUI
import UserNotifications

// MARK: - App Delegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationManager.shared
        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        NotificationManager.shared.handleDeviceToken(deviceToken)
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        NotificationManager.shared.handleRegistrationError(error)
    }
}

// MARK: - Main App

@main
struct alertApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        // Configure NotificationManager with API service
        NotificationManager.shared.configure(with: APIService.shared)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
