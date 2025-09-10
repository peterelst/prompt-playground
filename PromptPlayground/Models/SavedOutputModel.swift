import Foundation
import CloudKit

struct SavedOutputModel: Identifiable, Codable {
    var id: UUID
    let promptID: UUID
    var output: String
    var systemPrompt: String
    var userPrompt: String
    var temperature: Double
    var maxTokens: Int
    var actualTokensUsed: Int?
    var isFavorite: Bool
    var createdAt: Date
    var notes: String

    // CloudKit support
    var recordID: CKRecord.ID?

    init(
        promptID: UUID,
        output: String,
        systemPrompt: String,
        userPrompt: String,
        temperature: Double,
        maxTokens: Int,
        actualTokensUsed: Int? = nil,
        notes: String = ""
    ) {
        self.id = UUID()
        self.promptID = promptID
        self.output = output
        self.systemPrompt = systemPrompt
        self.userPrompt = userPrompt
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.actualTokensUsed = actualTokensUsed
        self.isFavorite = false
        self.createdAt = Date()
        self.notes = notes
    }

    // CloudKit record conversion
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "SavedOutputModel", recordID: recordID ?? CKRecord.ID())
        record["id"] = id.uuidString
        record["promptID"] = promptID.uuidString
        record["output"] = output
        record["systemPrompt"] = systemPrompt
        record["userPrompt"] = userPrompt
        record["temperature"] = temperature
        record["maxTokens"] = maxTokens
        record["actualTokensUsed"] = actualTokensUsed ?? 0
        record["isFavorite"] = isFavorite ? 1 : 0
        record["createdAt"] = createdAt
        record["notes"] = notes
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> SavedOutputModel? {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let promptIDString = record["promptID"] as? String,
              let promptID = UUID(uuidString: promptIDString),
              let output = record["output"] as? String,
              let systemPrompt = record["systemPrompt"] as? String,
              let userPrompt = record["userPrompt"] as? String,
              let temperature = record["temperature"] as? Double,
              let maxTokens = record["maxTokens"] as? Int,
              let actualTokensUsed = record["actualTokensUsed"] as? Int,
              let isFavoriteInt = record["isFavorite"] as? Int,
              let createdAt = record["createdAt"] as? Date,
              let notes = record["notes"] as? String else {
            return nil
        }

        var savedOutput = SavedOutputModel(
            promptID: promptID,
            output: output,
            systemPrompt: systemPrompt,
            userPrompt: userPrompt,
            temperature: temperature,
            maxTokens: maxTokens,
            actualTokensUsed: actualTokensUsed > 0 ? actualTokensUsed : nil,
            notes: notes
        )

        savedOutput.id = id
        savedOutput.isFavorite = isFavoriteInt == 1
        savedOutput.createdAt = createdAt
        savedOutput.recordID = record.recordID

        return savedOutput
    }
}
