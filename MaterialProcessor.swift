import Foundation
import PDFKit
import UniformTypeIdentifiers
import UIKit

enum MaterialProcessor {
    static let maxFileBytes = 10 * 1024 * 1024
    static let maxImageSide: CGFloat = 1500
    static let materialsCharacterLimit = 30_000
    static let maxImagesPerRequest = 6

    static func material(fromFile url: URL) throws -> ProcessedFile {
        let accessed = url.startAccessingSecurityScopedResource()
        defer {
            if accessed { url.stopAccessingSecurityScopedResource() }
        }

        try ensureFileSize(url)

        let fileName = url.lastPathComponent
        let type = materialType(for: url)

        switch type {
        case .pdf:
            let data = try Data(contentsOf: url)
            try ensureDataSize(data)
            let text = extractPDFText(from: url, fallbackData: data)
            return ProcessedFile(fileName: fileName, type: .pdf, data: data, extractedText: text)
        case .text:
            let data = try Data(contentsOf: url)
            try ensureDataSize(data)
            let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .utf16)
                ?? ""
            guard !text.isEmpty else { throw MaterialProcessError.unreadable }
            return ProcessedFile(fileName: fileName, type: .text, data: data, extractedText: text)
        case .image:
            let data = try Data(contentsOf: url)
            return try material(fromImageData: data, fileName: fileName)
        }
    }

    static func material(fromImageData data: Data, fileName: String) throws -> ProcessedFile {
        let jpeg = try resizedJPEG(from: data)
        try ensureDataSize(jpeg)
        let name = fileName.hasSuffix(".jpg") || fileName.hasSuffix(".jpeg")
            ? fileName
            : fileName.replacingOccurrences(of: "\\.[^.]+$", with: "", options: .regularExpression) + ".jpg"
        return ProcessedFile(fileName: name, type: .image, data: jpeg)
    }

    static func materialsContext(from materials: [Material]) -> String {
        var remaining = materialsCharacterLimit
        var chunks: [String] = []

        for material in materials.sorted(by: { $0.addedAt < $1.addedAt }) {
            guard remaining > 80 else { break }
            guard let text = material.extractedText?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !text.isEmpty else { continue }

            let header = "### \(material.fileName)\n"
            let budget = remaining - header.count
            guard budget > 0 else { break }
            let body = text.count <= budget ? text : String(text.prefix(budget)) + "…"
            chunks.append(header + body)
            remaining -= header.count + body.count
        }

        guard !chunks.isEmpty else { return "" }
        return "<class_materials>\n\(chunks.joined(separator: "\n\n"))\n</class_materials>"
    }

    private static func materialType(for url: URL) -> MaterialType {
        let ext = url.pathExtension.lowercased()
        if ext == "pdf" { return .pdf }
        if ["png", "jpg", "jpeg", "heic", "heif", "gif", "webp"].contains(ext) { return .image }
        return .text
    }

    private static func extractPDFText(from url: URL, fallbackData: Data) -> String? {
        let document = PDFDocument(url: url) ?? PDFDocument(data: fallbackData)
        guard let document else { return nil }
        var pages: [String] = []
        for index in 0..<document.pageCount {
            if let pageText = document.page(at: index)?.string?
                .trimmingCharacters(in: .whitespacesAndNewlines),
               !pageText.isEmpty {
                pages.append(pageText)
            }
        }
        let joined = pages.joined(separator: "\n\n")
        return joined.isEmpty ? nil : joined
    }

    private static func resizedJPEG(from data: Data) throws -> Data {
        guard let image = UIImage(data: data) else { throw MaterialProcessError.unreadable }
        let longest = max(image.size.width, image.size.height)
        let scale = longest > maxImageSide ? maxImageSide / longest : 1
        let newSize = CGSize(width: max(1, image.size.width * scale), height: max(1, image.size.height * scale))
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        let rendered = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }

        let qualities: [CGFloat] = [0.72, 0.55, 0.4]
        for quality in qualities {
            if let jpeg = rendered.jpegData(compressionQuality: quality), jpeg.count <= maxFileBytes {
                return jpeg
            }
        }
        throw MaterialProcessError.tooLarge
    }

    private static func ensureFileSize(_ url: URL) throws {
        let values = try url.resourceValues(forKeys: [.fileSizeKey])
        if let size = values.fileSize, size > maxFileBytes {
            throw MaterialProcessError.tooLarge
        }
    }

    private static func ensureDataSize(_ data: Data) throws {
        if data.count > maxFileBytes {
            throw MaterialProcessError.tooLarge
        }
    }
}

enum MaterialProcessError: LocalizedError {
    case tooLarge
    case unreadable
    case unsupported

    var bunnyMessage: String {
        switch self {
        case .tooLarge:
            return "That file is a bit too crunchy (over 10 MB). Try a smaller nibble?"
        case .unreadable:
            return "I couldn’t read those notes — the pages hopped away. Try another file?"
        case .unsupported:
            return "I only munch PDFs, text files, and photos of notes."
        }
    }
}
