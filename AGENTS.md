# Squirrel Play - Agent Instructions

A Steam Big Picture-inspired game management Flutter app for couch gaming with gamepad support.

## Essential Commands

```bash
# Requires Flutter SDK in PATH
export PATH="/home/simooo/flutter/bin:$PATH"

# Run app (desktop only)
flutter run -d linux

# Run all tests
flutter test

# Analyze code
flutter analyze

# Generate JSON serialization code (*.g.dart)
flutter pub run build_runner build --delete-conflicting-outputs

# Generate localization code from ARB files
flutter gen-l10n
```

## Architecture

```
lib/
├── app/           # App entry, DI (di.dart), router
├── core/          # Theme, utilities, services
├── data/          # Repositories impl, services, models
├── domain/        # Entities, repository interfaces
├── presentation/  # UI layer (pages, widgets, blocs)
└── l10n/          # Localization (generated)
```

- **DI**: Manual registration in `lib/app/di.dart` using get_it
- **State**: BLoC pattern — all blocs in `presentation/blocs/`
- **Navigation**: GoRouter with focus management observer

## Critical Setup Requirements

### sqflite_common_ffi Initialization (Desktop)

`main.dart` **must** initialize sqflite FFI before `configureDependencies()`:

```dart
if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

Without this, the app crashes with `databaseFactory not initialized`.

### BLoC Registration Rules

- Use `registerFactory` for blocs that need fresh state per dialog/screen (e.g., `AddGameBloc`, `QuickScanBloc`)
- Use `registerSingleton` for services and repositories

```dart
getIt.registerFactory<AddGameBloc>(() => AddGameBloc(...));
getIt.registerFactory<QuickScanBloc>(() => QuickScanBloc(...));
```

### Event Handler Registration

Every event in a BLoC must have a registered handler via `on<Event>()` in the constructor. Missing handlers cause runtime crashes:

```dart
Bad state: add(Event) was called without a registered event handler
```

## Code Generation

This project uses code generation for:
- **JSON models**: `*.g.dart` files via `json_serializable`
- **Localizations**: `lib/l10n/*.dart` from `lib/l10n/*.arb` files

Run both commands after modifying model classes or ARB files:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

## Audio Assets

Sound files are in `assets/sounds/` (FLAC format):
- `jump-retro-video-game-sfx-jump-c-sound.flac` → focus move
- `select-sound.flac` → focus select/back
- `transition-transition-whoosh-sound-sound.flac` → page transition
- `rechambering-finish-sound.flac` → scan complete
- `error-sound.flac` → scan error / general error

All audio playback goes through `SoundService` (lazy-loaded, graceful fallback if files missing).

## Testing

- **370 tests** across unit and widget tests
- Uses `mocktail` for mocking, `bloc_test` for BLoC tests
- Widget tests require proper BLoC providers in test widget tree
- `registerFallbackValue(FakeEntity())` is required in `setUpAll` when mocking methods that take custom objects
- Run with `flutter test` (not `dart test`)

## Analysis Rules

From `analysis_options.yaml`:
- `always_use_package_imports` enforced (no relative imports)
- `require_trailing_commas` enforced
- `prefer_final_fields` and `prefer_final_locals` enforced
- Excludes generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/**`)

## Common Pitfalls

1. **Missing event handlers**: Every BLoC event needs `on<EventType>()` registration
2. **Factory vs Singleton**: Blocs that need fresh state per dialog/screen use `registerFactory`, not `registerSingleton`
3. **Async gaps in BuildContext**: Guard async context usage with `mounted` checks
4. **Generated files**: Must regenerate after model changes — build errors often stem from stale `.g.dart`
5. **Package imports only**: Relative imports violate `analysis_options.yaml` and will fail CI
6. **Testing custom objects with mocktail**: Remember to `registerFallbackValue(FakeGame())` before using mocked methods that accept custom types
7. **FocusTraversalService registration**: All focusable widgets must register/unregister their `FocusNode` with `FocusTraversalService` in `initState`/`dispose`
8. **L10n keys**: New strings must be added to both `app_en.arb` and `app_zh.arb`, then run `flutter gen-l10n`

## Focusable Widgets

The app has a family of reusable focusable wrappers for gamepad navigation. Follow these patterns when adding new interactive controls:
- `FocusableButton` — primary action buttons
- `FocusableListTile` — list row selections
- `FocusableSwitch` — toggle controls
- `FocusableSlider` — value sliders with D-pad left/right adjustment
- `FocusableTextField` — text inputs with focus border

All use `AppColors.primaryAccent` for focus border, `AppColors.surfaceElevated` for focus background, and hook into `SoundService.instance.playFocusMove()`.
