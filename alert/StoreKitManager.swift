//
//  StoreKitManager.swift
//  alert
//
//  StoreKit 2 integration for KidoAlert Premium subscriptions.
//  Handles purchase, restore, and background transaction updates.
//

import StoreKit
import Foundation

@MainActor
class StoreKitManager: ObservableObject {
    static let shared = StoreKitManager()

    // Product IDs registered in App Store Connect
    static let monthlyID = "com.kidoalert.premium.monthly"
    static let yearlyID  = "com.kidoalert.premium.yearly"

    @Published private(set) var products: [Product] = []
    @Published private(set) var isPremium = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var transactionListener: Task<Void, Error>?
    private let api = APIService.shared

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await refreshPremiumStatus()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Load Products

    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: [Self.monthlyID, Self.yearlyID])
            // Sort: monthly first, yearly second
            products = storeProducts.sorted { $0.id == Self.monthlyID ? true : false }
        } catch {
            errorMessage = "Erro ao carregar planos: \(error.localizedDescription)"
        }
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await handleVerifiedTransaction(transaction)
                await transaction.finish()

            case .userCancelled:
                break

            case .pending:
                // Awaiting approval (e.g. Ask to Buy)
                break

            @unknown default:
                break
            }
        } catch {
            errorMessage = "Erro na compra: \(error.localizedDescription)"
        }
    }

    // MARK: - Restore

    func restore() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshPremiumStatus()
        } catch {
            errorMessage = "Erro ao restaurar compras: \(error.localizedDescription)"
        }
    }

    // MARK: - Transaction Listener (background renewals / cancellations)

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard let self else { break }
                do {
                    let transaction = try await MainActor.run { try self.checkVerified(result) }
                    await self.handleVerifiedTransaction(transaction)
                    await transaction.finish()
                } catch {
                    print("❌ Transação inválida ignorada: \(error)")
                }
            }
        }
    }

    // MARK: - Internal Helpers

    private func handleVerifiedTransaction(_ transaction: Transaction) async {
        if transaction.revocationDate != nil {
            // Subscription revoked/refunded
            isPremium = false
        } else if let expiration = transaction.expirationDate, expiration < Date() {
            // Expired
            isPremium = false
        } else {
            // Valid subscription — send to backend for server-side validation
            isPremium = true
            await verifyWithBackend(transaction)
        }
    }

    private func verifyWithBackend(_ transaction: Transaction) async {
        do {
            // The backend expects the original transaction ID as the receipt identifier
            try await api.verifyAppleReceipt(String(transaction.originalID))
            await AuthManager.shared.refreshLimits()
            print("✅ Assinatura verificada no backend: \(transaction.productID)")
        } catch {
            // Non-fatal: app-side isPremium is already true; backend will catch up via webhook
            print("⚠️ Falha ao verificar no backend (será sincronizado via webhook): \(error)")
        }
    }

    private func refreshPremiumStatus() async {
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil,
                   let expiration = transaction.expirationDate,
                   expiration >= Date() {
                    isPremium = true
                    return
                }
            }
        }
        isPremium = false
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let value):
            return value
        }
    }
}

enum StoreError: LocalizedError {
    case failedVerification

    var errorDescription: String? {
        "Não foi possível verificar a compra. Tente novamente."
    }
}
