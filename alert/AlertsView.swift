import SwiftUI

struct AlertsView: View {
    @EnvironmentObject var appState: AppState
    @State private var showCreateAlert = false
    @State private var alertToEdit: LocationAlert?

    private var activeCount: Int { appState.alerts.filter { $0.isActive }.count }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color(.systemBackground).ignoresSafeArea()

            if appState.alerts.isEmpty {
                emptyState
            } else {
                alertsList
            }

            // FAB — only when list non-empty
            if !appState.alerts.isEmpty {
                Button(action: { showCreateAlert = true }) {
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
        .navigationTitle("Meus Alertas")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showCreateAlert) {
            NavigationStack {
                CreateAlertView().environmentObject(appState)
            }
        }
        .sheet(item: $alertToEdit) { alert in
            NavigationStack {
                CreateAlertView(editingAlert: alert).environmentObject(appState)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color(.systemGray5))
                    .frame(width: 80, height: 80)
                Image(systemName: "mappin.slash")
                    .font(.system(size: 36))
                    .foregroundColor(.secondary)
            }
            Text("Nenhum alerta criado")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
            Text("Crie seu primeiro alerta para receber notificações")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button(action: { showCreateAlert = true }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus").font(.system(size: 14, weight: .semibold))
                    Text("Criar Alerta").font(.system(size: 15, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Capsule().fill(Color.blue))
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Alerts List

    private var alertsList: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Counter header
                HStack {
                    Text("Alertas")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.primary)
                    Spacer()
                    Text("\(activeCount) de \(appState.alerts.count) ativos")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                ForEach(appState.alerts) { alert in
                    AlertCard(
                        alert: alert,
                        onEdit: { alertToEdit = alert },
                        onDelete: { appState.removeAlert(alert) },
                        onToggle: { isActive in
                            var updated = alert
                            updated.isActive = isActive
                            appState.updateAlert(updated)
                        }
                    )
                    .padding(.horizontal, 20)
                }

                Spacer().frame(height: 88)
            }
        }
    }
}

// MARK: - AlertCard
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
            // Header
            HStack(alignment: .top, spacing: 12) {
                // Icon box
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isActive ? Color.blue.opacity(0.1) : Color(.systemGray5))
                        .frame(width: 40, height: 40)
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(isActive ? .blue : Color(.systemGray))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(alert.name)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.primary)

                    Text(alert.address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    if let schedule = alert.scheduleDescription {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 10))
                            Text(schedule)
                                .font(.system(size: 11))
                        }
                        .foregroundColor(.blue.opacity(0.8))
                        .padding(.vertical, 3)
                        .padding(.horizontal, 8)
                        .background(Capsule().fill(Color.blue.opacity(0.1)))
                    }
                }

                Spacer()

                Toggle("", isOn: $isActive)
                    .labelsHidden()
                    .onChange(of: isActive) { _, newValue in
                        onToggle(newValue)
                    }
            }

            Divider()

            // Footer
            HStack {
                if let childName = alert.childName {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.child").font(.caption)
                        Text(childName).font(.caption)
                    }
                    .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { showDeleteConfirmation = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Excluir")
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color(.systemFill), lineWidth: 1)
                )
        )
        .opacity(isActive ? 1.0 : 0.7)
        .onTapGesture { onEdit() }
        .confirmationDialog(
            "Tem certeza que deseja excluir este alerta?",
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Excluir", role: .destructive) { onDelete() }
            Button("Cancelar", role: .cancel) {}
        } message: {
            Text("Esta ação não pode ser desfeita")
        }
    }
}

#Preview {
    NavigationStack {
        AlertsView().environmentObject(AppState())
    }
}
