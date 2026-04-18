# Handoff: Sprint 3

## Status: Ready for QA

## What to Test

1. **Manual Add Tab strings**
   - Open the Add Game dialog → Manual Add tab.
   - Verify labels: "Executable File", "Browse...", "No file selected", "Game Name", "Enter game name", "Add Game".
   - Trigger validation errors (empty file/name) and verify "Invalid file" / "Invalid name" appear.

2. **Scan Directory Tab strings**
   - Open the Add Game dialog → Scan Directory tab.
   - Verify "Add Directory", "Start Scan", "Cancel" (during scan), "Select All", "Select None".
   - After a scan, verify the status line shows "Found X executables (Y selected)" and the confirm button reads "Add X Games".
   - Trigger an empty scan result and verify "No executables found", subtitle, and "Select Different Directories".
   - During adding, verify "Adding games..." appears.

3. **Steam Games Tab strings**
   - Open the Add Game dialog → Steam Games tab.
   - Verify "Initializing..." appears briefly.
   - In error state, verify "Default: {path}" and "Browse for Steam Folder".
   - In loaded state, verify "Steam Path:", "Select All", "Select None", "Rescan", "Found X games (Y already added)", "No Steam games found" (if empty), "App ID: {appId}", "Already Added" badge.
   - Verify import button states: "Import Selected Games" (zero selected) and "Import X Games" (with count).
   - During import, verify "Importing games...", "X of Y" progress, and current game name.
   - After import, verify "Import Complete!", "X games imported", "X skipped", "Errors:", and "Close".

4. **Gamepad File Browser strings**
   - Open the file browser (from Manual Add or Scan Directory).
   - Verify the dialog title "Select File" and empty-state "No items" (if applicable).
   - In **file mode**, verify the A-button hint reads "Select".
   - In **directory mode**, verify the A-button hint reads "Open" and the Select-button hint reads "Select Current".
   - Verify B-button hint reads "Back" and X-button hint reads "Toggle" (in multi-directory mode).

5. **Chinese locale verification**
   - Switch the app locale to Chinese (Simplified) in system settings or via the app language selector.
   - Repeat steps 1–4 and confirm all text appears in Chinese.

## Running the Application

- **Command**: `flutter run -d linux` (ensure `flutter` is on PATH: `export PATH="/home/simooo/flutter/bin:$PATH"`)
- The app starts on the Linux desktop. Navigate to the Add Game dialog via the top bar or home page empty state.

## Known Gaps

- None. All user-visible strings in the four target files are now localized. Dynamic messages originating from BLoC states (e.g., `SteamScannerLoading.message`, `ScanDirectoryForm.errorMessage`) were explicitly out of scope for this sprint, per the contract.
