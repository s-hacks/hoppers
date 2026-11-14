import SwiftUI

struct AddClassSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var selectedEmoji = HoppersPreviewData.emojis[0]
    @State private var isCreating = false
    @FocusState private var nameFocused: Bool

    var existingCount: Int
    var onCreate: (String, String) async -> Void

    init(existingCount: Int = 0, onCreate: @escaping (String, String) async -> Void) {
        self.existingCount = existingCount
        self.onCreate = onCreate
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var previewName: String {
        trimmedName.isEmpty ? "…" : trimmedName
    }

    var body: some View {
        NavigationStack {
            ZStack {
                HoppersBackground()

                VStack(spacing: 22) {
                    BunnyView(state: trimmedName.isEmpty ? .idle : .happy, size: 120)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Class name")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(HoppersTheme.plum.opacity(0.7))

                        TextField("e.g. AP Chemistry", text: $name)
                            .font(.system(.title3, design: .rounded).weight(.semibold))
                            .foregroundStyle(HoppersTheme.plum)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                            .focused($nameFocused)

                        Text("Meet your new \(previewName) Hopper!")
                            .font(.system(.body, design: .rounded).weight(.medium))
                            .foregroundStyle(HoppersTheme.plum)
                            .padding(.top, 4)
                            .animation(HoppersTheme.spring, value: previewName)
                    }
                    .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Pick an emoji")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(HoppersTheme.plum.opacity(0.7))
                            .padding(.horizontal, 24)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(HoppersPreviewData.emojis, id: \.self) { emoji in
                                    Button {
                                        withAnimation(HoppersTheme.spring) {
                                            selectedEmoji = emoji
                                        }
                                    } label: {
                                        Text(emoji)
                                            .font(.system(size: 28))
                                            .frame(width: 52, height: 52)
                                            .background(
                                                selectedEmoji == emoji
                                                    ? HoppersTheme.blushPink
                                                    : Color.white.opacity(0.85)
                                            )
                                            .clipShape(Circle())
                                            .overlay(
                                                Circle().stroke(
                                                    selectedEmoji == emoji
                                                        ? HoppersTheme.plum.opacity(0.2)
                                                        : Color.clear,
                                                    lineWidth: 2
                                                )
                                            )
                                            .scaleEffect(selectedEmoji == emoji ? 1.08 : 1)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                    }

                    Spacer()

                    Button {
                        Task { await create() }
                    } label: {
                        Text("Create Hopper")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(trimmedName.isEmpty ? HoppersTheme.lavender : HoppersTheme.plum)
                            .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
                            .shadow(color: HoppersTheme.plum.opacity(trimmedName.isEmpty ? 0.08 : 0.28), radius: 14, y: 8)
                    }
                    .disabled(trimmedName.isEmpty || isCreating)
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.horizontal, 24)
                    .padding(.bottom, 12)
                }
            }
            .font(.system(.body, design: .rounded))
            .navigationTitle("New Hopper")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }
            }
            .onAppear { nameFocused = true }
        }
        .presentationDetents([.large])
        .preferredColorScheme(.light)
    }

    private func create() async {
        guard !trimmedName.isEmpty else { return }
        isCreating = true
        await onCreate(trimmedName, selectedEmoji)
        isCreating = false
        dismiss()
    }
}

#Preview("Add class") {
    AddClassSheet(existingCount: 2) { _, _ in }
}
