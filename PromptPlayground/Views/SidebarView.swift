import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @Binding var selectedPrompt: PromptModel?
    @Binding var selectedProject: ProjectModel?
    @Binding var searchText: String
    @Binding var showingNewPrompt: Bool
    @Binding var showingSettings: Bool

    @State private var showingNewProject = false
    @State private var showingProjectManager = false

    var filteredPrompts: [PromptModel] {
        let prompts = cloudKitManager.searchPrompts(query: searchText)

        if let selectedProject = selectedProject {
            return prompts.filter { $0.projectID == selectedProject.id }
        } else {
            return prompts.filter { $0.projectID == nil }
        }
    }

    var body: some View {
        List(selection: $selectedPrompt) {
            Section {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search prompts...", text: $searchText)
                }
                .padding(.vertical, 4)

                // Project selector
                Menu {
                    Button("All Prompts") {
                        selectedProject = nil
                    }

                    Divider()

                    ForEach(cloudKitManager.projects) { project in
                        Button(project.name) {
                            selectedProject = project
                        }
                    }

                    Divider()

                    Button("Manage Projects...") {
                        showingProjectManager = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "folder.fill")
                            .foregroundColor(selectedProject != nil ? Color(hex: selectedProject!.color) : .secondary)
                        Text(selectedProject?.name ?? "All Prompts")
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Section {
                ForEach(filteredPrompts) { prompt in
                    PromptRowView(prompt: prompt)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await cloudKitManager.deletePrompt(prompt)
                                    if selectedPrompt?.id == prompt.id {
                                        selectedPrompt = nil
                                    }
                                }
                            }
                        }
                        .swipeActions(edge: .leading) {
                            Button {
                                var updatedPrompt = prompt
                                updatedPrompt.isFavorite.toggle()
                                Task {
                                    await cloudKitManager.savePrompt(updatedPrompt)
                                }
                            } label: {
                                Image(systemName: prompt.isFavorite ? "heart.slash" : "heart")
                            }
                            .tint(prompt.isFavorite ? .gray : .pink)
                        }
                }
            } header: {
                HStack {
                    Text("\(filteredPrompts.count) Prompts")
                    Spacer()
                    Button {
                        showingNewPrompt = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Prompts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gear")
                }
            }
        }
        .sheet(isPresented: $showingProjectManager) {
            ProjectsView()
        }
        .onAppear {
            if selectedPrompt == nil && !filteredPrompts.isEmpty {
                selectedPrompt = filteredPrompts.first
            }
        }
    }
}

struct PromptRowView: View {
    let prompt: PromptModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(prompt.title)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                if prompt.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.pink)
                }
            }

            if !prompt.userPrompt.isEmpty {
                Text(prompt.userPrompt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                if !prompt.tags.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 4) {
                            ForEach(prompt.tags.prefix(3), id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.blue)
                                    .cornerRadius(4)
                            }

                            if prompt.tags.count > 3 {
                                Text("+\(prompt.tags.count - 3)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                Spacer()

                Text(prompt.modifiedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

// Helper extension for hex colors
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    NavigationView {
        SidebarView(
            selectedPrompt: .constant(nil),
            selectedProject: .constant(nil),
            searchText: .constant(""),
            showingNewPrompt: .constant(false),
            showingSettings: .constant(false)
        )
        .environmentObject(CloudKitManager())
    }
}
