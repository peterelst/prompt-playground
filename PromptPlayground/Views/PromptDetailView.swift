import SwiftUI

struct PromptDetailView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var afmService: AFMService
    @State var prompt: PromptModel

    @State private var title: String
    @State private var systemPrompt: String
    @State private var userPrompt: String
    @State private var temperature: Double
    @State private var maxTokens: Int
    @State private var tags: [String]
    @State private var selectedProject: ProjectModel?

    @State private var currentOutput = ""
    @State private var showingSavedOutputs = false
    @State private var isRunning = false
    @State private var showingTagEditor = false
    @State private var newTag = ""

    init(prompt: PromptModel) {
        self.prompt = prompt
        self._title = State(initialValue: prompt.title)
        self._systemPrompt = State(initialValue: prompt.systemPrompt)
        self._userPrompt = State(initialValue: prompt.userPrompt)
        self._temperature = State(initialValue: prompt.temperature)
        self._maxTokens = State(initialValue: prompt.maxTokens)
        self._tags = State(initialValue: prompt.tags)
        self._selectedProject = State(initialValue: nil)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with title and project
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Prompt Title", text: $title, axis: .vertical)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .textFieldStyle(.plain)
                        .onChange(of: title) { _, newValue in
                            saveChanges()
                        }

                    HStack {
                        Menu {
                            Button("No Project") {
                                selectedProject = nil
                                saveChanges()
                            }

                            ForEach(cloudKitManager.projects) { project in
                                Button(project.name) {
                                    selectedProject = project
                                    saveChanges()
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(selectedProject != nil ? Color(hex: selectedProject!.color) : .secondary)
                                Text(selectedProject?.name ?? "No Project")
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            var updatedPrompt = prompt
                            updatedPrompt.isFavorite.toggle()
                            Task {
                                await cloudKitManager.savePrompt(updatedPrompt)
                                prompt = updatedPrompt
                            }
                        } label: {
                            Image(systemName: prompt.isFavorite ? "heart.fill" : "heart")
                                .foregroundColor(prompt.isFavorite ? .pink : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color(.systemBackground))

                // Prompt Configuration
                VStack(spacing: 16) {
                    // System Prompt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("System Prompt")
                            .font(.headline)

                        TextField("Enter system prompt...", text: $systemPrompt, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(5...10)
                            .onChange(of: systemPrompt) { _, newValue in
                                saveChanges()
                            }
                    }

                    // User Prompt
                    VStack(alignment: .leading, spacing: 8) {
                        Text("User Prompt")
                            .font(.headline)

                        TextField("Enter user prompt...", text: $userPrompt, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...8)
                            .onChange(of: userPrompt) { _, newValue in
                                saveChanges()
                            }
                    }

                    // Parameters
                    VStack(spacing: 12) {
                        // Temperature
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Temperature")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(temperature, specifier: "%.2f")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Slider(value: $temperature, in: 0...1, step: 0.01)
                                .onChange(of: temperature) { _, newValue in
                                    saveChanges()
                                }
                        }

                        // Max Tokens
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Max Tokens")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Spacer()
                                Text("\(maxTokens)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Slider(value: Binding(
                                get: { Double(maxTokens) },
                                set: { maxTokens = Int($0) }
                            ), in: 100...4000, step: 50)
                            .onChange(of: maxTokens) { _, newValue in
                                saveChanges()
                            }

                            HStack {
                                Text("≈ \(prompt.estimatedCharacters) characters")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("≈ \(prompt.estimatedWords) words")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    // Tags
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Tags")
                                .font(.headline)
                            Spacer()
                            Button("Add Tag") {
                                showingTagEditor = true
                            }
                            .font(.caption)
                        }

                        if !tags.isEmpty {
                            FlowLayout(items: tags) { tag in
                                HStack(spacing: 4) {
                                    Text(tag)
                                    Button {
                                        tags.removeAll { $0 == tag }
                                        saveChanges()
                                    } label: {
                                        Image(systemName: "xmark")
                                            .font(.caption)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.2))
                                .foregroundColor(.blue)
                                .cornerRadius(8)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)

                // Run Button and Output
                VStack(spacing: 16) {
                    HStack {
                        Button {
                            runPrompt()
                        } label: {
                            HStack {
                                if isRunning {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "play.fill")
                                }
                                Text(isRunning ? "Running..." : "Run Prompt")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!afmService.isAvailable || isRunning || userPrompt.isEmpty)

                        Button {
                            showingSavedOutputs = true
                        } label: {
                            Image(systemName: "bookmark.fill")
                        }
                        .buttonStyle(.bordered)
                    }

                    if !currentOutput.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Output")
                                    .font(.headline)
                                Spacer()

                                Button("Save Output") {
                                    saveCurrentOutput()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }

                            Text(currentOutput)
                                .padding()
                                .background(Color(.tertiarySystemBackground))
                                .cornerRadius(8)
                                .textSelection(.enabled)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingTagEditor) {
            TagEditorView(newTag: $newTag) { tag in
                if !tag.isEmpty && !tags.contains(tag) {
                    tags.append(tag)
                    saveChanges()
                }
            }
        }
        .sheet(isPresented: $showingSavedOutputs) {
            SavedOutputsView(promptID: prompt.id)
        }
        .onAppear {
            selectedProject = cloudKitManager.projects.first { $0.id == prompt.projectID }
        }
    }

    private func saveChanges() {
        var updatedPrompt = prompt
        updatedPrompt.title = title
        updatedPrompt.systemPrompt = systemPrompt
        updatedPrompt.userPrompt = userPrompt
        updatedPrompt.temperature = temperature
        updatedPrompt.maxTokens = maxTokens
        updatedPrompt.tags = tags
        updatedPrompt.projectID = selectedProject?.id
        updatedPrompt.modifiedAt = Date()

        Task {
            await cloudKitManager.savePrompt(updatedPrompt)
            prompt = updatedPrompt
        }
    }

    private func runPrompt() {
        guard afmService.isAvailable && !userPrompt.isEmpty else { return }

        Task {
            isRunning = true

            do {
                let result = try await afmService.generateCompletion(
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt,
                    temperature: temperature,
                    maxTokens: maxTokens
                )

                currentOutput = result.output
            } catch {
                currentOutput = "Error: \(error.localizedDescription)"
            }

            isRunning = false
        }
    }

    private func saveCurrentOutput() {
        let savedOutput = SavedOutputModel(
            promptID: prompt.id,
            output: currentOutput,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: temperature,
            maxTokens: maxTokens
        )

        Task {
            await cloudKitManager.saveSavedOutput(savedOutput)
        }
    }
}

struct TagEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var newTag: String
    let onAdd: (String) -> Void

    var body: some View {
        NavigationView {
            VStack {
                TextField("Tag name", text: $newTag)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Spacer()
            }
            .navigationTitle("Add Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        onAdd(newTag)
                        newTag = ""
                        dismiss()
                    }
                    .disabled(newTag.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct SavedOutputsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cloudKitManager: CloudKitManager
    let promptID: UUID

    var savedOutputs: [SavedOutputModel] {
        cloudKitManager.savedOutputsForPrompt(promptID)
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(savedOutputs) { output in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(output.output)
                            .lineLimit(3)

                        HStack {
                            Text(output.createdAt.formatted(.dateTime))
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Spacer()

                            if output.isFavorite {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                    .foregroundColor(.pink)
                            }
                        }
                    }
                    .swipeActions {
                        Button("Delete", role: .destructive) {
                            Task {
                                await cloudKitManager.deleteSavedOutput(output)
                            }
                        }

                        Button {
                            var updatedOutput = output
                            updatedOutput.isFavorite.toggle()
                            Task {
                                await cloudKitManager.saveSavedOutput(updatedOutput)
                            }
                        } label: {
                            Image(systemName: output.isFavorite ? "heart.slash" : "heart")
                        }
                        .tint(.pink)
                    }
                }
            }
            .navigationTitle("Saved Outputs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// Flow Layout for tags
struct FlowLayout<Item: Hashable, ItemView: View>: View {
    let items: [Item]
    let itemView: (Item) -> ItemView

    init(items: [Item], @ViewBuilder itemView: @escaping (Item) -> ItemView) {
        self.items = items
        self.itemView = itemView
    }

    var body: some View {
        GeometryReader { geometry in
            content(availableWidth: geometry.size.width)
        }
    }

    private func content(availableWidth: CGFloat) -> some View {
        var width: CGFloat = 0
        var height: CGFloat = 0

        return ZStack(alignment: .topLeading) {
            ForEach(Array(items.enumerated()), id: \.element) { index, item in
                itemView(item)
                    .alignmentGuide(.leading) { dimensions in
                        if abs(width - dimensions.width) > availableWidth {
                            width = 0
                            height -= dimensions.height
                        }
                        let result = width
                        if index < items.count - 1 {
                            width -= dimensions.width
                        } else {
                            width = 0
                        }
                        return result
                    }
                    .alignmentGuide(.top) { _ in
                        let result = height
                        if index < items.count - 1 {
                            height += 0
                        }
                        return result
                    }
            }
        }
    }
}

#Preview {
    PromptDetailView(prompt: PromptModel(title: "Sample Prompt", systemPrompt: "You are a helpful assistant", userPrompt: "Help me write code"))
        .environmentObject(CloudKitManager())
        .environmentObject(AFMService())
}
