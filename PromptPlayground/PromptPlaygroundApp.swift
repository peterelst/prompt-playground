import SwiftUI
import CloudKit

@main
struct PromptPlaygroundApp: App {
    @StateObject private var cloudKitManager = CloudKitManager()
    @StateObject private var afmService = AFMService()
    @StateObject private var iapManager = IAPManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(cloudKitManager)
                .environmentObject(afmService)
                .environmentObject(iapManager)
                .onAppear {
                    cloudKitManager.initialize()
                    afmService.checkAvailability()
                    iapManager.loadProducts()
                }
        }
    }
}
