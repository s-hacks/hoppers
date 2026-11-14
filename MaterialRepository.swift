import Foundation
import Supabase

protocol MaterialRepository: Sendable {
    func fetchMaterials(classId: UUID) async throws -> [Material]
    func uploadMaterial(classId: UUID, file: ProcessedFile) async throws -> Material
    func deleteMaterial(_ material: Material) async throws
    func signedURL(for material: Material, expiresIn: Int) async throws -> URL
    func downloadData(for material: Material) async throws -> Data
}

actor ImageBytesCache {
    private var storage: [String: Data] = [:]

    func data(for path: String) -> Data? { storage[path] }

    func store(_ data: Data, for path: String) {
        storage[path] = data
    }

    func remove(_ path: String) {
        storage[path] = nil
    }

    func removeAll(inFolder folder: String) {
        for key in storage.keys where key.hasPrefix(folder) {
            storage[key] = nil
        }
    }
}

struct SupabaseMaterialRepository: MaterialRepository {
    private static let cache = ImageBytesCache()
    private var client: SupabaseClient { SupabaseManager.client }

    func fetchMaterials(classId: UUID) async throws -> [Material] {
        try await client
            .from("materials")
            .select()
            .eq("class_id", value: classId)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func uploadMaterial(classId: UUID, file: ProcessedFile) async throws -> Material {
        let userId = try await client.auth.session.user.id
        let safeName = file.fileName.replacingOccurrences(of: "/", with: "_")
        let path = "\(userId.uuidString.lowercased())/\(classId.uuidString.lowercased())/\(UUID().uuidString.lowercased())_\(safeName)"
        let id = UUID()

        try await client.storage
            .from(SupabaseManager.storageBucket)
            .upload(
                path,
                data: file.data,
                options: FileOptions(contentType: file.type.mimeType, upsert: false)
            )

        if file.type == .image {
            await Self.cache.store(file.data, for: path)
        }

        let insert = MaterialInsert(
            id: id,
            classId: classId,
            fileName: file.fileName,
            type: file.type.rawValue,
            storagePath: path,
            extractedText: file.extractedText
        )

        do {
            return try await client
                .from("materials")
                .insert(insert)
                .select()
                .single()
                .execute()
                .value
        } catch {
            try? await client.storage.from(SupabaseManager.storageBucket).remove(paths: [path])
            throw error
        }
    }

    func deleteMaterial(_ material: Material) async throws {
        try await client.storage
            .from(SupabaseManager.storageBucket)
            .remove(paths: [material.storagePath])
        try await client
            .from("materials")
            .delete()
            .eq("id", value: material.id)
            .execute()
        await Self.cache.remove(material.storagePath)
    }

    func signedURL(for material: Material, expiresIn: Int = 3600) async throws -> URL {
        try await client.storage
            .from(SupabaseManager.storageBucket)
            .createSignedURL(path: material.storagePath, expiresIn: expiresIn)
    }

    func downloadData(for material: Material) async throws -> Data {
        if let cached = await Self.cache.data(for: material.storagePath) {
            return cached
        }
        let data = try await client.storage
            .from(SupabaseManager.storageBucket)
            .download(path: material.storagePath)
        await Self.cache.store(data, for: material.storagePath)
        return data
    }
}

final class MockMaterialRepository: MaterialRepository, @unchecked Sendable {
    var materials: [Material] = [
        Material(
            id: UUID(),
            classId: HoppersPreviewData.history.id,
            fileName: "Chapter 4 notes.txt",
            type: .text,
            storagePath: "preview/notes.txt",
            extractedText: "Renaissance notes",
            createdAt: Date()
        )
    ]

    func fetchMaterials(classId: UUID) async throws -> [Material] {
        materials.filter { $0.classId == classId }
    }

    func uploadMaterial(classId: UUID, file: ProcessedFile) async throws -> Material {
        let material = Material(
            id: UUID(),
            classId: classId,
            fileName: file.fileName,
            type: file.type,
            storagePath: "preview/\(file.fileName)",
            extractedText: file.extractedText,
            createdAt: Date()
        )
        materials.insert(material, at: 0)
        return material
    }

    func deleteMaterial(_ material: Material) async throws {
        materials.removeAll { $0.id == material.id }
    }

    func signedURL(for material: Material, expiresIn: Int) async throws -> URL {
        URL(string: "https://example.com/\(material.fileName)")!
    }

    func downloadData(for material: Material) async throws -> Data {
        Data()
    }
}
