import SwiftUI

@main
struct PromptPlaygroundApp: App {
    @StateObject private var promptStore = PromptStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(promptStore)
        }
        .windowResizability(.contentSize)
        .windowStyle(.automatic)
    }
}
