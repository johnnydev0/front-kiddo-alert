//
//  AlertsView.swift
//  alert
//
//  Screen to view, manage, activate/deactivate and delete location alerts
//

import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreateAlert = false
    @State private var alertToEdit: LocationAlert?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            // Background to ensure full frame
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Content
            if appState.alerts.isEmpty {
                // Empty State
                VStack(spacing: 20) {
                    Spacer()

                    ZStack {
                        Circle()
                            .fill(Color.purple.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "mappin.slash")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)
                    }

                    Text("Nenhum Alerta Criado")
                        .font(.title2.bold())
                        .foregroundColor(.primary)

                    Text("Crie alertas para ser notificado quando suas criancas chegarem ou sairem de locais importantes")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // List of Alerts
                ScrollView {
                    VStack(spacing: 16) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Meus Alertas")
                                    .font(.title.bold())
                                    .foregroundColor(.primary)

                                Text("\(appState.alerts.count) de \(appState.mockData.maxFreeAlerts) alertas")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.horizontal)
                        .padding(.top)

                        // Alert Cards
                        ForEach(appState.alerts) { alert in
                            AlertCard(alert: alert, onEdit: {
                                alertToEdit = alert
                            }, onDelete: {
                                appState.removeAlert(alert)
                            }, onToggle: { isActive in
                                var updatedAlert = alert
                                updatedAlert.isActive = isActive
                                appState.updateAlert(updatedAlert)
                            })
                        }
                        .padding(.horizontal)

                        // Bottom padding for FAB
                        Spacer()
                            .frame(height: 100)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .id(appState.alerts.count)
            }

            // Floating Action Button
            Button(action: { showCreateAlert = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                    Text("Novo Alerta")
                        .font(.body.weight(.semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(
                    Capsule()
                        .fill(Color.blue)
                        .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                )
            }
            .padding()
        }
        .navigationTitle("Alertas")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateAlert) {
            NavigationStack {
                CreateAlertView()
                    .environmentObject(appState)
            }
        }
        .sheet(item: $alertToEdit) { alert in
            NavigationStack {
                CreateAlertView(editingAlert: alert)
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Alert Card Component
struct AlertCard: View {
    let alert: LocationAlert
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onToggle: (Bool) -> Void
    @State private var isActive: Bool
    @State private var showDeleteConfirmation = false

    init(alert: LocationAlert, onEdit: @escaping () -> Void, onDelete: @escaping () -> Void, onToggle: @escaping (Bool) -> Void) {
        self.alert = alert
        self.onEdit = onEdit
        self.onDelete = onDelete
        self.onToggle = onToggle
        self._isActive = State(initialValue: alert.isActive)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with toggle
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "mappin.circle.fill")
                            .foregroundColor(isActive ? .purple : .gray)

                        Text(alert.name)
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                    }

                    Text(alert.address)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()

                Toggle("", isOn: $isActive)
                    .labelsHidden()
                    .onChange(of: isActive) { oldValue, newValue in
                        onToggle(newValue)
                    }
            }

            Divider()

            // Details and actions
            HStack {
                // Child name
                if let childName = alert.childName {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.child")
                            .font(.caption)
                        Text(childName)
                            .font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                // Delete button
                Button(action: { showDeleteConfirmation = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Excluir")
                    }
                    .font(.subheadline)
                    .foregroundColor(.red)
                }
            }

            // Status indicator
            if !isActive {
                HStack(spacing: 6) {
                    Image(systemName: "pause.circle.fill")
                        .font(.caption)
                    Text("Alerta pausado")
                        .font(.caption)
                }
                .foregroundColor(.orange)
                .padding(.vertical, 6)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .fill(Color.orange.opacity(0.1))
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 4)
        )
        .opacity(isActive ? 1 : 0.7)
        .onTapGesture {
            onEdit()
        }
        .confirmationDialog(
            "Tem certeza que deseja excluir este alerta?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) {
                deleteAlert()
            }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta acao nao pode ser desfeita")
        }
    }

    private func deleteAlert() {
        onDelete()
    }
}

// MARK: - Info Banner
struct InfoBanner: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
        )
    }
}

#Preview {
    NavigationStack {
        AlertsView()
            .environmentObject(AppState())
    }
}
