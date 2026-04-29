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

    @State private var selectedChildIds: Set<String> = []
    @State private var alertName = ""
    @State private var address = ""
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: -23.5505, longitude: -46.6333),
        span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    )
    @State private var showPaywall = false
    @State private var didCenterOnUser = false
    @State private var showSearchResults = false
    @StateObject private var searchManager = AddressSearchManager()

    // Radius state
    @State private var selectedRadius: Double = 150.0
    private let radiusOptions: [(Double, String)] = [(100, "100m"), (150, "150m"), (200, "200m"), (500, "500m")]

    // Schedule state
    @State private var hasSchedule = false
    @State private var startTime = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date())!
    @State private var endTime = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date())!
    @State private var scheduleMode: ScheduleMode = .weekdays
    @State private var selectedDays: Set<Int> = [1, 2, 3, 4, 5]

    init(editingAlert: LocationAlert? = nil) {
        self.editingAlert = editingAlert
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
                            Text("Crianca")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if appState.children.isEmpty {
                                Text("Nenhuma crianca cadastrada")
                                    .foregroundColor(.orange)
                                    .font(.subheadline)
                            } else {
                                VStack(spacing: 6) {
                                    ForEach(appState.children) { child in
                                        let id = child.id.uuidString.lowercased()
                                        Button {
                                            if selectedChildIds.contains(id) {
                                                selectedChildIds.remove(id)
                                            } else {
                                                selectedChildIds.insert(id)
                                            }
                                        } label: {
                                            HStack(spacing: 10) {
                                                Image(systemName: selectedChildIds.contains(id) ? "checkmark.circle.fill" : "circle")
                                                    .foregroundColor(selectedChildIds.contains(id) ? .blue : .gray)
                                                Text(child.name)
                                                    .foregroundColor(.primary)
                                                Spacer()
                                            }
                                            .padding(.vertical, 8)
                                            .padding(.horizontal, 10)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(selectedChildIds.contains(id) ? Color.blue.opacity(0.1) : Color(.tertiarySystemBackground))
                                            )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    } else if let childName = editingAlert?.childName {
                        // Show child name in edit mode (read-only)
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Crianca")
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

                    // Address Search
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Endereco")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Buscar endereco...", text: $address)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                            .onChange(of: address) { _, newValue in
                                searchManager.search(query: newValue)
                                showSearchResults = !newValue.isEmpty
                            }

                        // Search Results
                        if showSearchResults && !searchManager.searchResults.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(searchManager.searchResults.prefix(5), id: \.self) { result in
                                    Button(action: {
                                        selectSearchResult(result)
                                    }) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(result.title)
                                                .font(.subheadline)
                                                .foregroundColor(.primary)
                                                .lineLimit(1)
                                            if !result.subtitle.isEmpty {
                                                Text(result.subtitle)
                                                    .font(.caption)
                                                    .foregroundColor(.secondary)
                                                    .lineLimit(1)
                                            }
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 10)
                                    }
                                    .buttonStyle(.plain)

                                    Divider()
                                }
                            }
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                        }
                    }
                }

                // Radius Section
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "circle.dashed")
                            .foregroundColor(.blue)
                        Text("Raio da Alerta")
                            .font(.headline)
                    }
                    HStack(spacing: 8) {
                        ForEach(radiusOptions, id: \.0) { value, label in
                            Button(action: { selectedRadius = value }) {
                                Text(label)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(selectedRadius == value ? .white : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(selectedRadius == value ? Color.blue : Color(.tertiarySystemBackground))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground).opacity(0.5))
                )

                // Schedule Section
                VStack(alignment: .leading, spacing: 16) {
                    Toggle(isOn: $hasSchedule) {
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .foregroundColor(.blue)
                            Text("Definir Horário")
                                .font(.headline)
                        }
                    }

                    if hasSchedule {
                        // Time Pickers
                        VStack(spacing: 12) {
                            DatePicker("Início", selection: $startTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)

                            DatePicker("Fim", selection: $endTime, displayedComponents: .hourAndMinute)
                                .datePickerStyle(.compact)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)

                        // Day Schedule
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Dias da Semana")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Picker("Modo", selection: $scheduleMode) {
                                ForEach(ScheduleMode.allCases, id: \.self) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .onChange(of: scheduleMode) { _, newValue in
                                switch newValue {
                                case .daily:
                                    selectedDays = Set(0...6)
                                case .weekdays:
                                    selectedDays = [1, 2, 3, 4, 5]
                                case .custom:
                                    break
                                }
                            }

                            if scheduleMode == .custom {
                                DayPickerView(selectedDays: $selectedDays)
                                    .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground).opacity(0.5))
                )

                // Map Selection
                VStack(alignment: .leading, spacing: 8) {
                    Text("Localizacao no Mapa")
                        .font(.headline)

                    Text("Arraste o mapa ou toque para ajustar a localizacao")
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

                    let infoNames: String = {
                        if isEditMode, let childName = editingAlert?.childName { return childName }
                        let selected = appState.children.filter { selectedChildIds.contains($0.id.uuidString.lowercased()) }
                        if selected.isEmpty { return "a crianca" }
                        return selected.map { $0.name }.joined(separator: " e ")
                    }()
                    Text("Voce sera notificado quando \(infoNames) chegar ou sair deste local")
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
                .disabled(!isAtLimit && (alertName.isEmpty || address.isEmpty || (!isEditMode && selectedChildIds.isEmpty)))
                .opacity(!isAtLimit && (alertName.isEmpty || address.isEmpty || (!isEditMode && selectedChildIds.isEmpty)) ? 0.5 : 1)
            }
            .padding()
        }
        .navigationTitle(isEditMode ? "Editar Alerta" : "Novo Alerta")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let alert = editingAlert {
                alertName = alert.name
                address = alert.address
                selectedRadius = alert.radius
                region = MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: alert.latitude, longitude: alert.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
                )

                // Populate schedule fields
                if let start = alert.startTime, let end = alert.endTime {
                    hasSchedule = true
                    startTime = dateFromTimeString(start)
                    endTime = dateFromTimeString(end)

                    let days = alert.scheduleDays ?? []
                    if days.isEmpty || days.count == 7 {
                        scheduleMode = .daily
                        selectedDays = Set(0...6)
                    } else if Set(days) == Set([1, 2, 3, 4, 5]) {
                        scheduleMode = .weekdays
                        selectedDays = Set(days)
                    } else {
                        scheduleMode = .custom
                        selectedDays = Set(days)
                    }
                }
            } else {
                // Center map on device location for new alerts
                if let location = appState.locationManager.currentLocation {
                    region = MKCoordinateRegion(
                        center: location.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )
                }

                if appState.children.count == 1, let firstChild = appState.children.first {
                    // Auto-select if only one child
                    selectedChildIds = [firstChild.id.uuidString.lowercased()]
                }
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

    // MARK: - Search

    private func selectSearchResult(_ result: MKLocalSearchCompletion) {
        address = [result.title, result.subtitle].filter { !$0.isEmpty }.joined(separator: ", ")
        showSearchResults = false
        searchManager.clear()

        Task {
            if let mapItem = await searchManager.geocode(completion: result) {
                let coordinate = mapItem.placemark.coordinate
                withAnimation {
                    region = MKCoordinateRegion(
                        center: coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                    )
                }
            }
        }
    }

    // MARK: - Helpers

    private func timeStringFromDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func dateFromTimeString(_ timeString: String) -> Date {
        let components = timeString.split(separator: ":").compactMap { Int($0) }
        guard components.count == 2 else { return Date() }
        return Calendar.current.date(bySettingHour: components[0], minute: components[1], second: 0, of: Date()) ?? Date()
    }

    private func handleSave() {
        if isAtLimit {
            showPaywall = true
        } else if editingAlert != nil {
            let alert = LocationAlert(
                id: editingAlert!.id,
                childId: editingAlert!.childId,
                childName: editingAlert!.childName,
                name: alertName,
                address: address,
                latitude: region.center.latitude,
                longitude: region.center.longitude,
                isActive: editingAlert!.isActive,
                radius: selectedRadius,
                startTime: hasSchedule ? timeStringFromDate(startTime) : nil,
                endTime: hasSchedule ? timeStringFromDate(endTime) : nil,
                scheduleDays: hasSchedule ? Array(selectedDays).sorted() : []
            )
            appState.updateAlert(alert)
            dismiss()
        } else {
            for childId in selectedChildIds {
                let childName = appState.children.first { $0.id.uuidString.lowercased() == childId }?.name
                let alert = LocationAlert(
                    id: UUID(),
                    childId: childId,
                    childName: childName,
                    name: alertName,
                    address: address,
                    latitude: region.center.latitude,
                    longitude: region.center.longitude,
                    isActive: true,
                    radius: selectedRadius,
                    startTime: hasSchedule ? timeStringFromDate(startTime) : nil,
                    endTime: hasSchedule ? timeStringFromDate(endTime) : nil,
                    scheduleDays: hasSchedule ? Array(selectedDays).sorted() : []
                )
                appState.addAlert(alert)
            }
            dismiss()
        }
    }
}

// MARK: - Day Picker (Apple Alarm Style)
struct DayPickerView: View {
    @Binding var selectedDays: Set<Int>

    private let days: [(Int, String, String)] = [
        (0, "D", "Domingo"),
        (1, "S", "Segunda"),
        (2, "T", "Terca"),
        (3, "Q", "Quarta"),
        (4, "Q", "Quinta"),
        (5, "S", "Sexta"),
        (6, "S", "Sabado"),
    ]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(days, id: \.0) { day in
                let isSelected = selectedDays.contains(day.0)

                Button(action: {
                    if isSelected {
                        selectedDays.remove(day.0)
                    } else {
                        selectedDays.insert(day.0)
                    }
                }) {
                    Text(day.1)
                        .font(.system(size: 14, weight: .semibold))
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(isSelected ? Color.blue : Color(.tertiarySystemBackground))
                        )
                        .foregroundColor(isSelected ? .white : .primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(day.2)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CreateAlertView()
            .environmentObject(AppState())
    }
}
