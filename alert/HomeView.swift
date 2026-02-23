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
                        .environmentObject(appState)
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
        GeometryReader { proxy in
            ScrollView {
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
                                Text("Adicionar Crianca")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal, 40)

                        NavigationLink(value: "acceptGuardianInvite") {
                            HStack {
                                Image(systemName: "ticket")
                                Text("Tenho um codigo de convite")
                            }
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.green)
                        }
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
                                    title: "Ver Historico",
                                    color: .orange
                                )
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                    }
                }
                .frame(minHeight: proxy.size.height)
            }
            .refreshable {
                await appState.refreshChildren()
            }
        }
    }

    // MARK: - Children List View

    @ViewBuilder
    private var childrenListView: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
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
                    .frame(minHeight: proxy.size.height)
                }
                .refreshable {
                    await appState.refreshChildren()
                }
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
                            title: "Convidar Responsavel",
                            color: .green
                        )
                    }

                    NavigationLink(value: "acceptGuardianInvite") {
                        QuickActionButton(
                            icon: "ticket",
                            title: "Tenho um codigo",
                            color: .teal
                        )
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
    }
}
