import Foundation

struct PromptModel: Identifiable, Codable {
    var id: UUID
    var title: String
    var systemPrompt: String
    var userPrompt: String
    var temperature: Double
    var maxTokens: Int
    var createdAt: Date
    var modifiedAt: Date

    init(
        title: String = "New Prompt",
        systemPrompt: String = "",
        userPrompt: String = "",
        temperature: Double = 0.7,
        maxTokens: Int = 1000
    ) {
        self.id = UUID()
        self.title = title
        self.systemPrompt = systemPrompt
        self.userPrompt = userPrompt
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    // Estimated character count for max tokens (rough estimate: 1 token ≈ 4 characters)
    var estimatedCharacters: Int {
        return maxTokens * 4
    }

    // Estimated word count for max tokens (rough estimate: 1 token ≈ 0.75 words)
    var estimatedWords: Int {
        return Int(Double(maxTokens) * 0.75)
    }
}
