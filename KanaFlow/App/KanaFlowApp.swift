import SwiftUI
import SwiftData
import SQLite3

@main
struct KanaFlowApp: App {
    let container: ModelContainer

    init() {
        migrateStoreIfNeeded()
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

// MARK: - Pre-migration shim
//
// SwiftData's migration plan machinery cannot match the stored schema checksum
// (the checksum was produced by a top-level class; nested VersionedSchema classes
// produce a different checksum even with identical fields). This function bypasses
// SwiftData entirely by operating directly on the SQLite file:
//
//  1. Adds any missing handwriting-metric columns (REAL DEFAULT 0.0).
//  2. Clears Z_METADATA so SwiftData has no old checksum to compare against;
//     on next open it adopts the store with the current model and writes
//     fresh correct metadata. Subsequent launches are a no-op.

private func migrateStoreIfNeeded() {
    guard let appSupport = FileManager.default
        .urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
    let storeURL = appSupport.appending(path: "default.store")
    guard FileManager.default.fileExists(atPath: storeURL.path) else { return }

    var db: OpaquePointer?
    guard sqlite3_open(storeURL.path, &db) == SQLITE_OK else { return }
    defer { sqlite3_close(db) }

    // Read existing columns
    var existingColumns: Set<String> = []
    var stmt: OpaquePointer?
    sqlite3_prepare_v2(db, "PRAGMA table_info(ZCHARACTERPROGRESS)", -1, &stmt, nil)
    while sqlite3_step(stmt) == SQLITE_ROW {
        if let cname = sqlite3_column_text(stmt, 1) {
            existingColumns.insert(String(cString: cname).uppercased())
        }
    }
    sqlite3_finalize(stmt)

    // Add any missing handwriting-metric columns
    let needed = [
        "ZTYPEBSHAPEEMA", "ZTYPEBLATESTSHAPE", "ZTYPEBLATESTPROPORTION",
        "ZTYPEBLATESTSTROKEORDER", "ZTYPEBLATESTCONSISTENCY", "ZTYPEBLATESTOVERALL"
    ]
    let missing = needed.filter { !existingColumns.contains($0) }
    guard !missing.isEmpty else { return }  // already migrated — fast path

    for col in missing {
        sqlite3_exec(db, "ALTER TABLE ZCHARACTERPROGRESS ADD COLUMN \(col) REAL DEFAULT 0.0",
                     nil, nil, nil)
    }

    // Clear schema metadata so SwiftData adopts the store with the current model
    sqlite3_exec(db, "DELETE FROM Z_METADATA", nil, nil, nil)
}
