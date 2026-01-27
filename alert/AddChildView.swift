//
//  AddChildView.swift
//  alert
//
//  Screen to add a new child to the family
//

import SwiftUI

struct AddChildView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var appState: AppState

    @State private var childName = ""
    @State private var showPaywall = false
    @State private var linkGenerated = false
    @State private var mockInviteLink = "kiddoalert://child/xyz789abc"
    @State private var showCopiedMessage = false

    var currentChildrenCount: Int {
        appState.children.count
    }

    var maxChildren: Int {
        appState.mockData.maxFreeChildren
    }

    var isAtLimit: Bool {
        currentChildrenCount >= maxChildren
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 30) {
                // Header Icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.badge.plus.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                    }

                    VStack(spacing: 8) {
                        Text("Adicionar Criança")
                            .font(.title2.bold())
                            .foregroundColor(.primary)

                        Text("Convide a criança para conectar")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)

                // Counter with Premium CTA
                VStack(spacing: 12) {
                    HStack {
                        Text("\(currentChildrenCount) de \(maxChildren) crianças")
                            .font(.subheadline)
                            .foregroundColor(isAtLimit ? .orange : .secondary)

                        Spacer()

                        if isAtLimit {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                        }
                    }

                    if isAtLimit {
                        Button(action: { showPaywall = true }) {
                            HStack {
                                Image(systemName: "star.fill")
                                Text("Upgrade para Premium")
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )

                // Explanation steps
                VStack(alignment: .leading, spacing: 20) {
                    Text("Como Funciona")
                        .font(.headline)

                    StepRow(
                        number: 1,
                        title: "Digite o nome da criança",
                        description: "Para identificar no app"
                    )

                    StepRow(
                        number: 2,
                        title: "Gere um link de convite",
                        description: "Compartilhe com a criança"
                    )

                    StepRow(
                        number: 3,
                        title: "A criança aceita no app dela",
                        description: "E o compartilhamento começa"
                    )
                }

                Divider()

                // Form
                VStack(alignment: .leading, spacing: 16) {
                    Text("Informacoes da Crianca")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Nome")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        TextField("Ex: Joao, Maria", text: $childName)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.words)
                            .disableAutocorrection(true)
                    }

                    if !linkGenerated && !childName.isEmpty {
                        Button(action: generateInvite) {
                            HStack {
                                Image(systemName: "link.circle.fill")
                                Text("Gerar Link de Convite")
                                    .font(.body.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isAtLimit ? Color.orange : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }

                // Link display (after generation)
                if linkGenerated {
                    VStack(spacing: 16) {
                        Divider()

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)

                                Text("Link Gerado!")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }

                            Text("Compartilhe este link com \(childName)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        // Link box
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Link de Convite")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text(mockInviteLink)
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                                    .lineLimit(1)
                                    .truncationMode(.middle)

                                Spacer()

                                Button(action: copyLink) {
                                    Image(systemName: showCopiedMessage ? "checkmark" : "doc.on.doc")
                                        .foregroundColor(showCopiedMessage ? .green : .blue)
                                }
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(.tertiarySystemBackground))
                            )
                        }

                        // Share button
                        Button(action: shareLink) {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                Text("Compartilhar Link")
                                    .font(.body.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        // Expiration info
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("Este link expira em 7 dias")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)

                        // Done button
                        Button(action: { dismiss() }) {
                            Text("Concluir")
                                .font(.body.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .foregroundColor(.primary)
                                .cornerRadius(12)
                        }
                    }
                }

                // Info boxes
                if !linkGenerated {
                    VStack(spacing: 12) {
                        InfoBox(
                            icon: "lock.shield.fill",
                            text: "A criança sempre precisa aceitar o convite",
                            color: .blue
                        )

                        InfoBox(
                            icon: "hand.raised.fill",
                            text: "Ela pode pausar o compartilhamento a qualquer momento",
                            color: .orange
                        )
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Adicionar Criança")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    private func generateInvite() {
        if isAtLimit {
            showPaywall = true
        } else {
            withAnimation {
                linkGenerated = true
            }
        }
    }

    private func copyLink() {
        UIPasteboard.general.string = mockInviteLink

        withAnimation {
            showCopiedMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
    }

    private func shareLink() {
        // Mock - in real app would show share sheet
    }
}

// MARK: - Step Row Component
struct StepRow: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Info Box Component
struct InfoBox: View {
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
        AddChildView()
            .environmentObject(AppState())
    }
}
