import SwiftUI

struct ProjectsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @State private var showingNewProject = false

    var body: some View {
        NavigationView {
            List {
                ForEach(cloudKitManager.projects) { project in
                    ProjectRowView(project: project)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                Task {
                                    await cloudKitManager.deleteProject(project)
                                }
                            }
                        }
                }
            }
            .navigationTitle("Projects")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNewProject = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewProject) {
            NewProjectView { project in
                Task {
                    await cloudKitManager.saveProject(project)
                }
            }
        }
    }
}

struct ProjectRowView: View {
    let project: ProjectModel
    @EnvironmentObject var cloudKitManager: CloudKitManager

    var promptCount: Int {
        cloudKitManager.promptsForProject(project).count
    }

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: project.color))
                .frame(width: 16, height: 16)

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)

                if !project.description.isEmpty {
                    Text(project.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text("\(promptCount) prompt\(promptCount == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct NewProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "#007AFF"

    let onSave: (ProjectModel) -> Void

    private let colors = [
        "#007AFF", // Blue
        "#FF3B30", // Red
        "#FF9500", // Orange
        "#FFCC00", // Yellow
        "#34C759", // Green
        "#5AC8FA", // Light Blue
        "#AF52DE", // Purple
        "#FF2D92", // Pink
        "#8E8E93", // Gray
        "#000000"  // Black
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("Project Details") {
                    TextField("Project Name", text: $name)

                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 16) {
                        ForEach(colors, id: \.self) { color in
                            Button {
                                selectedColor = color
                            } label: {
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 32, height: 32)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.primary, lineWidth: selectedColor == color ? 2 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("New Project")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let project = ProjectModel(
                            name: name.isEmpty ? "Untitled Project" : name,
                            description: description,
                            color: selectedColor
                        )
                        onSave(project)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ProjectsView()
        .environmentObject(CloudKitManager())
}
