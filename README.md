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
