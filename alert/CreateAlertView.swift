//
//  CreateAlertView.swift
//  alert
//
//  Screen to create a new location alert
//

import SwiftUI
import MapKit

struct CreateAlertView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    let editingAlert: LocationAlert?

    @State private var alertName = ""
    @State private var address = ""
    @State private var expectedTime = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var showPaywall = false

    init(editingAlert: LocationAlert? = nil) {
        self.editingAlert = editingAlert
    }

    var currentAlertsCount: Int {
        appState.mockData.alerts.count
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

                    // Expected Time (optional)
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Horario Esperado (opcional)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Ex: 08:00", text: $expectedTime)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.numbersAndPunctuation)
                            .disableAutocorrection(true)
                    }
                }

                // Map Selection (Mock)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Localização no Mapa")
                        .font(.headline)

                    Text("Toque no mapa para ajustar a localização")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Map(coordinateRegion: $region)
                        .frame(height: 200)
                        .cornerRadius(12)
                        .disabled(true) // Mock - no interaction in Phase 1
                        .overlay(
                            Image(systemName: "mappin.circle.fill")
                                .font(.largeTitle)
                                .foregroundColor(.red)
                        )
                }

                // Info box
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)

                    Text("Você será notificado quando a criança chegar ou sair deste local")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )

                // Save Button
                Button(action: handleSave) {
                    Text(isAtLimit ? "Desbloquear Mais Alertas" : (isEditMode ? "Salvar Alteracoes" : "Salvar Alerta"))
                        .font(.body.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isAtLimit ? Color.orange : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(alertName.isEmpty || address.isEmpty)
                .opacity((alertName.isEmpty || address.isEmpty) ? 0.5 : 1)
            }
            .padding()
        }
        .navigationTitle(isEditMode ? "Editar Alerta" : "Novo Alerta")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let alert = editingAlert {
                alertName = alert.name
                address = alert.address
                expectedTime = alert.expectedTime ?? ""
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: alert.latitude, longitude: alert.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )
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
            // Mock save - just dismiss
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
