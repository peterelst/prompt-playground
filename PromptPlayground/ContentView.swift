import SwiftUI

struct ContentView: View {
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var afmService: AFMService
    @State private var selectedPrompt: PromptModel?
    @State private var showingNewPrompt = false
    @State private var searchText = ""
    @State private var selectedProject: ProjectModel?
    @State private var showingSettings = false

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedPrompt: $selectedPrompt,
                selectedProject: $selectedProject,
                searchText: $searchText,
                showingNewPrompt: $showingNewPrompt,
                showingSettings: $showingSettings
            )
        } detail: {
            if let selectedPrompt = selectedPrompt {
                PromptDetailView(prompt: selectedPrompt)
            } else {
                EmptyDetailView()
            }
        }
        .sheet(isPresented: $showingNewPrompt) {
            NewPromptView { newPrompt in
                Task {
                    await cloudKitManager.savePrompt(newPrompt)
                    selectedPrompt = newPrompt
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .alert("Error", isPresented: .constant(cloudKitManager.error != nil)) {
            Button("OK") {
                cloudKitManager.error = nil
            }
        } message: {
            Text(cloudKitManager.error ?? "")
        }
    }
}

struct EmptyDetailView: View {
    @EnvironmentObject var afmService: AFMService

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Prompt Playground")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create and test prompts with Apple Foundation Models")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if !afmService.isAvailable {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title2)
                        .foregroundColor(.orange)

                    Text("Apple Foundation Models Unavailable")
                        .font(.headline)
                        .foregroundColor(.orange)

                    Text("You can still create and organize prompts. The Run button will be enabled when Apple Intelligence becomes available.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
        }
        .padding()
    }
}

struct NewPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @State private var title = ""
    @State private var selectedProject: ProjectModel?
    let onSave: (PromptModel) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Prompt Details") {
                    TextField("Title", text: $title)

                    Picker("Project", selection: $selectedProject) {
                        Text("No Project").tag(ProjectModel?.none)
                        ForEach(cloudKitManager.projects) { project in
                            Text(project.name).tag(ProjectModel?.some(project))
                        }
                    }
                }
            }
            .navigationTitle("New Prompt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        let newPrompt = PromptModel(
                            title: title.isEmpty ? "New Prompt" : title,
                            projectID: selectedProject?.id
                        )
                        onSave(newPrompt)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var iapManager: IAPManager
    @EnvironmentObject var cloudKitManager: CloudKitManager
    @EnvironmentObject var afmService: AFMService

    var body: some View {
        NavigationView {
            List {
                Section("Status") {
                    HStack {
                        Image(systemName: "icloud.fill")
                        Text("CloudKit")
                        Spacer()
                        Text(cloudKitStatus)
                            .foregroundColor(cloudKitManager.cloudKitStatus == .available ? .green : .orange)
                    }

                    HStack {
                        Image(systemName: "brain.head.profile")
                        Text("Apple Intelligence")
                        Spacer()
                        Text(afmService.isAvailable ? "Available" : "Unavailable")
                            .foregroundColor(afmService.isAvailable ? .green : .orange)
                    }
                }

                Section("Support") {
                    if let product = iapManager.supportProduct {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Support the Developer")
                                    .font(.headline)
                                Text("Help support continued development")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Button(product.displayPrice) {
                                Task {
                                    await iapManager.purchase(product)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(iapManager.isLoading)
                        }
                    }

                    Button("Restore Purchases") {
                        Task {
                            await iapManager.restorePurchases()
                        }
                    }
                    .disabled(iapManager.isLoading)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
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

    private var cloudKitStatus: String {
        switch cloudKitManager.cloudKitStatus {
        case .available:
            return "Available"
        case .noAccount:
            return "No Account"
        case .restricted:
            return "Restricted"
        case .couldNotDetermine:
            return "Unknown"
        case .temporarilyUnavailable:
            return "Temporarily Unavailable"
        @unknown default:
            return "Unknown"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(CloudKitManager())
        .environmentObject(AFMService())
        .environmentObject(IAPManager())
}
