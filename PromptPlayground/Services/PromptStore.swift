import Foundation

@MainActor
class PromptStore: ObservableObject {
    @Published var prompts: [PromptModel] = []

    private let userDefaults = UserDefaults.standard
    private let promptsKey = "saved_prompts"

    init() {
        loadPrompts()
    }

    // MARK: - Loading and Saving

    private func loadPrompts() {
        guard let data = userDefaults.data(forKey: promptsKey),
              let decodedPrompts = try? JSONDecoder().decode([PromptModel].self, from: data) else {
            // Initialize with sample prompts if no saved data exists
            prompts = createSamplePrompts()
            savePrompts()
            return
        }

        prompts = decodedPrompts.sorted { $0.modifiedAt > $1.modifiedAt }
    }

    private func createSamplePrompts() -> [PromptModel] {
        return [
            PromptModel(
                title: "Code Review Assistant",
                systemPrompt: "You are an experienced software engineer who provides constructive code reviews. Focus on code quality, best practices, potential bugs, and suggestions for improvement.",
                userPrompt: "Please review this code and provide feedback:",
                temperature: 0.3,
                maxTokens: 1500
            ),
            PromptModel(
                title: "Creative Writing Helper",
                systemPrompt: "You are a creative writing assistant who helps with storytelling, character development, and narrative structure. You provide imaginative and engaging suggestions.",
                userPrompt: "Help me develop this story idea:",
                temperature: 0.8,
                maxTokens: 2000
            ),
            PromptModel(
                title: "Technical Explanation",
                systemPrompt: "You are a technical educator who explains complex concepts in simple, understandable terms. Use analogies and examples when helpful.",
                userPrompt: "Explain this technical concept:",
                temperature: 0.4,
                maxTokens: 1200
            ),
            PromptModel(
                title: "Data Analysis Assistant",
                systemPrompt: "You are a data analyst who helps interpret data, identify trends, and suggest actionable insights. Be precise and data-driven in your responses.",
                userPrompt: "Analyze this data and provide insights:",
                temperature: 0.2,
                maxTokens: 1800
            )
        ]
    }

    private func savePrompts() {
        guard let data = try? JSONEncoder().encode(prompts) else { return }
        userDefaults.set(data, forKey: promptsKey)
    }

    // MARK: - CRUD Operations

    func addPrompt(_ prompt: PromptModel) {
        prompts.insert(prompt, at: 0)
        savePrompts()
    }

    func updatePrompt(_ prompt: PromptModel) {
        var updatedPrompt = prompt
        updatedPrompt.modifiedAt = Date()

        if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
            prompts[index] = updatedPrompt
            // Re-sort to move updated prompt to top
            prompts.sort { $0.modifiedAt > $1.modifiedAt }
            savePrompts()
        }
    }

    func deletePrompt(_ prompt: PromptModel) {
        prompts.removeAll { $0.id == prompt.id }
        savePrompts()
    }

    // MARK: - Utility Methods

    func searchPrompts(query: String) -> [PromptModel] {
        if query.isEmpty {
            return prompts
        }

        return prompts.filter { prompt in
            prompt.title.localizedCaseInsensitiveContains(query) ||
            prompt.systemPrompt.localizedCaseInsensitiveContains(query) ||
            prompt.userPrompt.localizedCaseInsensitiveContains(query)
        }
    }
}
