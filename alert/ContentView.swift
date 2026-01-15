//
//  ContentView.swift
//  alert
//
//  Main entry point - switches between splash, responsável, and criança modes
//  Phase 2: Includes permission flow
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var appState = AppState()
    @State private var hasSeenPermissionExplanation = DataManager.shared.hasSeenPermissionExplanation
    @State private var showPermissionView = false

    var body: some View {
        Group {
            if appState.showingSplash {
                SplashView()
            } else if showPermissionView {
                LocationPermissionView {
                    showPermissionView = false
                    hasSeenPermissionExplanation = true
                }
            } else {
                switch appState.userMode {
                case .responsavel:
                    HomeView()
                case .crianca:
                    ChildModeView()
                }
            }
        }
        .environmentObject(appState)
        .onAppear {
            appState.finishSplash()

            // Check if we need to show permission view after splash
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                checkPermissions()
            }
        }
    }

    private func checkPermissions() {
        let status = appState.locationManager.authorizationStatus

        // Show permission view if status is notDetermined (first time)
        // OR if denied and user hasn't seen explanation yet
        if status == .notDetermined {
            showPermissionView = true
        } else if status == .denied && !hasSeenPermissionExplanation {
            showPermissionView = true
        } else if status == .authorizedWhenInUse {
            // If only WhenInUse, show screen to upgrade to Always
            showPermissionView = true
        }
    }
}

#Preview {
    ContentView()
}
