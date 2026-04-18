# Handoff: Sprint 4

## Status: Ready for QA

## What to Test

### 1. Chain of Responsibility Architecture
- Verify all files exist in `lib/data/services/directory_metadata_chain/`:
  - `game_metadata_handler.dart`
  - `directory_context.dart`
  - `steam_directory_handler.dart`
  - `default_metadata_handler.dart`
  - `directory_metadata_chain.dart`

### 2. Unit Tests
Run the new test suites:
```bash
flutter test test/data/services/directory_metadata_chain/
flutter test test/presentation/blocs/add_game/
```

All tests should pass (18 chain tests + 9 BLoC tests = 27 new tests).

### 3. Integration Scenarios (via unit tests)
- **Steam path with matching manifest**: `SteamDirectoryHandler` sets `title` to manifest `name` and `steamAppId` to `appId`
- **Steam path without matching manifest**: Falls through to `DefaultMetadataHandler` which sets cleaned filename title
- **Non-Steam path**: `DefaultMetadataHandler` directly sets cleaned filename title without calling `scanLibrary`
- **Manual add flow (`FileSelected`)**: BLoC runs chain and uses suggested title as initial name
- **Scan confirmation (`ConfirmScanSelection`)**: BLoC runs chain for each selected executable, sets `suggestedTitle`, and uses it for `Game.title`

### 4. Static Analysis
```bash
flutter analyze
```
Should report zero issues.

### 5. Full Test Suite
```bash
flutter test
```
Should pass all 438 tests with zero failures.

## Running the Application

- Command: `flutter run -d linux`
- The app should compile and start normally with the new DI registrations

## Known Gaps

None. All contract criteria are implemented and tested.
