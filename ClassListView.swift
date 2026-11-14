import SwiftUI

struct ClassListView: View {
    @EnvironmentObject private var services: HoppersServices
    @EnvironmentObject private var auth: AuthViewModel

    var body: some View {
        ClassListScreen(repository: services.classes)
            .environmentObject(auth)
            .environmentObject(services)
    }
}

private struct ClassListScreen: View {
    @EnvironmentObject private var auth: AuthViewModel
    @StateObject private var viewModel: ClassListViewModel
    @State private var showAddClass = false
    @State private var showProfile = false
    @State private var appeared = false
    @State private var classToRename: ClassItem?
    @State private var renameDraft = ""
    @State private var classToDelete: ClassItem?

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    init(repository: any ClassRepository) {
        _viewModel = StateObject(wrappedValue: ClassListViewModel(repository: repository))
    }

    var body: some View {
        ZStack {
            HoppersBackground()

            VStack(spacing: 0) {
                header
                if viewModel.isLoading && viewModel.classes.isEmpty {
                    BunnyLoadingView(message: "Gathering your Hoppers…")
                } else if let error = viewModel.errorMessage, viewModel.classes.isEmpty {
                    errorState(error)
                } else if viewModel.classes.isEmpty {
                    emptyState
                } else {
                    classGrid
                }
            }
        }
        .font(.system(.body, design: .rounded))
        .toolbar(.hidden, for: .navigationBar)
        .task { await viewModel.load() }
        .refreshable { await viewModel.refresh() }
        .sheet(isPresented: $showAddClass) {
            AddClassSheet(existingCount: viewModel.classes.count) { name, emoji in
                await viewModel.create(name: name, emoji: emoji)
            }
        }
        .sheet(isPresented: $showProfile) {
            ProfileSheet()
        }
        .alert("Rename Hopper", isPresented: Binding(
            get: { classToRename != nil },
            set: { if !$0 { classToRename = nil } }
        )) {
            TextField("Class name", text: $renameDraft)
            Button("Save") {
                if let item = classToRename {
                    let name = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !name.isEmpty else { return }
                    Task { await viewModel.rename(id: item.id, name: name) }
                }
                classToRename = nil
            }
            Button("Cancel", role: .cancel) { classToRename = nil }
        } message: {
            Text("This becomes “\(renameDraft.isEmpty ? "…" : renameDraft) Hopper”.")
        }
        .confirmationDialog(
            "Delete \(classToDelete?.botName ?? "this Hopper")?",
            isPresented: Binding(
                get: { classToDelete != nil },
                set: { if !$0 { classToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                if let item = classToDelete {
                    Task { await viewModel.delete(id: item.id) }
                }
                classToDelete = nil
            }
            Button("Cancel", role: .cancel) { classToDelete = nil }
        } message: {
            Text("Their chat and materials will hop away too.")
        }
        .alert("Oh carrots!", isPresented: Binding(
            get: { viewModel.errorMessage != nil && !viewModel.classes.isEmpty },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .onAppear {
            withAnimation(HoppersTheme.softSpring) {
                appeared = true
            }
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            Spacer()
            VStack(spacing: 6) {
                BunnyView(state: viewModel.classes.isEmpty ? .sleepy : .happy, size: 72)
                Text("My Hoppers")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(HoppersTheme.plum)
                Text("One bunny tutor per class")
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundStyle(HoppersTheme.plum.opacity(0.65))
            }
            Spacer()
            Button {
                showProfile = true
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(HoppersTheme.plum)
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.8))
                    .clipShape(Circle())
                    .hoppersShadow(0.08)
            }
            .accessibilityLabel("Profile")
            .padding(.trailing, 16)
            .padding(.top, 8)
        }
        .padding(.top, 8)
        .padding(.bottom, 12)
    }

    private var classGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 14) {
                ForEach(Array(viewModel.classes.enumerated()), id: \.element.id) { index, item in
                    NavigationLink {
                        ChatView(classItem: item)
                    } label: {
                        ClassCardView(classItem: item)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            renameDraft = item.name
                            classToRename = item
                        } label: {
                            Label("Rename", systemImage: "pencil")
                        }
                        Button(role: .destructive) {
                            classToDelete = item
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .staggeredAppear(appeared, delay: Double(index) * 0.07)
                }

                Button {
                    showAddClass = true
                } label: {
                    AddClassCard()
                }
                .buttonStyle(.plain)
                .staggeredAppear(appeared, delay: Double(viewModel.classes.count) * 0.07)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            BunnyView(state: .sleepy, size: 180)
            Text("No Hoppers yet! Add your first class.")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(HoppersTheme.plum)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                showAddClass = true
            } label: {
                Text("Add a class")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 28)
                    .padding(.vertical, 14)
                    .background(HoppersTheme.plum)
                    .clipShape(Capsule())
                    .hoppersShadow(0.16)
            }
            .buttonStyle(ScaleButtonStyle())
            Spacer()
        }
        .opacity(appeared ? 1 : 0)
    }

    private func errorState(_ message: String) -> some View {
        VStack(spacing: 16) {
            Spacer()
            BunnyView(state: .sleepy, size: 140)
            Text(message)
                .font(.system(.body, design: .rounded).weight(.medium))
                .foregroundStyle(HoppersTheme.plum)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)
            Button("Try again") {
                Task { await viewModel.load() }
            }
            .font(.system(.headline, design: .rounded).weight(.bold))
            Spacer()
        }
    }
}

private extension View {
    func staggeredAppear(_ appeared: Bool, delay: Double) -> some View {
        self
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 18)
            .animation(HoppersTheme.spring.delay(delay), value: appeared)
    }
}

#Preview("My Hoppers") {
    NavigationStack {
        ClassListView()
    }
    .environmentObject(HoppersServices.preview)
    .environmentObject(AuthViewModel())
}
