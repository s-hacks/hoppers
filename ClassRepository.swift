import Foundation
import Supabase

protocol ClassRepository: Sendable {
    func fetchClasses() async throws -> [ClassItem]
    func createClass(id: UUID, name: String, emoji: String, colorIndex: Int) async throws -> ClassItem
    func renameClass(id: UUID, name: String) async throws
    func deleteClass(id: UUID) async throws
}

struct SupabaseClassRepository: ClassRepository {
    private var client: SupabaseClient { SupabaseManager.client }

    func fetchClasses() async throws -> [ClassItem] {
        try await client
            .from("classes")
            .select("id, name, emoji, color_index, created_at, materials(count)")
            .order("created_at", ascending: true)
            .execute()
            .value
    }

    func createClass(id: UUID, name: String, emoji: String, colorIndex: Int) async throws -> ClassItem {
        let insert = ClassInsert(
            id: id,
            name: name,
            emoji: emoji,
            colorIndex: colorIndex
        )
        let created: ClassItem = try await client
            .from("classes")
            .insert(insert)
            .select("id, name, emoji, color_index, created_at, materials(count)")
            .single()
            .execute()
            .value
        return created
    }

    func renameClass(id: UUID, name: String) async throws {
        try await client
            .from("classes")
            .update(["name": name])
            .eq("id", value: id)
            .execute()
    }

    func deleteClass(id: UUID) async throws {
        let userId = try await client.auth.session.user.id
        try await deleteStorageFolder(userId: userId, classId: id)
        try await client
            .from("classes")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    private func deleteStorageFolder(userId: UUID, classId: UUID) async throws {
        let folder = "\(userId.uuidString.lowercased())/\(classId.uuidString.lowercased())"
        let objects = try await client.storage
            .from(SupabaseManager.storageBucket)
            .list(path: folder)
        let paths = objects.map { "\(folder)/\($0.name)" }
        if !paths.isEmpty {
            try await client.storage
                .from(SupabaseManager.storageBucket)
                .remove(paths: paths)
        }
    }
}

final class MockClassRepository: ClassRepository, @unchecked Sendable {
    var classes: [ClassItem] = HoppersPreviewData.classes

    func fetchClasses() async throws -> [ClassItem] {
        classes
    }

    func createClass(id: UUID, name: String, emoji: String, colorIndex: Int) async throws -> ClassItem {
        let item = ClassItem(id: id, name: name, emoji: emoji, colorIndex: colorIndex)
        classes.append(item)
        return item
    }

    func renameClass(id: UUID, name: String) async throws {
        guard let index = classes.firstIndex(where: { $0.id == id }) else { return }
        classes[index].name = name
    }

    func deleteClass(id: UUID) async throws {
        classes.removeAll { $0.id == id }
    }
}
