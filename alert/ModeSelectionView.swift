//
//  ModeSelectionView.swift
//  alert
//
//  Phase 3: Onboarding screen for mode selection
//  User chooses between Guardian and Child mode
//

import SwiftUI

struct ModeSelectionView: View {
    @EnvironmentObject var appState: AppState
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showChildInviteView = false

    var body: some View {
        if showChildInviteView {
            ChildInviteView(onBack: { showChildInviteView = false })
                .environmentObject(appState)
        } else {
            modeSelectionContent
        }
    }

    var modeSelectionContent: some View {
        VStack(spacing: 40) {
            Spacer()

            // Logo and title
            VStack(spacing: 16) {
                Image(systemName: "mappin.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(.blue.gradient)

                Text("KidoAlert")
                    .font(.system(size: 32, weight: .bold, design: .rounded))

                Text("Como você vai usar o app?")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Mode selection cards
            VStack(spacing: 16) {
                ModeCard(
                    icon: "person.2.fill",
                    title: "Sou Responsável",
                    description: "Monitore a localização das crianças e receba alertas quando chegarem ou saírem de locais",
                    color: .blue
                ) {
                    selectMode(.responsavel)
                }

                ModeCard(
                    icon: "figure.child",
                    title: "Sou Criança",
                    description: "Compartilhe sua localização com seus responsáveis de forma segura",
                    color: .green
                ) {
                    selectMode(.crianca)
                }
            }
            .padding(.horizontal)
            .disabled(isLoading)

            if isLoading {
                ProgressView()
                    .padding()
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            // Footer
            Text("Seus dados são protegidos e nunca compartilhados sem permissão")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom)
        }
    }

    private func selectMode(_ mode: UserMode) {
        isLoading = true
        errorMessage = nil

        if mode == .crianca {
            Task {
                do {
                    // Try to authenticate first to check if already linked
                    let user = try await appState.authManager.authenticateDeviceSilently(mode: .crianca)

                    if user.hasLinkedChild == true {
                        // Already linked - go straight to child mode
                        appState.userMode = .crianca
                        appState.authManager.publishAuthState(user)
                        appState.locationManager.startLocationUpdates()
                        print("✅ Criança já vinculada, pulando convite")
                    } else {
                        // Not linked yet - show invite code screen
                        showChildInviteView = true
                    }
                } catch {
                    // Auth failed - show invite screen as fallback
                    showChildInviteView = true
                }
                isLoading = false
            }
            return
        }

        // Guardian mode - authenticate directly
        Task {
            await appState.authenticateAsGuardian()

            isLoading = false

            if let error = appState.errorMessage {
                errorMessage = error
            }
        }
    }
}

struct ModeCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                    .frame(width: 60)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ModeSelectionView()
        .environmentObject(AppState())
}
