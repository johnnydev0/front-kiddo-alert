//
//  LocationPermissionView.swift
//  alert
//
//  Phase 2: Permission explanation screen
//

import SwiftUI
import CoreLocation
import Combine

struct LocationPermissionView: View {
    @EnvironmentObject var appState: AppState
    @State private var showingSettings = false
    @State private var hasRequestedWhenInUse = false
    @State private var hasRequestedAlways = false

    var onPermissionGranted: () -> Void

    var body: some View {
        VStack(spacing: 30) {
            Spacer()

            // Icon
            Image(systemName: "location.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.blue)

            // Title
            Text("Localização")
                .font(.largeTitle)
                .fontWeight(.bold)

            // Explanation
            VStack(alignment: .leading, spacing: 16) {
                PermissionBenefit(
                    icon: "bell.fill",
                    text: "Receba alertas quando seus filhos chegarem ou saírem de lugares importantes"
                )

                PermissionBenefit(
                    icon: "lock.fill",
                    text: "Seus dados são privados e seguros. Não fazemos rastreamento contínuo"
                )

                PermissionBenefit(
                    icon: "battery.100",
                    text: "Sistema otimizado para não gastar bateria desnecessariamente"
                )
            }
            .padding(.horizontal)

            Spacer()

            // Permission status
            if appState.locationManager.authorizationStatus == .denied ||
               appState.locationManager.authorizationStatus == .restricted {
                VStack(spacing: 12) {
                    Text("Permissão negada")
                        .foregroundColor(.orange)
                        .font(.callout)

                    Button(action: {
                        openSettings()
                    }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Abrir Configurações")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            } else {
                Button(action: {
                    requestPermission()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Permitir Localização")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }

            // Skip button (not recommended)
            Button("Agora não") {
                onPermissionGranted()
            }
            .foregroundColor(.gray)
            .padding(.bottom, 30)
        }
        .onReceive(appState.locationManager.$authorizationStatus) { newStatus in
            handleAuthorizationChange(newStatus)
        }
    }

    private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
        switch status {
        case .authorizedWhenInUse:
            if !hasRequestedAlways {
                hasRequestedAlways = true
                // Delay to ensure iOS is ready for second permission request
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.appState.locationManager.requestLocationPermission()
                }
            }
        case .authorizedAlways:
            DataManager.shared.hasSeenPermissionExplanation = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                onPermissionGranted()
            }
        case .denied, .restricted:
            break
        default:
            break
        }
    }

    private func requestPermission() {
        let currentStatus = appState.locationManager.authorizationStatus

        if currentStatus == .notDetermined {
            hasRequestedWhenInUse = true
        }

        appState.locationManager.requestLocationPermission()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

struct PermissionBenefit: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)

            Text(text)
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    LocationPermissionView(onPermissionGranted: {})
        .environmentObject(AppState())
}
