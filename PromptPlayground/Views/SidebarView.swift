import SwiftUI

struct SidebarView: View {
    @EnvironmentObject var promptStore: PromptStore
    @Binding var selectedPrompt: PromptModel?
    @Binding var searchText: String
    @Binding var showingNewPrompt: Bool

    var filteredPrompts: [PromptModel] {
        promptStore.searchPrompts(query: searchText)
    }

    var body: some View {
        List(selection: $selectedPrompt) {
            Section {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search prompts...", text: $searchText)
                }
                .padding(.vertical, 4)
            }

            Section {
                ForEach(filteredPrompts) { prompt in
                    PromptRowView(prompt: prompt)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button("Delete", role: .destructive) {
                                promptStore.deletePrompt(prompt)
                                if selectedPrompt?.id == prompt.id {
                                    selectedPrompt = nil
                                }
                            }
                        }
                }
            } header: {
                HStack {
                    Text("\(filteredPrompts.count) Prompts")
                    Spacer()
                    Button {
                        showingNewPrompt = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .navigationTitle("Prompts")
        .onAppear {
            if selectedPrompt == nil && !filteredPrompts.isEmpty {
                selectedPrompt = filteredPrompts.first
            }
        }
    }
}

struct PromptRowView: View {
    let prompt: PromptModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(prompt.title)
                .font(.headline)
                .lineLimit(1)

            if !prompt.userPrompt.isEmpty {
                Text(prompt.userPrompt)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            HStack {
                Text("Temp: \(prompt.temperature, specifier: "%.2f")")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Text("Tokens: \(prompt.maxTokens)")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                Text(prompt.modifiedAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    NavigationView {
        SidebarView(
            selectedPrompt: .constant(nil),
            searchText: .constant(""),
            showingNewPrompt: .constant(false)
        )
        .environmentObject(PromptStore())
    }
}
