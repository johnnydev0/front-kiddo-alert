//
//  CreateAlertView.swift
//  alert
//
//  Screen to create a new location alert
//  Phase 2: Creates real geofences
//

import SwiftUI
import MapKit

struct CreateAlertView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    let editingAlert: LocationAlert?

    @State private var selectedChildId: String = ""
    @State private var alertName = ""
    @State private var address = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var showPaywall = false

    init(editingAlert: LocationAlert? = nil) {
        self.editingAlert = editingAlert
    }

    var selectedChild: Child? {
        appState.children.first { $0.id.uuidString.lowercased() == selectedChildId.lowercased() }
    }

    var currentAlertsCount: Int {
        appState.alerts.count
    }

    var maxAlerts: Int {
        appState.mockData.maxFreeAlerts
    }

    var isAtLimit: Bool {
        // If editing, don't count the current alert
        if editingAlert != nil {
            return false
        }
        return currentAlertsCount >= maxAlerts
    }

    var isEditMode: Bool {
        editingAlert != nil
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Counter
                HStack {
                    Text("\(currentAlertsCount) de \(maxAlerts) alertas usados")
                        .font(.subheadline)
                        .foregroundColor(isAtLimit ? .orange : .secondary)

                    Spacer()

                    if isAtLimit {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )

                // Form Fields
                VStack(alignment: .leading, spacing: 20) {
                    Text("Detalhes do Alerta")
                        .font(.headline)

                    // Child Picker (only for new alerts)
                    if !isEditMode {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Criança")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if appState.children.isEmpty {
                                Text("Nenhuma criança cadastrada")
                                    .foregroundColor(.orange)
                                    .font(.subheadline)
                            } else {
                                Picker("Selecione a criança", selection: $selectedChildId) {
                                    Text("Selecione...").tag("")
                                    ForEach(appState.children) { child in
                                        Text(child.name).tag(child.id.uuidString.lowercased())
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(10)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                            }
                        }
                    } else if let childName = editingAlert?.childName {
                        // Show child name in edit mode (read-only)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Criança")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text(childName)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(8)
                        }
                    }

                    // Alert Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nome do Local")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Ex: Escola, Casa da Vovo", text: $alertName)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }

                    // Address
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Endereco")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Digite o endereco", text: $address)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }
                }

                // Map Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Localização no Mapa")
                        .font(.headline)

                    Text("Arraste o mapa ou toque para ajustar a localização")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ZStack {
                        Map(coordinateRegion: $region)
                            .frame(height: 250)
                            .cornerRadius(12)

                        // Fixed pin in center
                        Image(systemName: "mappin.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                            .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 2)
                    }

                    // Show coordinates
                    Text("Lat: \(region.center.latitude, specifier: "%.4f"), Lon: \(region.center.longitude, specifier: "%.4f")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                }

                // Info box
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)

                    if let child = selectedChild {
                        Text("Você será notificado quando \(child.name) chegar ou sair deste local")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if isEditMode, let childName = editingAlert?.childName {
                        Text("Você será notificado quando \(childName) chegar ou sair deste local")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Você será notificado quando a criança chegar ou sair deste local")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )

                // Save Button
                Button(action: handleSave) {
                    HStack {
                        if isAtLimit {
                            Image(systemName: "star.fill")
                        }
                        Text(isAtLimit ? "Desbloquear Mais Alertas" : (isEditMode ? "Salvar Alteracoes" : "Salvar Alerta"))
                            .font(.body.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isAtLimit ? Color.orange : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!isAtLimit && (alertName.isEmpty || address.isEmpty || (!isEditMode && selectedChildId.isEmpty)))
                .opacity(!isAtLimit && (alertName.isEmpty || address.isEmpty || (!isEditMode && selectedChildId.isEmpty)) ? 0.5 : 1)
            }
            .padding()
        }
        .navigationTitle(isEditMode ? "Editar Alerta" : "Novo Alerta")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let alert = editingAlert {
                selectedChildId = alert.childId
                alertName = alert.name
                address = alert.address
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: alert.latitude, longitude: alert.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
            } else if appState.children.count == 1, let firstChild = appState.children.first {
                // Auto-select if only one child
                selectedChildId = firstChild.id.uuidString.lowercased()
            }
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func handleSave() {
        if isAtLimit {
            showPaywall = true
        } else {
            // Get child info
            let childId = isEditMode ? (editingAlert?.childId ?? "") : selectedChildId
            let childName = isEditMode ? editingAlert?.childName : selectedChild?.name

            let alert = LocationAlert(
                id: editingAlert?.id ?? UUID(),
                childId: childId,
                childName: childName,
                name: alertName,
                address: address,
                latitude: region.center.latitude,
                longitude: region.center.longitude,
                isActive: editingAlert?.isActive ?? true
            )

            if editingAlert != nil {
                appState.updateAlert(alert)
            } else {
                appState.addAlert(alert)
            }

            dismiss()
        }
    }
}

#Preview {
    NavigationStack {
        CreateAlertView()
            .environmentObject(AppState())
    }
}
