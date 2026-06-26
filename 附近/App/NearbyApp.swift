import SwiftUI
import SwiftData
import UIKit

@main
struct NearbyApp: App {
    let container: ModelContainer

    init() {
        // Set window + system chrome backgrounds to paper-50 so status bar and
        // home indicator areas don't show system black.
        let paper = UIColor(red: 0xFA/255, green: 0xF6/255, blue: 0xEE/255, alpha: 1)
        UIWindow.appearance().backgroundColor = paper

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

