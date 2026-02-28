import SwiftUI
import SwiftData

@main
struct KanaFlowApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: CharacterProgress.self)
        } catch {
            // Schema changed (e.g. new fields added). Wipe the local store and
            // start fresh rather than crashing. Progress data will be reset.
            Self.deleteDefaultStore()
            do {
                container = try ModelContainer(for: CharacterProgress.self)
            } catch {
                fatalError("Failed to create ModelContainer after store reset: \(error)")
            }
        }
    }

    private static func deleteDefaultStore() {
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
        let base = appSupport.appending(path: "default.store")
        for suffix in ["", "-wal", "-shm"] {
            try? fm.removeItem(at: URL(fileURLWithPath: base.path + suffix))
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}
