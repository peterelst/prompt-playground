import SwiftUI
import AppKit

struct PromptDetailView: View {
    @EnvironmentObject var promptStore: PromptStore
    @State var prompt: PromptModel

    @State private var title: String
    @State private var systemPrompt: String
    @State private var userPrompt: String
    @State private var temperature: Double
    @State private var maxTokens: Int

    init(prompt: PromptModel) {
        self.prompt = prompt
        self._title = State(initialValue: prompt.title)
        self._systemPrompt = State(initialValue: prompt.systemPrompt)
        self._userPrompt = State(initialValue: prompt.userPrompt)
        self._temperature = State(initialValue: prompt.temperature)
        self._maxTokens = State(initialValue: prompt.maxTokens)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header with title
                VStack(alignment: .leading, spacing: 12) {
                    TextField("Prompt Title", text: $title, axis: .vertical)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .textFieldStyle(.plain)
                        .onChange(of: title) { _, newValue in
                            saveChanges()
                        }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))

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
                                Text("Maximum Tokens")
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
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
                .cornerRadius(12)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveChanges() {
        var updatedPrompt = prompt
        updatedPrompt.title = title
        updatedPrompt.systemPrompt = systemPrompt
        updatedPrompt.userPrompt = userPrompt
        updatedPrompt.temperature = temperature
        updatedPrompt.maxTokens = maxTokens
        updatedPrompt.modifiedAt = Date()

        promptStore.updatePrompt(updatedPrompt)
        prompt = updatedPrompt
    }
}

#Preview {
    PromptDetailView(prompt: PromptModel(title: "Sample Prompt", systemPrompt: "You are a helpful assistant", userPrompt: "Help me write code"))
        .environmentObject(PromptStore())
}
