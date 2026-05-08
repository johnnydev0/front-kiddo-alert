import Foundation
import MapKit
import Combine

struct AddressSearchResult: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    fileprivate let completion: MKLocalSearchCompletion?
    fileprivate let mapItem: MKMapItem?

    init(completion: MKLocalSearchCompletion) {
        self.title = completion.title
        self.subtitle = completion.subtitle
        self.completion = completion
        self.mapItem = nil
    }

    init(mapItem: MKMapItem) {
        self.title = mapItem.name ?? ""
        self.subtitle = mapItem.placemark.title ?? ""
        self.completion = nil
        self.mapItem = mapItem
    }

    var coordinate: CLLocationCoordinate2D? { mapItem?.placemark.coordinate }
}

@MainActor
class AddressSearchManager: NSObject, ObservableObject {
    @Published var searchResults: [AddressSearchResult] = []
    @Published var isSearching = false
    @Published var geocodeError: String?

    private let completer = MKLocalSearchCompleter()
    private var directSearchTask: Task<Void, Never>?
    private var useDirectSearch = false
    private var currentRegion: MKCoordinateRegion?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func setRegion(_ region: MKCoordinateRegion) {
        completer.region = region
        currentRegion = region
    }

    func search(query: String) {
        geocodeError = nil
        directSearchTask?.cancel()

        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            useDirectSearch = false
            return
        }

        isSearching = true

        // Queries com número usam busca direta — o completer não lida bem com numerações
        if query.contains(where: { $0.isNumber }) {
            useDirectSearch = true
            directSearchTask = Task { await searchDirect(query: query) }
        } else {
            useDirectSearch = false
            completer.queryFragment = query
        }
    }

    private func searchDirect(query: String) async {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        if let region = currentRegion {
            request.region = region
        }

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard !Task.isCancelled else { return }
            searchResults = response.mapItems.prefix(5).map { AddressSearchResult(mapItem: $0) }
        } catch {
            guard !Task.isCancelled else { return }
            searchResults = []
        }
        isSearching = false
    }

    func geocode(result: AddressSearchResult) async -> CLLocationCoordinate2D? {
        geocodeError = nil

        // Resultados da busca direta já têm coordenadas
        if let coordinate = result.coordinate { return coordinate }

        guard let completion = result.completion else { return nil }

        do {
            let request = MKLocalSearch.Request(completion: completion)
            let response = try await MKLocalSearch(request: request).start()
            return response.mapItems.first?.placemark.coordinate
        } catch {
            geocodeError = "Não foi possível encontrar o endereço. Verifique sua conexão e tente novamente."
            return nil
        }
    }

    func clear() {
        directSearchTask?.cancel()
        searchResults = []
        isSearching = false
        geocodeError = nil
        useDirectSearch = false
    }
}

extension AddressSearchManager: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            guard !self.useDirectSearch else { return }
            self.searchResults = completer.results.map { AddressSearchResult(completion: $0) }
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            guard !self.useDirectSearch else { return }
            self.isSearching = false
        }
    }
}
