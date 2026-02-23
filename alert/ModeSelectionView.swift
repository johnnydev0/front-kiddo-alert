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
        VStack(spacing: 0) {
            // Hero section
            VStack(spacing: 8) {
                KidoLogoView(size: 64)
                Text("Alertas de chegada para quem você ama")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(Color(.secondarySystemBackground))

            // Cards section
            VStack(alignment: .leading, spacing: 16) {
                Text("Como você quer usar o KidoAlert?")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                ModeCard(
                    icon: "shield.fill",
                    title: "Sou Responsável",
                    description: "Acompanhe a localização dos seus filhos e receba alertas de chegada",
                    color: .blue,
                    borderColor: Color.blue.opacity(0.2)
                ) {
                    selectMode(.responsavel)
                }

                ModeCard(
                    icon: "figure.child",
                    title: "Sou Filho(a)",
                    description: "Compartilhe sua localização com seus responsáveis de forma segura",
                    color: .green,
                    borderColor: Color.green.opacity(0.2)
                ) {
                    selectMode(.crianca)
                }
            }
            .padding(24)
            .disabled(isLoading)

            if isLoading {
                ProgressView().padding()
            }

            if let error = errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            Text("Sua privacidade é importante. Dados de localização são compartilhados apenas com os responsáveis autorizados.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
    }

    private func selectMode(_ mode: UserMode) {
        isLoading = true
        errorMessage = nil

        if mode == .crianca {
            Task {
                do {
                    let user = try await appState.authManager.authenticateDeviceSilently(mode: .crianca)
                    if user.hasLinkedChild == true {
                        appState.userMode = .crianca
                        appState.authManager.publishAuthState(user)
                        appState.locationManager.startLocationUpdates()
                        print("✅ Criança já vinculada, pulando convite")
                    } else {
                        showChildInviteView = true
                    }
                } catch {
                    showChildInviteView = true
                }
                isLoading = false
            }
            return
        }

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
    let borderColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(color.opacity(0.1))
                        .frame(width: 56, height: 56)
                    Image(systemName: icon)
                        .font(.system(size: 26))
                        .foregroundColor(color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(3)
                }

                Spacer()
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(borderColor, lineWidth: 2)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ModeSelectionView()
        .environmentObject(AppState())
}
