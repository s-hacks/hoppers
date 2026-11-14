import PhotosUI
import SwiftUI
import UniformTypeIdentifiers

struct MaterialsView: View {
    let classItem: ClassItem
    @EnvironmentObject private var services: HoppersServices

    var body: some View {
        MaterialsScreen(classItem: classItem, repository: services.materials)
    }
}

private struct MaterialsScreen: View {
    let classItem: ClassItem
    let repository: any MaterialRepository

    @Environment(\.dismiss) private var dismiss
    @State private var materials: [Material] = []
    @State private var showAddOptions = false
    @State private var showFileImporter = false
    @State private var showPhotoPicker = false
    @State private var pickerItems: [PhotosPickerItem] = []
    @State private var errorMessage: String?
    @State private var isImporting = false
    @State private var isLoading = false
    @State private var previewMaterial: Material?

    var body: some View {
        ZStack {
            HoppersBackground()

            VStack(spacing: 0) {
                header
                if isLoading && materials.isEmpty {
                    BunnyLoadingView(message: "Looking through your notes…")
                } else if materials.isEmpty {
                    emptyState
                } else {
                    materialsList
                }
                addButton
            }

            if isImporting {
                Color.black.opacity(0.12).ignoresSafeArea()
                VStack(spacing: 10) {
                    BunnyView(state: .thinking, size: 72)
                    Text("Uploading to the burrow…")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(HoppersTheme.plum)
                }
                .padding(24)
                .background(.white.opacity(0.92))
                .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
                .hoppersShadow()
            }
        }
        .font(.system(.body, design: .rounded))
        .navigationBarBackButtonHidden(true)
        .toolbar(.hidden, for: .navigationBar)
        .task { await load() }
        .confirmationDialog("Add materials", isPresented: $showAddOptions, titleVisibility: .visible) {
            Button("Files") { showFileImporter = true }
            Button("Photos") { showPhotoPicker = true }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("PDFs, notes, or photos of worksheets.")
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .plainText, .utf8PlainText, .text],
            allowsMultipleSelection: true
        ) { result in
            handleFileResult(result)
        }
        .photosPicker(
            isPresented: $showPhotoPicker,
            selection: $pickerItems,
            maxSelectionCount: 6,
            matching: .images
        )
        .onChange(of: pickerItems) { _, items in
            guard !items.isEmpty else { return }
            importPhotos(items)
        }
        .sheet(item: $previewMaterial) { material in
            MaterialPreviewView(material: material, repository: repository)
        }
        .alert("Oh carrots!", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private var header: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(HoppersTheme.plum)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.8))
                    .clipShape(Circle())
                    .hoppersShadow(0.08)
            }
            .accessibilityLabel("Back")

            VStack(alignment: .leading, spacing: 2) {
                Text("Materials")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(HoppersTheme.plum)
                Text(classItem.botName)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(HoppersTheme.plum.opacity(0.7))
            }

            Spacer()
            Text(classItem.emoji)
                .font(.system(size: 28))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.45))
    }

    private var materialsList: some View {
        List {
            ForEach(materials) { material in
                Button {
                    previewMaterial = material
                } label: {
                    MaterialRow(material: material, accent: classItem.color)
                }
                .buttonStyle(.plain)
                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task { await delete(material) }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable { await load() }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            BunnyView(state: .idle, size: 140)
            Text("No notes in this burrow yet.")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(HoppersTheme.plum)
            Text("Add a PDF, a text file, or a photo of your worksheet.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(HoppersTheme.plum.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var addButton: some View {
        Button {
            showAddOptions = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Add Materials")
            }
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(HoppersTheme.plum)
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .shadow(color: HoppersTheme.plum.opacity(0.25), radius: 12, y: 6)
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
        .disabled(isImporting)
    }

    private func load() async {
        isLoading = materials.isEmpty
        defer { isLoading = false }
        do {
            materials = try await repository.fetchMaterials(classId: classItem.id)
        } catch {
            errorMessage = AppError.from(error).bunnyMessage
        }
    }

    private func handleFileResult(_ result: Result<[URL], Error>) {
        switch result {
        case .failure:
            errorMessage = MaterialProcessError.unreadable.bunnyMessage
        case .success(let urls):
            Task { await upload(urls: urls) }
        }
    }

    private func upload(urls: [URL]) async {
        isImporting = true
        defer { isImporting = false }
        for url in urls {
            do {
                let file = try MaterialProcessor.material(fromFile: url)
                let saved = try await repository.uploadMaterial(classId: classItem.id, file: file)
                materials.insert(saved, at: 0)
            } catch let error as MaterialProcessError {
                errorMessage = error.bunnyMessage
            } catch {
                errorMessage = AppError.from(error).bunnyMessage
            }
        }
    }

    private func importPhotos(_ items: [PhotosPickerItem]) {
        isImporting = true
        Task {
            defer {
                isImporting = false
                pickerItems = []
            }
            for (index, item) in items.enumerated() {
                do {
                    let data = try await loadImageData(from: item)
                    let file = try MaterialProcessor.material(
                        fromImageData: data,
                        fileName: "Notes photo \(materials.count + index + 1).jpg"
                    )
                    let saved = try await repository.uploadMaterial(classId: classItem.id, file: file)
                    materials.insert(saved, at: 0)
                } catch let error as MaterialProcessError {
                    errorMessage = error.bunnyMessage
                } catch {
                    errorMessage = AppError.from(error).bunnyMessage
                }
            }
        }
    }

    private func loadImageData(from item: PhotosPickerItem) async throws -> Data {
        if let wrapped = try await item.loadTransferable(type: HopperImageData.self) {
            return wrapped.data
        }
        if let data = try await item.loadTransferable(type: Data.self) {
            return data
        }
        throw MaterialProcessError.unreadable
    }

    private func delete(_ material: Material) async {
        let previous = materials
        materials.removeAll { $0.id == material.id }
        do {
            try await repository.deleteMaterial(material)
        } catch {
            materials = previous
            errorMessage = AppError.from(error).bunnyMessage
        }
    }
}

private struct HopperImageData: Transferable {
    let data: Data

    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(importedContentType: .image) { data in
            HopperImageData(data: data)
        }
    }
}

private struct MaterialRow: View {
    let material: Material
    var accent: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: material.type.systemImage)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(HoppersTheme.plum)
                .frame(width: 44, height: 44)
                .background(accent)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(material.fileName)
                    .font(.system(.body, design: .rounded).weight(.semibold))
                    .foregroundStyle(HoppersTheme.plum)
                    .lineLimit(1)
                Text("\(material.type.label) · \(material.createdAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundStyle(HoppersTheme.plum.opacity(0.6))
            }
            Spacer()
        }
        .padding(12)
        .background(Color.white.opacity(0.86))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .hoppersShadow(0.08)
    }
}

#Preview("Materials") {
    NavigationStack {
        MaterialsView(classItem: HoppersPreviewData.history)
    }
    .environmentObject(HoppersServices.preview)
}
