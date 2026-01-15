//
//  HomeView.swift
//  alert
//
//  Main home screen for Responsável (Guardian) mode
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack(path: $appState.navigationPath) {
            VStack(spacing: 0) {
                // Main content
                ScrollView {
                    VStack(spacing: 20) {
                        // Header
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

                            // Mode toggle button (for testing)
                            Button(action: { appState.toggleMode() }) {
                                Image(systemName: "person.crop.circle")
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
        }
    }
}

// MARK: - Child Card Component
struct ChildCard: View {
    let child: Child
    @EnvironmentObject var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(child.name)
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 8, height: 8)

                        Text(child.status.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Battery indicator
                HStack(spacing: 4) {
                    Image(systemName: batteryIcon)
                        .foregroundColor(batteryColor)
                    Text("\(child.batteryLevel)%")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

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
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal)
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
