//
//  PaywallView.swift
//  alert
//
//  Clean paywall screen - no pressure tactics
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var store = StoreKitManager.shared
    @State private var selectedProductID = StoreKitManager.yearlyID

    var selectedProduct: Product? {
        store.products.first { $0.id == selectedProductID }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.blue.opacity(0.1), .purple.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.purple.opacity(0.2))
                                .frame(width: 100, height: 100)

                            Image(systemName: "star.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.purple.gradient)
                        }

                        VStack(spacing: 8) {
                            Text("KidoAlert Premium")
                                .font(.title.bold())
                                .foregroundColor(.primary)

                            Text("Mais tranquilidade para sua família")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.top, 40)

                    // Features
                    VStack(spacing: 16) {
                        FeatureRow(
                            icon: "bell.badge.fill",
                            title: "Alertas Ilimitados",
                            description: "Crie quantos alertas precisar"
                        )

                        FeatureRow(
                            icon: "person.3.fill",
                            title: "Mais Crianças",
                            description: "Adicione até 50 crianças"
                        )

                        FeatureRow(
                            icon: "person.2.fill",
                            title: "Mais Responsáveis",
                            description: "Até 10 responsáveis por família"
                        )

                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Histórico Completo",
                            description: "Acesso a todos os eventos passados"
                        )

                        FeatureRow(
                            icon: "clock.badge.checkmark",
                            title: "Atualizações Mais Rápidas",
                            description: "Intervalo de 2 minutos"
                        )
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                    )

                    // Plan selector
                    VStack(spacing: 16) {
                        Text("Escolha seu plano")
                            .font(.headline)
                            .foregroundColor(.primary)

                        if store.products.isEmpty {
                            ProgressView()
                                .frame(height: 100)
                        } else {
                            HStack(spacing: 12) {
                                ForEach(store.products) { product in
                                    PricingCard(
                                        product: product,
                                        isSelected: selectedProductID == product.id
                                    )
                                    .onTapGesture {
                                        selectedProductID = product.id
                                        AnalyticsManager.shared.trackPaywallPlanSelected(planId: product.id)
                                    }
                                }
                            }
                        }
                    }

                    // Error message
                    if let error = store.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }

                    // CTA Button
                    Button(action: {
                        guard let product = selectedProduct else { return }
                        Task { await store.purchase(product) }
                    }) {
                        Group {
                            if store.isLoading {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .tint(.white)
                            } else if let product = selectedProduct {
                                Text("Continuar • \(product.displayPrice)")
                                    .font(.body.weight(.semibold))
                            } else {
                                Text("Continuar")
                                    .font(.body.weight(.semibold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(store.isLoading || selectedProduct == nil)

                    // Fine print
                    VStack(spacing: 8) {
                        Text("Cancele a qualquer momento")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("Seus alertas críticos nunca serão bloqueados")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Restore purchases (required by Apple)
                    Button(action: {
                        Task { await store.restore() }
                    }) {
                        Text("Restaurar Compras")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .disabled(store.isLoading)

                    Spacer()
                }
                .padding()
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .task {
            AnalyticsManager.shared.trackPaywallViewed()
            if store.products.isEmpty {
                await store.loadProducts()
            }
        }
        .onChange(of: store.isPremium) { _, isPremium in
            if isPremium { dismiss() }
        }
    }
}

// MARK: - Feature Row
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.purple.opacity(0.1))
                    .frame(width: 44, height: 44)

                Image(systemName: icon)
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - Pricing Card (real StoreKit product)
struct PricingCard: View {
    let product: Product
    let isSelected: Bool

    private var isYearly: Bool { product.id == StoreKitManager.yearlyID }
    private var period: String { isYearly ? "Anual" : "Mensal" }

    var body: some View {
        VStack(spacing: 12) {
            if isYearly {
                Text("POPULAR")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.purple))
            } else {
                Spacer().frame(height: 20)
            }

            Text(period)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            Text(product.displayPrice)
                .font(.title2.bold())
                .foregroundColor(.primary)

            if isYearly {
                Text("Economize 58%")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Spacer().frame(height: 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isSelected ? Color.purple.opacity(0.1) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                )
        )
    }
}

#Preview {
    PaywallView()
}
