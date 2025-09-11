import SwiftUI

struct ContentView: View {
    @EnvironmentObject var promptStore: PromptStore
    @State private var selectedPrompt: PromptModel?
    @State private var showingNewPrompt = false
    @State private var searchText = ""

    var body: some View {
        NavigationSplitView {
            SidebarView(
                selectedPrompt: $selectedPrompt,
                searchText: $searchText,
                showingNewPrompt: $showingNewPrompt
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
                promptStore.addPrompt(newPrompt)
                selectedPrompt = newPrompt
            }
        }
    }
}

struct EmptyDetailView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "text.bubble.fill")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Prompt Playground")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Create and organize your prompts")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Select a prompt from the sidebar to get started, or create a new one.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
    }
}

struct NewPromptView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    let onSave: (PromptModel) -> Void

    var body: some View {
        NavigationView {
            Form {
                Section("Prompt Details") {
                    TextField("Title", text: $title)
                        .textFieldStyle(.roundedBorder)
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
                            title: title.isEmpty ? "New Prompt" : title
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


#Preview {
    ContentView()
        .environmentObject(PromptStore())
}
