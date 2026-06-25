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
            ContentView()
        }
        .modelContainer(container)
    }
}

struct ContentView: View {
    var body: some View {
        Text("附近")
    }
}
