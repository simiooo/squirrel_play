# Squirrel Play - Agent Instructions

A Steam Big Picture-inspired game management Flutter desktop app for couch gaming with full gamepad support.

## Project Overview

Squirrel Play is a desktop-only Flutter application designed for TV/couch gaming environments. It provides a 10-foot UI for managing and launching PC games with gamepad navigation. The app supports game library management, Steam integration, directory scanning for executables, metadata fetching from RAWG API and Steam Store, and bilingual UI (English and Chinese Simplified).

**Primary target platform**: Linux desktop  
**Secondary platforms**: Windows, macOS  
**Flutter SDK**: ^3.11.4

## Technology Stack

- **Framework**: Flutter (desktop-only, Material 3 dark theme)
- **State Management**: flutter_bloc (BLoC pattern)
- **Navigation**: go_router with ShellRoute for persistent shell UI
- **Dependency Injection**: get_it (manual registration in `lib/app/di.dart`)
- **Database**: SQLite via sqflite_common_ffi (desktop FFI implementation)
- **HTTP Client**: dio
- **Gamepad Input**: gamepads package
- **Audio**: audioplayers (FLAC assets)
- **Window Management**: window_manager + system_tray
- **Localization**: flutter_gen_l10n with ARB files
- **Code Generation**: json_serializable, freezed, injectable_generator
- **Testing**: flutter_test, bloc_test, mocktail

## Build and Test Commands

```bash
# Requires Flutter SDK in PATH
export PATH="/home/simooo/flutter/bin:$PATH"

# Run app (desktop only — Linux primary target)
flutter run -d linux

# Run all tests (370 tests, do NOT use `dart test`)
flutter test

# Analyze code
flutter analyze

# Generate JSON serialization code (*.g.dart)
flutter pub run build_runner build --delete-conflicting-outputs

# Generate localization code from ARB files
flutter gen-l10n
```

Run `flutter analyze` then `flutter test` after any code change. Run both codegen commands after modifying model classes or ARB files.

## Platform Support and Build Configuration

The project includes platform directories for Linux, Windows, macOS, Android, iOS, and Web. However, the app is designed for **desktop-only** use:

- **Linux**: CMake build (`linux/CMakeLists.txt`), GTK application ID `com.example.squirrel_play`
- **Windows**: CMake build (`windows/CMakeLists.txt`), C++17, custom title bar (`TitleBarStyle.hidden`)
- **macOS**: Xcode project with standard Flutter macOS runner

The app uses `window_manager` for custom window chrome (hidden OS title bar), fullscreen toggle, and system tray integration. `sqflite_common_ffi` is required on all desktop platforms for database support.

## Code Organization

```
lib/
├── app/           # App entry, DI (di.dart), router (GoRouter configuration)
├── core/          # Theme, utilities, services, extensions, constants
│   ├── constants/
│   ├── extensions/
│   ├── i18n/      # LocaleCubit for runtime language switching
│   ├── services/  # WindowManagerService, PlatformInfo
│   ├── theme/     # AppTheme, DesignTokens (colors, typography, spacing)
│   └── utils/
├── data/          # Repository implementations, datasources, models, services
│   ├── datasources/local/   # DatabaseHelper, database constants
│   ├── datasources/remote/  # API clients
│   ├── models/              # Data models with JSON serialization (*.g.dart)
│   ├── repositories/        # Repository implementations
│   └── services/            # Business logic services
│       ├── directory_metadata_chain/  # Chain of Responsibility for game metadata
│       └── metadata/                  # RAWG, Steam metadata sources
├── domain/        # Entities, repository interfaces, validators, services
│   ├── entities/            # Pure business objects (e.g., Game)
│   ├── repositories/        # Abstract repository interfaces
│   ├── services/            # Domain service interfaces (e.g., GameLauncher)
│   └── validators/
├── presentation/  # UI layer (pages, widgets, blocs)
│   ├── blocs/               # One directory per BLoC/Cubit
│   ├── navigation/          # FocusTraversalService, GamepadHintProvider
│   ├── pages/               # Top-level pages (Home, Library, Settings, etc.)
│   └── widgets/             # Reusable widgets, dialog contents, focusable controls
└── l10n/          # Localization ARB files and generated Dart code
```

- **DI**: Manual registration in `lib/app/di.dart` using get_it
- **State**: BLoC pattern — all blocs in `presentation/blocs/`
- **Navigation**: GoRouter with ShellRoute providing persistent TopBar + GamepadNavBar
- **Focus**: Flutter `FocusScope` architecture (see below)

## Database Architecture

SQLite is used for local persistence with the following tables:
- `games` — game entries with executable paths, play counts, favorites
- `game_metadata` — fetched metadata (title, description, cover art, ratings)
- `game_genres` — genre associations
- `game_screenshots` — screenshot URLs
- `scan_directories` — user-configured directories for scanning

