# Contract Review: Sprint 4 — Directory Metadata Chain of Responsibility

## Assessment: APPROVED

## Scope Coverage

The contract covers all 10 acceptance criteria from the spec for Sprint 4:

| Spec Criterion | Contract Coverage | Status |
|---|---|---|
| 1. `GameMetadataHandler` abstract base class with `setNext()` and `handle()` | Covered in §1 (new file `game_metadata_handler.dart`) | ✅ |
| 2. `DirectoryContext` with executable path, file name, directory path, mutable fields | Covered in §1 (new file `directory_context.dart`) | ✅ |
| 3. `SteamDirectoryHandler` detects `steamapps/common/` and parses `appmanifest_*.acf` | Covered in §1 (new file `steam_directory_handler.dart`) | ✅ |
| 4. `DefaultMetadataHandler` uses `FilenameCleaner` | Covered in §1 (new file `default_metadata_handler.dart`) | ✅ |
| 5. `DirectoryMetadataChain` builder wires `SteamDirectoryHandler` → `DefaultMetadataHandler` | Covered in §1 (new file `directory_metadata_chain.dart`) | ✅ |
| 6. `AddGameBloc` uses chain during manual add to set initial title | Covered in §3 (`_onFileSelected` integration) | ✅ |
| 7. `AddGameBloc` uses chain during scan confirmation | Covered in §3 (`_onConfirmScanSelection` integration) | ✅ |
| 8. `DiscoveredExecutableModel` extended with optional `suggestedTitle` | Covered in §2 | ✅ |
| 9. Unit tests for Steam detection, ACF parsing, fallback, chain ordering | Covered in §5 (5 new test files) | ✅ |
| 10. `flutter analyze` and `flutter test` pass | Covered in Success Criteria 1 and 8 | ✅ |

**Note on Criterion 6**: The spec literally says the chain should be used "during manual add (`_onConfirmManualAdd`)". The contract instead invokes the chain in `_onFileSelected`. This is a *superior* design choice: the user sees the suggested title immediately in the form and can edit it before saving. The "before saving" requirement is still satisfied. No change needed.

## Success Criteria Review

All 8 success criteria in the contract are specific and testable:

1. **Chain Architecture Exists**: "files exist in X directory and `flutter analyze` reports zero errors" — testable via inspection + analyzer. ✅
2. **Steam Directory Detection Works**: Mock-based unit test with matching `possibleExecutablePaths` — testable. ✅
3. **Default Fallback Works**: Unit test asserting `FilenameCleaner.cleanForDisplay` is called and no delegation occurs — testable. ✅
4. **Chain Ordering Is Correct**: Unit test with both Steam-match and non-Steam-match scenarios — testable. ✅
5. **`DiscoveredExecutableModel` Has `suggestedTitle`**: Inspection + analyzer — testable. ✅
6. **`AddGameBloc` Integrates the Chain**: Unit tests for `FileSelected`, `ConfirmScanSelection`, and `ConfirmManualAdd` — testable. ✅
7. **DI Registration**: Inspection + app builds/runs — testable. ✅
8. **All Existing Tests Pass**: `flutter test` — testable. ✅

## Technical Feasibility Assessment

### Existing Code Leverage
- **`SteamManifestParser`**: The contract correctly uses `scanLibrary(libraryPath)` and matches against `manifest.possibleExecutablePaths`. This aligns perfectly with the existing API.
- **`FilenameCleaner.cleanForDisplay()`**: Correctly referenced as the terminal handler's logic.
- **`AddGameBloc`**: The current `_onFileSelected` and `_onConfirmScanSelection` handlers use `event.fileName.replaceAll('.exe', '')` as the title. The contract's proposed async chain invocation in `_onFileSelected` is a clean replacement.
- **`DiscoveredExecutableModel`**: Adding `suggestedTitle` as a runtime-only nullable field is straightforward and low-risk.
- **`di.dart`**: `AddGameBloc` is already registered as a `registerFactory`, which matches the contract's requirement for fresh state per dialog.

### Minor Concerns / Suggestions

1. **Path extraction in `_onFileSelected`**: The contract's example code uses `event.path.lastIndexOf(platformSeparator)`, but `platformSeparator` is not in scope within `AddGameBloc`. Recommend using the `path` package's `dirname()` function (already a standard dependency in Flutter projects) instead of manual string slicing. This is more robust across platforms.

2. **`DiscoveredExecutableModel` equality/hashCode**: The contract correctly notes that `==` and `hashCode` should remain path-based. Since `suggestedTitle` is mutable and runtime-only, two executables at the same path are identical regardless of suggested title. This is the right call — just make sure the comment in the code is clear.

3. **DI registration granularity**: The contract says "register `DirectoryMetadataChain.build` as a factory or singleton." Since the chain is stateless and only wraps `SteamManifestParser` (already a singleton), a singleton is fine. A factory also works but is unnecessary. No issue either way.

4. **Test naming**: The contract proposes `test/presentation/blocs/add_game/add_game_bloc_test.dart`. There are currently no existing tests for `AddGameBloc`, so this is a new file. Confirming: the Generator should mock `GameRepository`, `HomeRepositoryImpl`, and the metadata chain (or `SteamManifestParser`), and must use `registerFallbackValue` for any custom mocktail types.

## Out of Scope Validation

The contract correctly excludes:
- RAWG fallback in chain (handled by Sprints 2–3 metadata pipeline) ✅
- Persistent storage of `suggestedTitle` (runtime-only, as specified) ✅
- UI changes to display suggested titles (out of scope) ✅
- Title confidence scoring (out of scope) ✅
- Background/scheduled metadata refresh (out of scope) ✅

No scope creep detected.

## Test Plan Preview

During evaluation I will verify:
1. **File existence**: All 5 new source files and 5 new test files exist.
2. **Analyzer**: `flutter analyze` passes with zero errors.
3. **Unit tests**: All new tests pass (mocktail-based handler tests, chain builder tests, BLoC integration tests).
4. **Regression**: All 370+ existing tests still pass.
5. **Integration**: Run the app, manually add a game, and verify the initial title is populated from the chain (either Steam title or cleaned filename).
6. **Edge cases**: Test what happens when an executable is in a `steamapps/common/` path but no manifest matches — should fall back to cleaned filename.

## Suggested Changes (Non-blocking)

1. In the BLoC integration section, replace the manual path separator logic with `p.dirname(event.path)` from the `path` package.
2. Add a brief code comment in `DiscoveredExecutableModel` explaining why `suggestedTitle` is excluded from `==`/`hashCode`.
3. Consider whether `GameMetadataHandler.handle()` should return `Future<void>` or `Future<bool>` (success indicator). The current contract uses `Future<void>` which is fine since state is mutated in `DirectoryContext`, but a return value could make testing slightly cleaner. Not a blocker.

---

**Verdict**: The contract is well-scoped, technically feasible, properly leverages existing code, and includes clear testable success criteria. Approved for implementation.
