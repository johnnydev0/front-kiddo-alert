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
    @State private var showLogoutConfirmation = false

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
                if isSharing && !appState.guardians.isEmpty {
                    VStack(spacing: 8) {
                        Text("Quem está vendo:")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        // Wrap in a flexible layout for multiple guardians
                        FlowLayout(spacing: 8) {
                            ForEach(appState.guardians, id: \.id) { guardian in
                                ResponsavelBadge(name: guardian.name ?? "Responsável")
                            }
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

                // Settings button
                Button(action: { showLogoutConfirmation = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                        Text("Trocar Perfil")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.bottom)

                Spacer()
            }
        }
        .onAppear {
            // Start location tracking when child mode view appears
            appState.startLocationTracking()
            // Load guardians if not loaded yet
            if appState.guardians.isEmpty {
                Task {
                    await appState.loadGuardians()
                }
            }
        }
        .alert("Trocar Perfil", isPresented: $showLogoutConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Trocar", role: .destructive) {
                Task {
                    await appState.logout()
                }
            }
        } message: {
            Text("Voce sera desconectado e podera escolher um novo perfil.")
        }
    }

    private func toggleSharing() {
        Task {
            withAnimation(.spring()) {
                // Update UI immediately
            }
            if isSharing {
                await appState.pauseLocationSharing()
            } else {
                await appState.resumeLocationSharing()
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

// MARK: - Flow Layout for wrapping badges
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalWidth: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)

            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalWidth = max(totalWidth, currentX - spacing)
        }

        return (CGSize(width: totalWidth, height: currentY + lineHeight), positions)
    }
}

#Preview {
    ChildModeView()
        .environmentObject(AppState())
}
