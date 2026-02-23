import SwiftUI

struct ChildModeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutConfirmation = false
    @State private var isPulseAnimating = false

    var isSharing: Bool {
        appState.locationManager.isLocationSharingActive
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Spacer()
                Button(action: { showLogoutConfirmation = true }) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .padding(10)
                }
            }
            .padding(.horizontal, 12)

            Spacer()

            // Status icon with pulse
            ZStack {
                if isSharing {
                    Circle()
                        .fill(Color.green.opacity(0.1))
                        .frame(width: 160, height: 160)
                        .scaleEffect(isPulseAnimating ? 1.15 : 1.0)
                        .opacity(isPulseAnimating ? 0 : 0.3)
                        .animation(
                            .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                            value: isPulseAnimating
                        )

                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 140, height: 140)
                }

                Circle()
                    .fill(isSharing ? Color.green.opacity(0.1) : Color(.systemGray5))
                    .frame(width: 112, height: 112)
                    .overlay(
                        Circle()
                            .stroke(
                                isSharing ? Color.green.opacity(0.2) : Color(.systemGray4),
                                lineWidth: 4
                            )
                    )

                Image(systemName: isSharing ? "location.fill" : "location.slash.fill")
                    .font(.system(size: 48))
                    .foregroundColor(isSharing ? .green : Color(.systemGray))
            }
            .animation(.easeInOut(duration: 0.3), value: isSharing)

            Spacer().frame(height: 28)

            // Status text
            Text(isSharing ? "Compartilhando localização" : "Compartilhamento pausado")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(isSharing ? .green : Color(.systemGray))
                .multilineTextAlignment(.center)

            Spacer().frame(height: 8)

            Text(isSharing
                ? "Seus responsáveis podem ver sua localização"
                : "Seus responsáveis não podem ver sua localização agora")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            // Guardian chips
            if !appState.guardians.isEmpty {
                Spacer().frame(height: 28)

                Text("QUEM ESTÁ VENDO")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .tracking(1.5)

                Spacer().frame(height: 10)

                FlowLayout(spacing: 8) {
                    ForEach(appState.guardians.prefix(4), id: \.id) { guardian in
                        GuardianChip(name: guardian.name ?? "Responsável")
                    }
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            // Action buttons
            VStack(spacing: 12) {
                Button(action: toggleSharing) {
                    HStack(spacing: 8) {
                        Image(systemName: isSharing ? "pause.fill" : "play.fill")
                            .font(.system(size: 16))
                        Text(isSharing ? "Pausar Compartilhamento" : "Retomar Compartilhamento")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(isSharing ? .primary : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(isSharing ? Color.clear : Color.green)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(isSharing ? Color(.systemGray3) : Color.clear, lineWidth: 2)
                            )
                    )
                }

                Button(action: { /* accept invite */ }) {
                    HStack(spacing: 6) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 15))
                        Text("Aceitar convite de responsável")
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground).ignoresSafeArea())
        .onAppear {
            appState.startLocationTracking()
            if appState.guardians.isEmpty {
                Task { await appState.loadGuardians() }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                isPulseAnimating = true
            }
        }
        .alert("Trocar Perfil", isPresented: $showLogoutConfirmation) {
            Button("Cancelar", role: .cancel) { }
            Button("Trocar", role: .destructive) {
                Task { await appState.logout() }
            }
        } message: {
            Text("Voce sera desconectado e podera escolher um novo perfil.")
        }
    }

    private func toggleSharing() {
        Task {
            if isSharing {
                await appState.pauseLocationSharing()
            } else {
                await appState.resumeLocationSharing()
            }
        }
    }
}

// MARK: - GuardianChip
private struct GuardianChip: View {
    let name: String

    private var initials: String {
        let parts = name.split(separator: " ").prefix(2)
        let result = parts.compactMap { $0.first.map { String($0).uppercased() } }.joined()
        return result.isEmpty ? "?" : result
    }

    private var chipColor: Color {
        let colors: [Color] = [
            Color(red: 0.23, green: 0.48, blue: 0.84),
            Color(red: 1.0,  green: 0.58, blue: 0.0),
            Color(red: 0.20, green: 0.78, blue: 0.35),
            Color(red: 0.69, green: 0.32, blue: 0.87)
        ]
        return colors[abs(name.hashValue) % colors.count]
    }

    var body: some View {
        HStack(spacing: 8) {
            ZStack {
                Circle().fill(chipColor)
                Text(initials)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 28, height: 28)

            Text(name)
                .font(.system(size: 13))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(.secondarySystemBackground))
                .overlay(Capsule().stroke(Color(.systemFill).opacity(0.5), lineWidth: 1))
        )
    }
}

// MARK: - FlowLayout (wrapping badge layout)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        arrange(proposal: proposal, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, lineH: CGFloat = 0, totalW: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 { x = 0; y += lineH + spacing; lineH = 0 }
            positions.append(CGPoint(x: x, y: y))
            lineH = max(lineH, size.height)
            x += size.width + spacing
            totalW = max(totalW, x - spacing)
        }
        return (CGSize(width: totalW, height: y + lineH), positions)
    }
}

#Preview {
    ChildModeView()
        .environmentObject(AppState())
}
