import Foundation

enum MaterialType: String, Codable, CaseIterable, Sendable {
    case pdf
    case image
    case text

    var systemImage: String {
        switch self {
        case .pdf: return "doc.richtext.fill"
        case .image: return "photo.fill"
        case .text: return "doc.text.fill"
        }
    }

    var label: String {
        switch self {
        case .pdf: return "PDF"
        case .image: return "Photo"
        case .text: return "Notes"
        }
    }

    var mimeType: String {
        switch self {
        case .pdf: return "application/pdf"
        case .image: return "image/jpeg"
        case .text: return "text/plain"
        }
    }
}

struct Material: Identifiable, Hashable, Codable, Sendable {
    let id: UUID
    var classId: UUID
    var fileName: String
    var type: MaterialType
    var storagePath: String
    var extractedText: String?
    var createdAt: Date

    var addedAt: Date { createdAt }

    enum CodingKeys: String, CodingKey {
        case id
        case classId = "class_id"
        case fileName = "file_name"
        case type
        case storagePath = "storage_path"
        case extractedText = "extracted_text"
        case createdAt = "created_at"
    }
}

struct MaterialInsert: Encodable {
    let id: UUID
    let classId: UUID
    let fileName: String
    let type: String
    let storagePath: String
    let extractedText: String?

    enum CodingKeys: String, CodingKey {
        case id
        case classId = "class_id"
        case fileName = "file_name"
        case type
        case storagePath = "storage_path"
        case extractedText = "extracted_text"
    }
}

struct ProcessedFile {
    var fileName: String
    var type: MaterialType
    var data: Data
    var extractedText: String?
}
