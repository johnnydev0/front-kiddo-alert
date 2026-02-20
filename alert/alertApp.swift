//
//  alertApp.swift
//  alert
//
//  Created by user289963 on 1/6/26.
//

import SwiftUI
import UserNotifications
import CoreLocation
import UIKit

// MARK: - App Delegate for Push Notifications

class AppDelegate: NSObject, UIApplicationDelegate {
    private var backgroundLocationHelper: BackgroundLocationHelper?

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

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let type = userInfo["type"] as? String else {
            completionHandler(.noData)
            return
        }

        if type == "request_location" {
            print("[AppDelegate] Location request received from guardian")
            handleLocationRequest(completionHandler: completionHandler)
        } else {
            completionHandler(.noData)
        }
    }

    private func handleLocationRequest(completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let helper = BackgroundLocationHelper { location in
            guard let location = location else {
                print("[AppDelegate] No location available")
                completionHandler(.failed)
                return
            }

            print("[AppDelegate] Got location: \(location.coordinate.latitude), \(location.coordinate.longitude)")

            Task {
                do {
                    let device = UIDevice.current
                    device.isBatteryMonitoringEnabled = true
                    let batteryLevel = device.batteryLevel >= 0 ? Int(device.batteryLevel * 100) : nil

                    let _ = try await APIService.shared.updateLocation(
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        batteryLevel: batteryLevel
                    )
                    print("[AppDelegate] Location sent to backend on request")
                    completionHandler(.newData)
                } catch {
                    print("[AppDelegate] Failed to send location: \(error)")
                    completionHandler(.failed)
                }
            }
        }

        self.backgroundLocationHelper = helper
        helper.requestLocation()
    }
}

// MARK: - Background Location Helper

private class BackgroundLocationHelper: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let completion: (CLLocation?) -> Void

    init(completion: @escaping (CLLocation?) -> Void) {
        self.completion = completion
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        // Try cached location first
        if let cached = locationManager.location,
           Date().timeIntervalSince(cached.timestamp) < 60 {
            print("[BackgroundLocationHelper] Using cached location")
            completion(cached)
            return
        }

        // Request fresh location
        locationManager.requestLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        completion(locations.last)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[BackgroundLocationHelper] Location error: \(error)")
        // Try cached as fallback
        if let cached = locationManager.location {
            completion(cached)
        } else {
            completion(nil)
        }
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
