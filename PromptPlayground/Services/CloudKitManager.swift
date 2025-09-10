import Foundation
import CloudKit
import SwiftUI

@MainActor
class CloudKitManager: ObservableObject {
    @Published var prompts: [PromptModel] = []
    @Published var projects: [ProjectModel] = []
    @Published var savedOutputs: [SavedOutputModel] = []
    @Published var isLoading = false
    @Published var error: String?
    @Published var cloudKitStatus: CKAccountStatus = .couldNotDetermine

    private let container = CKContainer.default()
    private var database: CKDatabase {
        container.privateCloudDatabase
    }

    func initialize() {
        checkCloudKitStatus()
        setupSubscriptions()
        fetchAllData()
    }

    private func checkCloudKitStatus() {
        container.accountStatus { [weak self] status, error in
            DispatchQueue.main.async {
                self?.cloudKitStatus = status
                if let error = error {
                    self?.error = "CloudKit Error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func setupSubscriptions() {
        // Set up CloudKit subscriptions for real-time sync
        let promptSubscription = CKQuerySubscription(
            recordType: "PromptModel",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        promptSubscription.notificationInfo = CKSubscription.NotificationInfo()
        promptSubscription.notificationInfo?.shouldSendContentAvailable = true

        let projectSubscription = CKQuerySubscription(
            recordType: "ProjectModel",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        projectSubscription.notificationInfo = CKSubscription.NotificationInfo()
        projectSubscription.notificationInfo?.shouldSendContentAvailable = true

        let outputSubscription = CKQuerySubscription(
            recordType: "SavedOutputModel",
            predicate: NSPredicate(value: true),
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        outputSubscription.notificationInfo = CKSubscription.NotificationInfo()
        outputSubscription.notificationInfo?.shouldSendContentAvailable = true

        database.save(promptSubscription) { _, _ in }
        database.save(projectSubscription) { _, _ in }
        database.save(outputSubscription) { _, _ in }
    }

    // MARK: - Data Fetching

    func fetchAllData() {
        Task {
            await withTaskGroup(of: Void.self) { group in
                group.addTask { await self.fetchPrompts() }
                group.addTask { await self.fetchProjects() }
                group.addTask { await self.fetchSavedOutputs() }
            }
        }
    }

    func fetchPrompts() async {
        isLoading = true
        do {
            let query = CKQuery(recordType: "PromptModel", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "modifiedAt", ascending: false)]

            let (records, _) = try await database.records(matching: query)
            let fetchedPrompts = records.compactMap { record in
                PromptModel.fromCKRecord(record.1)
            }

            self.prompts = fetchedPrompts
        } catch {
            self.error = "Failed to fetch prompts: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func fetchProjects() async {
        do {
            let query = CKQuery(recordType: "ProjectModel", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

            let (records, _) = try await database.records(matching: query)
            let fetchedProjects = records.compactMap { record in
                ProjectModel.fromCKRecord(record.1)
            }

            self.projects = fetchedProjects
        } catch {
            self.error = "Failed to fetch projects: \(error.localizedDescription)"
        }
    }

    func fetchSavedOutputs() async {
        do {
            let query = CKQuery(recordType: "SavedOutputModel", predicate: NSPredicate(value: true))
            query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]

            let (records, _) = try await database.records(matching: query)
            let fetchedOutputs = records.compactMap { record in
                SavedOutputModel.fromCKRecord(record.1)
            }

            self.savedOutputs = fetchedOutputs
        } catch {
            self.error = "Failed to fetch saved outputs: \(error.localizedDescription)"
        }
    }

    // MARK: - CRUD Operations

    func savePrompt(_ prompt: PromptModel) async {
        do {
            var updatedPrompt = prompt
            updatedPrompt.modifiedAt = Date()

            let record = updatedPrompt.toCKRecord()
            let savedRecord = try await database.save(record)

            if let index = prompts.firstIndex(where: { $0.id == prompt.id }) {
                if var savedPrompt = PromptModel.fromCKRecord(savedRecord) {
                    prompts[index] = savedPrompt
                }
            } else {
                if let savedPrompt = PromptModel.fromCKRecord(savedRecord) {
                    prompts.insert(savedPrompt, at: 0)
                }
            }
        } catch {
            self.error = "Failed to save prompt: \(error.localizedDescription)"
        }
    }

    func deletePrompt(_ prompt: PromptModel) async {
        guard let recordID = prompt.recordID else { return }

        do {
            try await database.deleteRecord(withID: recordID)
            prompts.removeAll { $0.id == prompt.id }

            // Also delete associated saved outputs
            savedOutputs.removeAll { $0.promptID == prompt.id }
        } catch {
            self.error = "Failed to delete prompt: \(error.localizedDescription)"
        }
    }

    func saveProject(_ project: ProjectModel) async {
        do {
            var updatedProject = project
            updatedProject.modifiedAt = Date()

            let record = updatedProject.toCKRecord()
            let savedRecord = try await database.save(record)

            if let index = projects.firstIndex(where: { $0.id == project.id }) {
                if let savedProject = ProjectModel.fromCKRecord(savedRecord) {
                    projects[index] = savedProject
                }
            } else {
                if let savedProject = ProjectModel.fromCKRecord(savedRecord) {
                    projects.append(savedProject)
                }
            }
        } catch {
            self.error = "Failed to save project: \(error.localizedDescription)"
        }
    }

    func deleteProject(_ project: ProjectModel) async {
        guard let recordID = project.recordID else { return }

        do {
            try await database.deleteRecord(withID: recordID)
            projects.removeAll { $0.id == project.id }

            // Remove project association from prompts
            for i in prompts.indices {
                if prompts[i].projectID == project.id {
                    prompts[i].projectID = nil
                    await savePrompt(prompts[i])
                }
            }
        } catch {
            self.error = "Failed to delete project: \(error.localizedDescription)"
        }
    }

    func saveSavedOutput(_ output: SavedOutputModel) async {
        do {
            let record = output.toCKRecord()
            let savedRecord = try await database.save(record)

            if let index = savedOutputs.firstIndex(where: { $0.id == output.id }) {
                if let savedOutput = SavedOutputModel.fromCKRecord(savedRecord) {
                    savedOutputs[index] = savedOutput
                }
            } else {
                if let savedOutput = SavedOutputModel.fromCKRecord(savedRecord) {
                    savedOutputs.insert(savedOutput, at: 0)
                }
            }
        } catch {
            self.error = "Failed to save output: \(error.localizedDescription)"
        }
    }

    func deleteSavedOutput(_ output: SavedOutputModel) async {
        guard let recordID = output.recordID else { return }

        do {
            try await database.deleteRecord(withID: recordID)
            savedOutputs.removeAll { $0.id == output.id }
        } catch {
            self.error = "Failed to delete saved output: \(error.localizedDescription)"
        }
    }

    // MARK: - Utility Methods

    func promptsForProject(_ project: ProjectModel) -> [PromptModel] {
        return prompts.filter { $0.projectID == project.id }
    }

    func promptsWithoutProject() -> [PromptModel] {
        return prompts.filter { $0.projectID == nil }
    }

    func savedOutputsForPrompt(_ promptID: UUID) -> [SavedOutputModel] {
        return savedOutputs.filter { $0.promptID == promptID }
    }

    func searchPrompts(query: String) -> [PromptModel] {
        if query.isEmpty { return prompts }

        return prompts.filter { prompt in
            prompt.title.localizedCaseInsensitiveContains(query) ||
            prompt.systemPrompt.localizedCaseInsensitiveContains(query) ||
            prompt.userPrompt.localizedCaseInsensitiveContains(query) ||
            prompt.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
}
