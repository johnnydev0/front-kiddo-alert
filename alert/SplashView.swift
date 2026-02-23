import SwiftUI

// MARK: - KidoLogoView (shared across screens)
struct KidoLogoView: View {
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color.blue)
                .frame(width: size, height: size)
            Image(systemName: "mappin.circle.fill")
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.55, height: size * 0.55)
                .foregroundColor(.white)
        }
    }
}

// MARK: - SplashView
struct SplashView: View {
    @State private var opacity: Double = 0
    @State private var yOffset: CGFloat = 12
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            Color(.secondarySystemBackground).ignoresSafeArea()

            VStack(spacing: 16) {
                KidoLogoView(size: 96)

                Text("KidoAlert")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)

                Text("Alertas de chegada para quem você ama")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .opacity(opacity)
            .offset(y: yOffset)

            VStack {
                Spacer()
                HStack(spacing: 6) {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .offset(y: isAnimating ? -8 : 0)
                            .animation(
                                .easeInOut(duration: 0.5)
                                    .repeatForever(autoreverses: true)
                                    .delay(Double(i) * 0.15),
                                value: isAnimating
                            )
                    }
                }
                .padding(.bottom, 96)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                opacity = 1
                yOffset = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    SplashView()
}
