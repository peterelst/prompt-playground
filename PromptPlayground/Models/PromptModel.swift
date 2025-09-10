import Foundation
import CloudKit

struct PromptModel: Identifiable, Codable {
    var id: UUID
    var title: String
    var systemPrompt: String
    var userPrompt: String
    var temperature: Double
    var maxTokens: Int
    var tags: [String]
    var projectID: UUID?
    var createdAt: Date
    var modifiedAt: Date
    var isFavorite: Bool

    // CloudKit support
    var recordID: CKRecord.ID?

    init(
        title: String = "New Prompt",
        systemPrompt: String = "",
        userPrompt: String = "",
        temperature: Double = 0.7,
        maxTokens: Int = 1000,
        tags: [String] = [],
        projectID: UUID? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.systemPrompt = systemPrompt
        self.userPrompt = userPrompt
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.tags = tags
        self.projectID = projectID
        self.createdAt = Date()
        self.modifiedAt = Date()
        self.isFavorite = false
        self.recordID = nil
    }

    // Estimated character count for max tokens (rough estimate: 1 token ≈ 4 characters)
    var estimatedCharacters: Int {
        return maxTokens * 4
    }

    // Estimated word count for max tokens (rough estimate: 1 token ≈ 0.75 words)
    var estimatedWords: Int {
        return Int(Double(maxTokens) * 0.75)
    }

    // CloudKit record conversion
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "PromptModel", recordID: recordID ?? CKRecord.ID())
        record["id"] = id.uuidString
        record["title"] = title
        record["systemPrompt"] = systemPrompt
        record["userPrompt"] = userPrompt
        record["temperature"] = temperature
        record["maxTokens"] = maxTokens
        record["tags"] = tags
        record["projectID"] = projectID?.uuidString
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        record["isFavorite"] = isFavorite ? 1 : 0
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> PromptModel? {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = record["title"] as? String,
              let systemPrompt = record["systemPrompt"] as? String,
              let userPrompt = record["userPrompt"] as? String,
              let temperature = record["temperature"] as? Double,
              let maxTokens = record["maxTokens"] as? Int,
              let tags = record["tags"] as? [String],
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date,
              let isFavoriteInt = record["isFavorite"] as? Int else {
            return nil
        }

        // Create the base prompt
        var prompt = PromptModel(
            title: title,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
            tags: tags
        )

        // Manually assign the fields that can't be set in the initializer
        prompt.id = id
        prompt.createdAt = createdAt
        prompt.modifiedAt = modifiedAt
        prompt.isFavorite = isFavoriteInt == 1
        prompt.recordID = record.recordID

        if let projectIDString = record["projectID"] as? String {
            prompt.projectID = UUID(uuidString: projectIDString)
        }

        return prompt
    }
}
