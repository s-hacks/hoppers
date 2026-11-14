import SwiftUI

enum HoppersTheme {
    static let cream = Color(hex: "FFF8F0")
    static let blushPink = Color(hex: "FFC8DD")
    static let lavender = Color(hex: "CDB4DB")
    static let babyBlue = Color(hex: "BDE0FE")
    static let plum = Color(hex: "4A3B52")
    static let carrot = Color(hex: "FF8A5B")
    static let innerEar = Color(hex: "FFAFCC")
    static let bunnyFur = Color(hex: "FFFAFC")

    static let spring = Animation.spring(response: 0.45, dampingFraction: 0.72)
    static let softSpring = Animation.spring(response: 0.55, dampingFraction: 0.78)

    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }

    /// Pastels used for class cards, rotating by `colorIndex`.
    static let classPastels: [Color] = [
        blushPink,
        lavender,
        babyBlue,
        innerEar,
        Color(hex: "E8D5C4")
    ]

    static func classColor(at index: Int) -> Color {
        classPastels[abs(index) % classPastels.count]
    }
}

enum BunnyState: String, CaseIterable {
    case idle
    case thinking
    case happy
    case sleepy
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}

extension View {
    func hoppersShadow(_ opacity: Double = 0.14) -> some View {
        shadow(color: HoppersTheme.plum.opacity(opacity), radius: 14, x: 0, y: 6)
    }

    func hoppersCard(padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(.white.opacity(0.72))
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .hoppersShadow(0.1)
    }
}

struct HoppersBackground: View {
    var body: some View {
        ZStack {
            HoppersTheme.cream

            Circle()
                .fill(HoppersTheme.blushPink.opacity(0.42))
                .frame(width: 280, height: 280)
                .blur(radius: 8)
                .offset(x: -150, y: -320)

            Circle()
                .fill(HoppersTheme.lavender.opacity(0.38))
                .frame(width: 240, height: 240)
                .blur(radius: 10)
                .offset(x: 160, y: -180)

            Circle()
                .fill(HoppersTheme.babyBlue.opacity(0.4))
                .frame(width: 260, height: 260)
                .blur(radius: 12)
                .offset(x: 140, y: 360)

            Circle()
                .fill(HoppersTheme.blushPink.opacity(0.22))
                .frame(width: 180, height: 180)
                .offset(x: -170, y: 280)
        }
        .ignoresSafeArea()
    }
}