Database migrations are handled in `DatabaseHelper._onUpgrade()` (currently at version 5). Foreign key constraints are enabled.

**Critical**: `main.dart` **must** initialize sqflite FFI before `configureDependencies()`:

```dart
if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
```

Without this, the app crashes with `databaseFactory not initialized`.

## Window and System Tray

`WindowManagerService` handles:
- Window title, minimum size (800×600), default size (1280×720)
- Centered positioning, custom title bar
- Fullscreen toggle (F11 / Start button)
- System tray integration with Open/Hide/Quit menu
- Safe quit validation (warns if games are still running)

## Focus Architecture (Post-Sprint 3)

The app uses **Flutter's native `FocusScope`** for focus management, not manual node lists.

- **TopBar scope**: `router.dart` `_ShellWithFocusScope` wraps `TopBar` in a `FocusScopeNode` (debugLabel: `TopBarScope`)
- **Content scope**: `app_shell.dart` wraps page body in a `FocusScopeNode` (debugLabel: `ContentScope`)
- **Dialog scopes**: `AddGameDialog`, `GamepadFileBrowser`, etc. wrap their content in `FocusScope` for automatic focus trapping
- **Cross-scope wrapping**: `FocusTraversalService` handles TopBar ↔ Content wrapping via `wrapToTopBar()` / `wrapToContent()` using `FocusScopeNode.traversalDescendants`
- **Internal navigation**: Within a scope, `FocusNode.focusInDirection()` handles geometry-based traversal
- **Row/grid navigation**: `GameCardRow` calls `registerRow()`, `GameGrid` calls `registerGrid()` for precise directional control. These are the **only** manual registrations remaining.

**Do NOT add manual `registerContentNode` / `registerTopBarNode` calls.** Widgets inside a `FocusScope` are automatically focusable if they use `Focus` or `FocusableButton`.

## BLoC Registration Rules

- Use `registerFactory` for blocs that need fresh state per dialog/screen (e.g., `AddGameBloc`, `QuickScanBloc`)
- Use `registerSingleton` for services and repositories
- Use `registerLazySingleton` for long-lived blocs like `QuickScanBloc`

```dart
getIt.registerFactory<AddGameBloc>(() => AddGameBloc(...));
getIt.registerFactory<QuickScanBloc>(() => QuickScanBloc(...));
```

## Event Handler Registration

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

## Localization

The app supports English (`en`) and Chinese Simplified (`zh`).

- **ARB files**: `lib/l10n/app_en.arb` (template), `lib/l10n/app_zh.arb`
- **Generated files**: `lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_zh.dart`
- **Runtime switching**: `LocaleCubit` persists the chosen locale in `SharedPreferences`
- **Configuration**: `l10n.yaml` defines the template ARB and output class name

**Rules**:
- New strings must be added to both `app_en.arb` and `app_zh.arb`
- Every key must have a `@description` metadata entry
- Run `flutter gen-l10n` after modifying ARB files
- Use `AppLocalizations.of(context)!.<key>` in widgets

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

### Test Organization

```
test/
├── core/           # Core utilities, i18n tests
├── data/           # Repository, datasource, service tests
│   ├── datasources/remote/
│   ├── repositories/
│   └── services/
│       ├── directory_metadata_chain/
│       └── metadata/
└── presentation/   # Bloc, page, widget tests
    ├── blocs/
    ├── pages/
    └── widgets/
```

## Analysis Rules

From `analysis_options.yaml`:
- `always_use_package_imports` enforced (no relative imports)
- `require_trailing_commas` enforced
- `prefer_final_fields` and `prefer_final_locals` enforced
- Excludes generated files (`*.g.dart`, `*.freezed.dart`, `lib/l10n/**`)
- Strict casts and strict raw types enabled

## Design System

All visual design is tokenized in `lib/core/theme/design_tokens.dart`:

