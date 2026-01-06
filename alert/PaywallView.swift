//
//  PaywallView.swift
//  alert
//
//  Clean paywall screen (mock) - no pressure tactics
//

import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Background
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

                    // Pricing (mock)
                    VStack(spacing: 16) {
                        Text("Escolha seu plano")
                            .font(.headline)
                            .foregroundColor(.primary)

                        HStack(spacing: 12) {
                            PricingCard(
                                period: "Mensal",
                                price: "R$ 9,90",
                                isPopular: false
                            )

                            PricingCard(
                                period: "Anual",
                                price: "R$ 89,90",
                                savings: "Economize 25%",
                                isPopular: true
                            )
                        }
                    }

                    // CTA Button
                    Button(action: {}) {
                        Text("Continuar")
                            .font(.body.weight(.semibold))
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

                    // Restore purchases
                    Button(action: {}) {
                        Text("Restaurar Compras")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

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

// MARK: - Pricing Card
struct PricingCard: View {
    let period: String
    let price: String
    var savings: String? = nil
    let isPopular: Bool

    var body: some View {
        VStack(spacing: 12) {
            if isPopular {
                Text("POPULAR")
                    .font(.caption2.weight(.bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.purple)
                    )
            } else {
                Spacer()
                    .frame(height: 20)
            }

            Text(period)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.primary)

            Text(price)
                .font(.title2.bold())
                .foregroundColor(.primary)

            if let savings = savings {
                Text(savings)
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                Spacer()
                    .frame(height: 16)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPopular ? Color.purple.opacity(0.1) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isPopular ? Color.purple : Color.clear, lineWidth: 2)
                )
        )
    }
}

#Preview {
    PaywallView()
}
