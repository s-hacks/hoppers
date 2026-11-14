import Combine
import Foundation
import SwiftUI

@MainActor
final class ClassListViewModel: ObservableObject {
    @Published var classes: [ClassItem] = []
    @Published var isLoading = false
    @Published var isRefreshing = false
    @Published var errorMessage: String?

    private let repository: any ClassRepository

    init(repository: any ClassRepository) {
        self.repository = repository
    }

    func load() async {
        if classes.isEmpty { isLoading = true }
        defer { isLoading = false }
        do {
            classes = try await repository.fetchClasses()
            errorMessage = nil
        } catch {
            errorMessage = AppError.from(error).bunnyMessage
        }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await load()
    }

    func create(name: String, emoji: String) async {
        let optimistic = ClassItem(
            name: name,
            emoji: emoji,
            colorIndex: classes.count,
            materialCount: 0
        )
        withAnimation(HoppersTheme.spring) {
            classes.append(optimistic)
        }
        do {
            let saved = try await repository.createClass(
                id: optimistic.id,
                name: name,
                emoji: emoji,
                colorIndex: optimistic.colorIndex
            )
            if let index = classes.firstIndex(where: { $0.id == optimistic.id }) {
                classes[index] = saved
            }
        } catch {
            withAnimation {
                classes.removeAll { $0.id == optimistic.id }
            }
            errorMessage = AppError.from(error).bunnyMessage
        }
    }

    func rename(id: UUID, name: String) async {
        let previous = classes
        if let index = classes.firstIndex(where: { $0.id == id }) {
            classes[index].name = name
        }
        do {
            try await repository.renameClass(id: id, name: name)
        } catch {
            classes = previous
            errorMessage = AppError.from(error).bunnyMessage
        }
    }

    func delete(id: UUID) async {
        let previous = classes
        withAnimation {
            classes.removeAll { $0.id == id }
        }
        do {
            try await repository.deleteClass(id: id)
        } catch {
            classes = previous
            errorMessage = AppError.from(error).bunnyMessage
        }
    }
}
