//
//  InviteView.swift
//  alert
//
//  Screen to generate and share invite links
//

import SwiftUI

struct InviteView: View {
    @State private var linkGenerated = false
    @State private var mockLink = "kiddoalert://invite/abc123xyz"
    @State private var showCopiedMessage = false

    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                // Header Icon
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.2.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.green)
                    }

                    Text("Convidar Responsável")
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                }
                .padding(.top, 20)

                // Explanation
                VStack(alignment: .leading, spacing: 16) {
                    ExplanationRow(
                        icon: "link",
                        title: "Gere um link único",
                        description: "Compartilhe com outro responsável"
                    )

                    ExplanationRow(
                        icon: "shield.checkmark",
                        title: "Seguro e privado",
                        description: "Apenas quem tem o link pode se conectar"
                    )

                    ExplanationRow(
                        icon: "bell.fill",
                        title: "Alertas compartilhados",
                        description: "Todos recebem notificações das crianças"
                    )
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.secondarySystemBackground))
                )

                // Current limits
                VStack(spacing: 12) {
                    HStack {
                        Text("Responsáveis Conectados")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("1 de 2")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.primary)
                    }

                    ProgressView(value: 1, total: 2)
                        .tint(.green)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )

                // Generate button or link display
                if !linkGenerated {
                    Button(action: generateLink) {
                        HStack {
                            Image(systemName: "link.circle.fill")
                            Text("Gerar Link de Convite")
                                .font(.body.weight(.semibold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    VStack(spacing: 16) {
                        // Link display
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Link de Convite")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            HStack {
                                Text(mockLink)
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
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }

                        // Expiration info
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text("Este link expira em 24 horas")
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                }

                // Info box
                HStack(spacing: 12) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)

                    Text("O novo responsável receberá alertas de todas as crianças conectadas")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Convite")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func generateLink() {
        withAnimation {
            linkGenerated = true
        }
    }

    private func copyLink() {
        // Mock - in real app would copy to clipboard
        UIPasteboard.general.string = mockLink

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
        // This would use UIActivityViewController
    }
}

// MARK: - Explanation Row Component
struct ExplanationRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 30)

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

#Preview {
    NavigationStack {
        InviteView()
    }
}