- **Colors**: `AppColors` — background (#0D0D0F), surface (#1A1A1E), primary accent (#FF6B2B), secondary accent (#00C9A7)
- **Typography**: Inter font via `google_fonts`, sizes on 4px grid (heading 32px, body 16px, caption 12px)
- **Spacing**: `AppSpacing` — multiples of 4px (xs=4, sm=8, md=12, lg=16, xl=24, xxl=32, xxxl=48, xxxxl=64)
- **Radii**: `AppRadii` — small=4, medium=8 (cards/buttons), large=12 (dialogs)
- **Elevations**: `AppElevations` — rest=2, focus=8, elevated=16
- **Animations**: `AppAnimationDurations` and `AppAnimationCurves` for consistent motion

The app uses a **dark theme only**, optimized for OLED with deep blacks. Game cards use a 2:3 aspect ratio (movie poster style) with responsive breakpoints.

## Focusable Widgets

The app has a family of reusable focusable wrappers for gamepad navigation. Follow these patterns when adding new interactive controls:
- `FocusableButton` — primary action buttons
- `FocusableListTile` — list row selections
- `FocusableSwitch` — toggle controls
- `FocusableSlider` — value sliders with D-pad left/right adjustment
- `FocusableTextField` — text inputs with focus border
- `PickerButton` — file/directory picker triggers

All use `AppColors.primaryAccent` for focus border, `AppColors.surfaceElevated` for focus background, and hook into `SoundService.instance.playFocusMove()`.

## Directory Metadata Chain of Responsibility

When a game is manually added or discovered via directory scanning, the app uses a **Chain of Responsibility** pattern to inspect the executable's sibling directory and determine the best initial title/metadata.

### Architecture

```
lib/data/services/directory_metadata_chain/
├── game_metadata_handler.dart      # Abstract base: setNext() + handle()
├── directory_context.dart           # Mutable context passed through the chain
├── steam_directory_handler.dart     # Detects Steam directories, parses appmanifest_*.acf
├── default_metadata_handler.dart    # Terminal handler: generates title from filename
└── directory_metadata_chain.dart    # Builder: wires handlers in order
```

### Handler Chain Order

1. **`SteamDirectoryHandler`** — checks if the executable is inside a `steamapps/common/` path structure. If so, it uses `SteamManifestParser` to find the matching `appmanifest_*.acf` file and extracts the official Steam game name and appId.
2. **`DefaultMetadataHandler`** — terminal fallback. Uses `FilenameCleaner.cleanForDisplay()` to generate a human-readable title from the executable filename (e.g., `"HollowKnight.exe"` → `"Hollow Knight"`).

### Usage

The chain is built via `DirectoryMetadataChain.build()` and injected into `AddGameBloc`:

```dart
// In DI (di.dart)
getIt.registerSingleton<DirectoryMetadataChain>(
  DirectoryMetadataChain.build(
    steamManifestParser: getIt<SteamManifestParser>(),
  ),
);
```

**Manual add flow** (`AddGameBloc._onFileSelected`): When a user picks an executable file, the chain is invoked immediately to populate the form's title field with the best guess.

**Scan flow** (`AddGameBloc._onConfirmScanSelection`): When discovered executables are confirmed, each gets processed through the chain, and `DiscoveredExecutableModel.suggestedTitle` is populated.

### Extending the Chain

To add a new handler (e.g., GOG Galaxy, Epic Games Store):

1. Create a class extending `GameMetadataHandler`:
   ```dart
   class EpicDirectoryHandler extends GameMetadataHandler {
     @override
     Future<void> handle(DirectoryContext context) async {
       if (/* can handle this directory */) {
         context.title = /* extract title */;
         return; // Handled — stop chain
       }
       await super.handle(context); // Pass to next handler
     }
   }
   ```

2. Register it in `DirectoryMetadataChain.build()` before `DefaultMetadataHandler`:
   ```dart
   static DirectoryMetadataChain build({...}) {
     final steam = SteamDirectoryHandler(...);
     final epic = EpicDirectoryHandler(...);
     final fallback = DefaultMetadataHandler();
     steam.setNext(epic);
     epic.setNext(fallback);
     return DirectoryMetadataChain(steam);
   }
   ```

3. Add unit tests in `test/data/services/directory_metadata_chain/`.

### Rules

- **Never call `context.title = null` after another handler has set it.** Handlers either populate the field and stop, or pass through unchanged.
- **`DefaultMetadataHandler` is always the terminal node.** It never calls `super.handle()`.
- **The chain is async** because it may perform file I/O (scanning manifests). Always `await chain.process(context)`.
- **`DirectoryContext` is mutable** by design — it accumulates parsed metadata as it flows through handlers. Treat it as a write-once accumulator (handlers should not overwrite each other's successful results).

## Common Pitfalls

1. **Missing event handlers**: Every BLoC event needs `on<EventType>()` registration
2. **Factory vs Singleton**: Blocs that need fresh state per dialog/screen use `registerFactory`, not `registerSingleton`
3. **Async gaps in BuildContext**: Guard async context usage with `mounted` checks
4. **Generated files**: Must regenerate after model changes — build errors often stem from stale `.g.dart`
5. **Package imports only**: Relative imports violate `analysis_options.yaml` and will fail CI
6. **Testing custom objects with mocktail**: Remember to `registerFallbackValue(FakeGame())` before using mocked methods that accept custom types
7. **Dialog FocusScope**: Wrap dialog content in `FocusScope` for automatic focus trapping. Do NOT use the removed `DialogFocusScope` widget or manual `registerContentNode` calls
8. **L10n keys**: New strings must be added to both `app_en.arb` and `app_zh.arb`, then run `flutter gen-l10n`
9. **FocusNode lifecycle**: Never create `FocusNode` inline in `build()` — always use state fields with `initState`/`dispose`
10. **Desktop-only assumptions**: The app assumes desktop windowing; do not introduce mobile-first patterns
11. **Gamepad-first UX**: All interactive elements must be reachable via directional pad navigation, not just mouse/touch
