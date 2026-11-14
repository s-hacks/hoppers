import PDFKit
import SwiftUI
import UIKit

struct MaterialPreviewView: View {
    let material: Material
    let repository: any MaterialRepository

    @Environment(\.dismiss) private var dismiss
    @State private var data: Data?
    @State private var image: UIImage?
    @State private var text: String?
    @State private var errorMessage: String?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                HoppersBackground()
                content
            }
            .navigationTitle(material.fileName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task { await load() }
        }
        .preferredColorScheme(.light)
    }

    @ViewBuilder
    private var content: some View {
        if isLoading {
            BunnyLoadingView(message: "Fetching your notes…")
        } else if let errorMessage {
            VStack(spacing: 12) {
                BunnyView(state: .sleepy, size: 120)
                Text(errorMessage)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(HoppersTheme.plum)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
        } else if material.type == .image, let image {
            ScrollView {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                    .padding(16)
            }
        } else if material.type == .pdf, let data {
            PDFKitView(data: data)
                .ignoresSafeArea(edges: .bottom)
        } else {
            ScrollView {
                Text(text ?? material.extractedText ?? "No text in this nibble.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(HoppersTheme.plum)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
        }
    }

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            if material.type == .text, let extracted = material.extractedText, !extracted.isEmpty {
                text = extracted
                return
            }
            let bytes = try await repository.downloadData(for: material)
            data = bytes
            switch material.type {
            case .image:
                image = UIImage(data: bytes)
            case .text:
                text = String(data: bytes, encoding: .utf8) ?? material.extractedText
            case .pdf:
                break
            }
        } catch {
            errorMessage = AppError.from(error).bunnyMessage
        }
    }
}

private struct PDFKitView: UIViewRepresentable {
    let data: Data

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.autoScales = true
        view.document = PDFDocument(data: data)
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = PDFDocument(data: data)
    }
}
