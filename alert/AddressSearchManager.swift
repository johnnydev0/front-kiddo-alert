import Foundation
import MapKit
import Combine

@MainActor
class AddressSearchManager: NSObject, ObservableObject {
    @Published var searchResults: [MKLocalSearchCompletion] = []
    @Published var isSearching = false

    private let completer = MKLocalSearchCompleter()
    private var searchTask: Task<Void, Never>?

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.address, .pointOfInterest]
    }

    func search(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            isSearching = false
            return
        }

        isSearching = true
        completer.queryFragment = query
    }

    func geocode(completion: MKLocalSearchCompletion) async -> MKMapItem? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()
            return response.mapItems.first
        } catch {
            print("[AddressSearch] Geocode error: \(error)")
            return nil
        }
    }

    func clear() {
        searchResults = []
        isSearching = false
    }
}

// MARK: - MKLocalSearchCompleterDelegate
extension AddressSearchManager: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        Task { @MainActor in
            self.searchResults = completer.results
            self.isSearching = false
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        Task { @MainActor in
            self.isSearching = false
            print("[AddressSearch] Completer error: \(error)")
        }
    }
}
