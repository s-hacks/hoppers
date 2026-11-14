import SwiftUI

enum Subject: String, CaseIterable, Identifiable, Hashable {
    case math = "Math"
    case science = "Science"
    case english = "English"
    case history = "History"
    case other = "Other"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .math: return "➗"
        case .science: return "🔬"
        case .english: return "📚"
        case .history: return "🏛️"
        case .other: return "✨"
        }
    }

    var chipColor: Color {
        switch self {
        case .math: return HoppersTheme.lavender
        case .science: return HoppersTheme.babyBlue
        case .english: return HoppersTheme.blushPink
        case .history: return Color(hex: "E8D5C4")
        case .other: return HoppersTheme.cream
        }
    }
}
