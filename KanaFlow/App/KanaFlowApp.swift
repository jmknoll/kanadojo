import SwiftUI
import SwiftData

@main
struct KanaFlowApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: CharacterProgress.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
