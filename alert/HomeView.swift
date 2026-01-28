//
//  HomeView.swift
//  alert
//
//  Main home screen for Responsável (Guardian) mode
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState
    @State private var showLogoutConfirmation = false

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            VStack(spacing: 0) {
                // Main content
                if appState.children.isEmpty {
                    // Empty state
                    emptyStateView
                } else {
                    // Children list
                    childrenListView
                }
            }
            .onAppear {
                Task {
                    await appState.refreshChildren()
                }
            }
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
                    InviteView()
                case "paywall":
                    PaywallView()
                default:
                   Text("Unknown")
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
                Text("Voce sera desconectado e podera escolher um novo perfil (Responsavel ou Crianca).")
            }
        }
    }

    // MARK: - Empty State View

    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 0) {
            // Settings button at top right
            HStack {
                Spacer()
                Menu {
                    Button(role: .destructive) {
                        showLogoutConfirmation = true
                    } label: {
                        Label("Trocar Perfil", systemImage: "arrow.left.arrow.right")
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
            .padding()

            Spacer()

            // Empty state content
            VStack(spacing: 24) {
                Image(systemName: "figure.2.and.child.holdinghands")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue.gradient)

                VStack(spacing: 8) {
                    Text("Bem-vindo ao KidoAlert!")
                        .font(.title2.bold())

                    Text("Adicione sua primeira criança para começar a acompanhar a localização dela.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                NavigationLink(value: "addChild") {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Adicionar Criança")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }

            Spacer()

            // Secondary actions
            VStack(spacing: 0) {
                Divider()

                VStack(spacing: 12) {
                    NavigationLink(value: "alerts") {
                        QuickActionButton(
                            icon: "mappin.circle.fill",
                            title: "Configurar Alertas",
                            color: .purple
                        )
                    }

                    NavigationLink(value: "history") {
                        QuickActionButton(
                            icon: "clock.fill",
                            title: "Ver Histórico",
                            color: .orange
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
    }

    // MARK: - Children List View

    @ViewBuilder
    private var childrenListView: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 20) {
                    // Header with settings

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Suas Crianças")
                                .font(.title.bold())
                                .foregroundColor(.primary)

                            Text("Toque para ver detalhes")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        // Settings menu
                        Menu {
                            Button(role: .destructive) {
                                showLogoutConfirmation = true
                            } label: {
                                Label("Trocar Perfil", systemImage: "arrow.left.arrow.right")
                            }
                        } label: {
                            Image(systemName: "gearshape.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding()

                    // Children Cards
                    ForEach(appState.children) { child in
                        ChildCard(child: child)
                            .environmentObject(appState)
                            .onTapGesture {
                                appState.selectedChild = child
                                appState.navigationPath.append("childDetail")
                            }
                    }

                    // Add some bottom padding so content doesn't hide under menu
                    Spacer()
                        .frame(height: 80)
                }
                .padding(.vertical)
            }
            .refreshable {
                await appState.refreshChildren()
            }

            // Quick Actions Menu at Bottom
            VStack(spacing: 0) {
                Divider()

                VStack(spacing: 12) {
                    NavigationLink(value: "addChild") {
                        QuickActionButton(
                            icon: "person.badge.plus",
                            title: "Adicionar Criança",
                            color: .blue
                        )
                    }

                    NavigationLink(value: "alerts") {
                        QuickActionButton(
                            icon: "mappin.circle.fill",
                            title: "Alertas",
                            color: .purple
                        )
                    }

                    NavigationLink(value: "history") {
                        QuickActionButton(
                            icon: "clock.fill",
                            title: "Ver Histórico",
                            color: .orange
                        )
                    }

                    NavigationLink(value: "invite") {
                        QuickActionButton(
                            icon: "person.2.fill",
                            title: "Convidar Responsável",
                            color: .green
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
    }
}

// MARK: - Child Card Component
struct ChildCard: View {
    let child: Child
    @EnvironmentObject var appState: AppState
    @State private var showInviteSheet = false
    @State private var inviteCode: String?
    @State private var isGeneratingCode = false

    // Child hasn't accepted invite if userId is not set on backend
    private var isPendingInvite: Bool {
        !child.hasAcceptedInvite
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name)
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    if isPendingInvite {
                        // Pending invite status
                        HStack(spacing: 6) {
                            Image(systemName: "clock.badge.questionmark")
                                .foregroundColor(.orange)
                            Text("Aguardando aprovação")
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                    } else {
                        // Normal status
                        HStack(spacing: 6) {
                            Circle()
                                .fill(statusColor)
                                .frame(width: 8, height: 8)

                            Text(child.status.rawValue)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()

                if !isPendingInvite {
                    // Battery indicator (only show if accepted)
                    HStack(spacing: 4) {
                        Image(systemName: batteryIcon)
                            .foregroundColor(batteryColor)
                        Text("\(child.batteryLevel)%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            if isPendingInvite {
                // Pending invite actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("A criança ainda não aceitou o convite")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(action: generateNewInvite) {
                        HStack(spacing: 6) {
                            if isGeneratingCode {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "ticket")
                            }
                            Text("Gerar Novo Código")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.orange)
                        .cornerRadius(8)
                    }
                    .disabled(isGeneratingCode)
                }
            } else {
                // Normal card footer
                HStack {
                    Text("Atualizado há \(child.lastUpdateMinutes) min")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button(action: {
                        appState.selectedChild = child
                        appState.navigationPath.append("childDetail")
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "location.fill")
                            Text("Ver Mapa")
                        }
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.blue)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .overlay(
            isPendingInvite ?
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.orange.opacity(0.3), lineWidth: 2)
            : nil
        )
        .padding(.horizontal)
        .sheet(isPresented: $showInviteSheet) {
            inviteCodeSheet
        }
    }

    // MARK: - Invite Code Sheet

    @ViewBuilder
    private var inviteCodeSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                if let code = inviteCode {
                    VStack(spacing: 16) {
                        Image(systemName: "ticket.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.orange)

                        Text("Código de Convite")
                            .font(.title2.bold())

                        Text("para \(child.name)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(code)
                            .font(.system(size: 36, weight: .bold, design: .monospaced))
                            .tracking(4)
                            .foregroundColor(.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.secondarySystemBackground))
                            )

                        Text("Compartilhe este código com a criança")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        VStack(spacing: 12) {
                            Button {
                                UIPasteboard.general.string = code
                            } label: {
                                HStack {
                                    Image(systemName: "doc.on.doc")
                                    Text("Copiar Código")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Button {
                                shareCode(code)
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Compartilhar")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)

                        Text("Este código expira em 7 dias")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)

                        Text("Erro ao gerar código")
                            .font(.title2.bold())

                        Text("Tente novamente mais tarde")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Convite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fechar") {
                        showInviteSheet = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func generateNewInvite() {
        isGeneratingCode = true

        Task {
            do {
                inviteCode = try await appState.generateInviteCode(for: child)
                showInviteSheet = true
            } catch {
                print("❌ Erro ao gerar código: \(error)")
            }
            isGeneratingCode = false
        }
    }

    private func shareCode(_ code: String) {
        let message = """
        Olá! Baixe o app KidoAlert e use o código \(code) para conectar comigo.

        1. Baixe o KidoAlert
        2. Selecione "Sou Criança"
        3. Digite o código: \(code)
        """

        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }

    private var statusColor: Color {
        switch child.status {
        case .emCasa: return .green
        case .naEscola: return .blue
        case .compartilhamentoPausado: return .gray
        case .emTransito: return .orange
        }
    }

    private var batteryIcon: String {
        if child.batteryLevel > 50 {
            return "battery.100"
        } else if child.batteryLevel > 20 {
            return "battery.50"
        } else {
            return "battery.25"
        }
    }

    private var batteryColor: Color {
        child.batteryLevel > 20 ? .green : .red
    }
}

// MARK: - Quick Action Button
struct QuickActionButton: View {
    let icon: String
    let title: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)

            Text(title)
                .font(.body.weight(.medium))
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}
