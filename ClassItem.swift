import Foundation
import SwiftUI

struct ClassItem: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var name: String
    var emoji: String
    var colorIndex: Int
    var createdAt: Date
    var materialCount: Int

    var botName: String { "\(name) Hopper" }

    var color: Color {
        HoppersTheme.classColor(at: colorIndex)
    }

    var materialsSubtitle: String {
        materialCount == 1 ? "1 material" : "\(materialCount) materials"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case emoji
        case colorIndex = "color_index"
        case createdAt = "created_at"
        case materials
    }

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        colorIndex: Int = 0,
        createdAt: Date = Date(),
        materialCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.colorIndex = colorIndex
        self.createdAt = createdAt
        self.materialCount = materialCount
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        emoji = try container.decode(String.self, forKey: .emoji)
        colorIndex = try container.decode(Int.self, forKey: .colorIndex)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        if let embeds = try container.decodeIfPresent([CountEmbed].self, forKey: .materials) {
            materialCount = embeds.first?.count ?? 0
        } else {
            materialCount = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(emoji, forKey: .emoji)
        try container.encode(colorIndex, forKey: .colorIndex)
        try container.encode(createdAt, forKey: .createdAt)
    }

    private struct CountEmbed: Decodable {
        let count: Int
    }
}

struct ClassInsert: Encodable {
    let id: UUID
    let name: String
    let emoji: String
    let colorIndex: Int

    enum CodingKeys: String, CodingKey {
        case id, name, emoji
        case colorIndex = "color_index"
    }
}

enum HoppersPreviewData {
    static let emojis = ["📐", "🔬", "📚", "🏛️", "✏️", "🌍", "🧮", "🧪", "🎨", "🎵"]

    static let history = ClassItem(
        name: "History",
        emoji: "🏛️",
        colorIndex: 1,
        materialCount: 3
    )

    static let math = ClassItem(
        name: "Math",
        emoji: "📐",
        colorIndex: 0,
        materialCount: 0
    )

    static let chemistry = ClassItem(
        name: "AP Chemistry",
        emoji: "🧪",
        colorIndex: 2,
        materialCount: 1
    )

    static var classes: [ClassItem] { [history, math, chemistry] }
}
