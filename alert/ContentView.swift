//
//  ContentView.swift
//  alert
//
//  Main entry point - switches between splash, auth, and main views
//  Phase 2: Includes permission flow
//  Phase 3: Includes authentication flow
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
            } else if appState.needsModeSelection {
                // Phase 3: Show mode selection for new users
                ModeSelectionView()
            } else if appState.needsProfileSetup {
                // Profile setup for new users (name and email)
                ProfileSetupView()
            } else if showPermissionView {
                LocationPermissionView {
                    showPermissionView = false
                    hasSeenPermissionExplanation = true
                }
            } else {
                // Main app views
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
        // Show error alerts
        .alert("Erro", isPresented: .init(
            get: { appState.errorMessage != nil },
            set: { if !$0 { appState.errorMessage = nil } }
        )) {
            Button("OK") {
                appState.errorMessage = nil
            }
        } message: {
            if let error = appState.errorMessage {
                Text(error)
            }
        }
    }

    private func checkPermissions() {
        // Don't check permissions if still in auth/setup flow
        guard !appState.needsModeSelection && !appState.needsProfileSetup else { return }

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
