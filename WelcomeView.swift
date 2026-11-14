import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void

    @State private var bunnyState: BunnyState = .idle
    @State private var appeared = false

    var body: some View {
        ZStack {
            HoppersBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    Spacer().frame(height: 12)

                    logo
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 16)

                    Text("Hop to it! Let's learn together")
                        .font(.system(.title3, design: .rounded).weight(.medium))
                        .foregroundStyle(HoppersTheme.plum.opacity(0.78))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                        .opacity(appeared ? 1 : 0)

                    Button {
                        bunnyState = bunnyState == .happy ? .idle : .happy
                    } label: {
                        BunnyView(state: bunnyState, size: 210)
                    }
                    .buttonStyle(.plain)
                    .scaleEffect(appeared ? 1 : 0.86)
                    .padding(.vertical, 4)

                    startButton
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)

                    Spacer().frame(height: 24)
                }
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .font(.system(.body, design: .rounded))
        .toolbar(.hidden, for: .navigationBar)
        .onAppear {
            withAnimation(HoppersTheme.softSpring) {
                appeared = true
            }
        }
    }

    private var logo: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text("🥕")
                    .font(.system(size: 28))
                Text("Hoppers")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(HoppersTheme.plum)
                Text("🥕")
                    .font(.system(size: 28))
                    .scaleEffect(x: -1, y: 1)
            }

            Text("your bunny tutor")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .tracking(2)
                .textCase(.uppercase)
                .foregroundStyle(HoppersTheme.lavender)
        }
        .padding(.top, 8)
    }

    private var startButton: some View {
        Button {
            bunnyState = .happy
            onStart()
        } label: {
            HStack(spacing: 10) {
                Text("Start Hopping")
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .font(.system(.title3, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    colors: [HoppersTheme.plum, Color(hex: "6B4F78")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
            .shadow(color: HoppersTheme.plum.opacity(0.3), radius: 16, y: 8)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 28)
        .accessibilityHint("Opens your classes")
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(HoppersTheme.spring, value: configuration.isPressed)
    }
}

#Preview("Welcome") {
    NavigationStack {
        WelcomeView(onStart: {})
    }
}
