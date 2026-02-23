import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            mainContent
                .toolbar(.hidden, for: .navigationBar)
                .navigationDestination(for: String.self) { destination in
                    switch destination {
                    case "childDetail":
                        if let child = appState.selectedChild {
                            ChildDetailView(child: child)
                        }
                    case "addChild":
                        AddChildView()
                    case "alerts":
                        AlertsView()
                    case "history":
                        HistoryView()
                    case "invite":
                        InviteView().environmentObject(appState)
                    case "acceptGuardianInvite":
                        GuardianInviteAcceptView()
                    case "paywall":
                        PaywallView()
                    default:
                        Text("Unknown")
                    }
                }
                .alert("Trocar Perfil", isPresented: $showLogoutConfirmation) {
                    Button("Cancelar", role: .cancel) { }
                    Button("Trocar", role: .destructive) {
                        Task { await appState.logout() }
                    }
                } message: {
                    Text("Voce sera desconectado e podera escolher um novo perfil (Responsavel ou Crianca).")
                }
        }
    }

    // MARK: - Main Content

    private var mainContent: some View {
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
                // Custom header
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        KidoLogoView(size: 32)
                        Text("KidoAlert")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    Menu {
                        Button(role: .destructive) {
                            showLogoutConfirmation = true
                        } label: {
                            Label("Trocar Perfil", systemImage: "arrow.left.arrow.right")
                        }
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))

                // Quick chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        QuickChip(icon: "bell.fill", label: "Alertas") {
                            appState.navigationPath.append("alerts")
                        }
                        QuickChip(icon: "clock.fill", label: "Historico") {
                            appState.navigationPath.append("history")
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                }
                .background(Color(.systemBackground))

                if appState.children.isEmpty {
                    emptyStateView
                } else {
                    childrenListView
                }
            }

            // FAB — only when list non-empty
            if !appState.children.isEmpty {
                Button(action: { appState.navigationPath.append("addChild") }) {
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 56, height: 56)
                        .background(Circle().fill(Color.blue))
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(20)
            }
        }
        .onAppear {
            Task { await appState.refreshChildren() }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer().frame(height: 60)

                ZStack {
                    Circle()
                        .fill(Color(.systemGray5))
                        .frame(width: 80, height: 80)
                    Image(systemName: "mappin")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary)
                }

                VStack(spacing: 6) {
                    Text("Nenhuma criança adicionada")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.primary)
                    Text("Adicione sua primeira criança para começar a monitorar")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }

                NavigationLink(value: "addChild") {
                    HStack(spacing: 6) {
                        Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
                        Text("Adicionar Criança").font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Capsule().fill(Color.blue))
                }

                NavigationLink(value: "acceptGuardianInvite") {
                    HStack(spacing: 4) {
                        Image(systemName: "ticket").font(.system(size: 13))
                        Text("Tenho um código de convite").font(.subheadline.weight(.medium))
                    }
                    .foregroundColor(.green)
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity)
        }
        .refreshable { await appState.refreshChildren() }
    }

    // MARK: - Children List

    private var childrenListView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                // Section header
                HStack {
                    Text("Suas Crianças")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(appState.children.count) criança\(appState.children.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                ForEach(appState.children) { child in
                    ChildCard(child: child)
                        .environmentObject(appState)
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            appState.selectedChild = child
                            appState.navigationPath.append("childDetail")
                        }
                }

                Spacer().frame(height: 88)
            }
            .padding(.vertical, 8)
        }
        .refreshable { await appState.refreshChildren() }
    }
}

// MARK: - QuickChip
private struct QuickChip: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(.blue)
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color(.secondarySystemBackground))
                    .overlay(Capsule().stroke(Color(.systemFill), lineWidth: 1))
            )
        }
        .buttonStyle(.plain)
    }
}
