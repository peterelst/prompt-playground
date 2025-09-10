import Foundation
import CloudKit

struct ProjectModel: Identifiable, Codable {
    var id: UUID
    var name: String
    var description: String
    var color: String // Hex color string
    var createdAt: Date
    var modifiedAt: Date

    // CloudKit support
    var recordID: CKRecord.ID?

    init(name: String = "New Project", description: String = "", color: String = "#007AFF") {
        self.id = UUID()
        self.name = name
        self.description = description
        self.color = color
        self.createdAt = Date()
        self.modifiedAt = Date()
    }

    // CloudKit record conversion
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "ProjectModel", recordID: recordID ?? CKRecord.ID())
        record["id"] = id.uuidString
        record["name"] = name
        record["description"] = description
        record["color"] = color
        record["createdAt"] = createdAt
        record["modifiedAt"] = modifiedAt
        return record
    }

    static func fromCKRecord(_ record: CKRecord) -> ProjectModel? {
        guard let idString = record["id"] as? String,
              let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let description = record["description"] as? String,
              let color = record["color"] as? String,
              let createdAt = record["createdAt"] as? Date,
              let modifiedAt = record["modifiedAt"] as? Date else {
            return nil
        }

        var project = ProjectModel(name: name, description: description, color: color)
        project.id = id
        project.createdAt = createdAt
        project.modifiedAt = modifiedAt
        project.recordID = record.recordID

        return project
    }
}
