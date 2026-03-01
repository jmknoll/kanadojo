# Kana Flow

A native iOS app for learning Japanese kana (hiragana and katakana).

## Tech Stack

- Swift 5.9
- SwiftUI
- iOS 17+ deployment target
- XcodeGen (`project.yml`) for project file generation

## Project Structure

```
KanaFlow/
├── App/           # App entry point and Info.plist
├── Data/          # Progress persistence (UserDefaults)
├── Logic/         # Quiz logic and SVG path parsing
├── Models/        # Kana data, models, stroke order data
├── Theme/         # App-wide styling (AppTheme)
├── ViewModels/    # ObservableObject view models
└── Views/
    ├── Home/      # Home screen
    ├── Quiz/      # Quiz play, card, input, canvas, summary
    ├── QuizSetup/ # Kana type, group, quiz type selectors
    └── Shared/    # Reusable UI components
Assets.xcassets/   # App icon and accent color
docs/              # Project documentation
project.yml        # XcodeGen project definition
```

## Development

1. Install XcodeGen if needed: `brew install xcodegen`
2. Generate the Xcode project: `xcodegen generate`
3. Open `KanaFlow.xcodeproj` in Xcode
4. Build and run on an iOS 17+ simulator or device

## Documentation

- [PRD](docs/PRD.md) - Product requirements and phased task breakdown

## Data Persistence & Migration

Progress data is stored with SwiftData in `CharacterProgress` (one record per kana character).

### Adding new fields to CharacterProgress

**Never use the wipe-on-failure pattern.** Instead, use SwiftData's versioned schema migration:

1. **Define a new schema version** in `KanaFlow/Data/AppMigrationPlan.swift`:
   - Add a new `SchemaVN` enum (copy the previous version's `CharacterProgress` definition as-is)
   - Add a new `SchemaVN+1` enum pointing at the current top-level `CharacterProgress`

2. **Add a migration stage** to `AppMigrationPlan.stages`:
   - Use `MigrationStage.lightweight` for purely additive changes with no data to transform
   - Use `MigrationStage.custom` when new non-optional numeric fields need correct defaults (SQLite assigns 0 to new columns — the `didMigrate` hook can fix them)

3. **Update `AppMigrationPlan.schemas`** to include the new schema version.

```swift
// Example: adding SchemaV3
enum SchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] { [CharacterProgress.self] }
}

static let migrateV2toV3 = MigrationStage.custom(
    fromVersion: SchemaV2.self,
    toVersion: SchemaV3.self,
    willMigrate: nil,
    didMigrate: { context in
        // fix any zero defaults from SQLite here
        try context.save()
    }
)
```

Correct/incorrect counts (the core user data) survive all schema migrations. SM-2 interval state may reset to defaults — that's acceptable since it self-corrects after a few quiz sessions.

## Notes

- Xcode 15+ required
- Building Quiz Mode first (Phase 1), Study Mode later
