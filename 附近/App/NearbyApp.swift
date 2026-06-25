import SwiftUI
import SwiftData

@main
struct NearbyApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Post.self, Response.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: false)
            )
        } catch {
            fatalError("Failed to init SwiftData container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .task { @MainActor in
                    let context = container.mainContext
                    let bank = TaskBank.loadSync()
                    await MockSeeder.seedIfNeeded(context: context, taskBank: bank)
                }
        }
        .modelContainer(container)
    }
}

