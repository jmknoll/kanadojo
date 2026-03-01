import SwiftData
import Foundation

// MARK: - Schema V1
// CharacterProgress with a single shared SM-2 track for both quiz types.

enum SchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] { [CharacterProgress.self] }

    @Model
    final class CharacterProgress {
        @Attribute(.unique) var characterId: String
        var correctCount: Int
        var incorrectCount: Int
        var lastPracticed: Date?
        var typeACorrect: Int
        var typeAIncorrect: Int
        var typeBCorrect: Int
        var typeBIncorrect: Int
        var intervalDays: Int
        var easeFactor: Double
        var consecutiveCorrect: Int
        var nextReviewDate: Date?

        init(characterId: String) {
            self.characterId = characterId
            self.correctCount = 0
            self.incorrectCount = 0
            self.lastPracticed = nil
            self.typeACorrect = 0
            self.typeAIncorrect = 0
            self.typeBCorrect = 0
            self.typeBIncorrect = 0
            self.intervalDays = 1
            self.easeFactor = 2.5
            self.consecutiveCorrect = 0
            self.nextReviewDate = nil
        }
    }
}

// MARK: - Schema V2
// CharacterProgress with independent SM-2 tracks per quiz type (typeA / typeB).

enum SchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    // References the current top-level CharacterProgress (in CharacterProgress.swift)
    static var models: [any PersistentModel.Type] { [CharacterProgress.self] }
}

// MARK: - Migration Plan

enum AppMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] { [SchemaV1.self, SchemaV2.self] }
    static var stages: [MigrationStage] { [migrateV1toV2] }

    // Lightweight schema migration (SwiftData drops old SM-2 columns and adds new
    // typeA*/typeB* ones). The didMigrate hook corrects any zero-valued defaults that
    // SQLite assigns to newly-added non-optional numeric columns.
    static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            let all = try context.fetch(FetchDescriptor<CharacterProgress>())
            for record in all {
                if record.typeAIntervalDays <= 0 { record.typeAIntervalDays = 1 }
                if record.typeAEaseFactor < 1.3  { record.typeAEaseFactor = 2.5 }
                if record.typeBIntervalDays <= 0 { record.typeBIntervalDays = 1 }
                if record.typeBEaseFactor < 1.3  { record.typeBEaseFactor = 2.5 }
            }
            try context.save()
        }
    )
}
