//
//  ChildModeView.swift
//  alert
//
//  Extremely simple interface for child mode
//  Shows sharing status and allows pause/resume
//  Phase 2: Real location sharing control
//

import SwiftUI

struct ChildModeView: View {
    @EnvironmentObject var appState: AppState

    var isSharing: Bool {
        appState.locationManager.isLocationSharingActive
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: isSharing ? [.blue.opacity(0.1), .purple.opacity(0.1)] : [.gray.opacity(0.1), .gray.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Status Icon
                ZStack {
                    Circle()
                        .fill(isSharing ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 140, height: 140)

                    Image(systemName: isSharing ? "checkmark.shield.fill" : "pause.circle.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(isSharing ? Color.blue.gradient : Color.gray.gradient)
                }
                .animation(.easeInOut, value: isSharing)

                // Status Text
                VStack(spacing: 12) {
                    Text(isSharing ? "Compartilhamento Ativo" : "Compartilhamento Pausado")
                        .font(.title.bold())
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)

                    if isSharing {
                        Text("Seus responsáveis podem ver sua localização")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    } else {
                        Text("Seus responsáveis foram avisados")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }

                Spacer()

                // Who can see
                if isSharing {
                    VStack(spacing: 8) {
                        Text("Quem está vendo:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(spacing: 16) {
                            ResponsavelBadge(name: "Mamãe")
                            ResponsavelBadge(name: "Papai")
                        }
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground).opacity(0.8))
                    )
                    .padding(.horizontal)
                }

                // Main Action Button
                Button(action: toggleSharing) {
                    HStack {
                        Image(systemName: isSharing ? "pause.fill" : "play.fill")
                        Text(isSharing ? "Pausar Compartilhamento" : "Retomar Compartilhamento")
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isSharing ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }
                .padding(.horizontal, 40)

                // Trust message
                Text(isSharing ? "Você pode pausar a qualquer momento" : "Você pode retomar a qualquer momento")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Mode toggle (for testing)
                HStack(spacing: 20) {
                    Button(action: { appState.toggleMode() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Modo Responsável")
                        }
                        .font(.caption)
                        .foregroundColor(.blue)
                    }

                    Button(action: { appState.resetToMockData() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                            Text("Resetar Dados")
                        }
                        .font(.caption)
                        .foregroundColor(.red)
                    }
                }
                .padding(.bottom)

                Spacer()
            }
        }
        .onAppear {
            // Start location tracking when child mode view appears
            appState.startLocationTracking()
        }
    }

    private func toggleSharing() {
        withAnimation(.spring()) {
            if isSharing {
                appState.locationManager.pauseLocationSharing()
            } else {
                appState.locationManager.resumeLocationSharing()
            }
        }
    }
}

// MARK: - Responsável Badge
struct ResponsavelBadge: View {
    let name: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.blue)

            Text(name)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.blue.opacity(0.1))
        )
    }
}

#Preview {
    ChildModeView()
        .environmentObject(AppState())
}
