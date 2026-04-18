// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Squirrel Play';

  @override
  String get topBarAddGame => 'Add Game';

  @override
  String get topBarGameLibrary => 'Game Library';

  @override
  String get topBarRescan => 'Rescan';

  @override
  String get topBarSettings => 'Settings';

  @override
  String get topBarHome => 'Home';

  @override
  String get pageHome => 'Home';

  @override
  String get pageLibrary => 'Library';

  @override
  String get pageSettings => 'Settings';

  @override
  String get homeEmptyState => 'No games yet. Add a game to get started.';

  @override
  String get libraryEmptyState => 'Your game library is empty.';

  @override
  String timeFormat(String hour, String minute) {
    return '$hour:$minute';
  }

  @override
  String get focusAddGameHint => 'Add a new game to your library';

  @override
  String get focusGameLibraryHint => 'View all games in your library';

  @override
  String get focusRescanHint => 'Rescan directories for new games';

  @override
  String get topBarRefresh => 'Refresh';

  @override
  String get topBarScanning => 'Scanning...';

  @override
  String topBarScanNewGames(int count) {
    return '$count new games found';
  }

  @override
  String get topBarScanNoNewGames => 'No new games found';

  @override
  String get topBarScanNoDirectories => 'No directories configured';

  @override
  String get topBarScanError => 'Scan error';

  @override
  String get topBarRefreshHint => 'Refresh game library';

  @override
  String get focusSettingsHint => 'Open application settings';

  @override
  String get focusHomeHint => 'Return to home page';

  @override
  String get dialogAddGameTitle => 'Add Game';

  @override
  String get dialogAddGameManualTab => 'Manual Add';

  @override
  String get dialogAddGameScanTab => 'Scan Directory';

  @override
  String get dialogAddGameSteamTab => 'Steam Games';

  @override
  String get dialogClose => 'Close';

  @override
  String get buttonBack => 'Back';

  @override
  String get buttonCancel => 'Cancel';

  @override
  String get buttonSave => 'Save';

  @override
  String get buttonRetry => 'Retry';

  @override
  String get buttonConfirm => 'Confirm';

  @override
  String get focusCardHint => 'Game card - press A to select';

  @override
  String get snackbarRescanPlaceholder => 'Rescan feature coming soon';

  @override
  String get dialogPlaceholderText =>
      'This feature will be available in a future update';

  @override
  String get emptyStateAddGame => 'Add your first game';

  @override
  String get emptyStateSubtitle => 'Add your first game to get started';

  @override
  String get buttonScanDirectory => 'Scan Directory';

  @override
  String get noDescriptionAvailable => 'No description available';

  @override
  String get errorLoadGames => 'Failed to load games';

  @override
  String get homeRowRecentlyAdded => 'Recently Added';

  @override
  String get homeRowAllGames => 'All Games';

  @override
  String get homeRowFavorites => 'Favorites';

  @override
  String get homeRowRecentlyPlayed => 'Recently Played';

  @override
  String get homeRowFeatured => 'Featured';

  @override
  String get viewAllGames => 'View All';

  @override
  String launchingGame(String gameName) {
    return 'Launching $gameName...';
  }

  @override
  String get launchCancelHint => 'Press B to cancel';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageChinese => 'Chinese (Simplified)';

  @override
  String get settingsApiKey => 'API Key';

  @override
  String get settingsApiKeyLabel => 'RAWG API Key';

  @override
  String get settingsApiKeyPlaceholder => 'Enter your RAWG API key';

  @override
  String get settingsApiKeyHelp => 'Get your free API key from rawg.io';

  @override
  String get settingsApiKeyDegraded => 'Degraded Mode';

  @override
  String get settingsApiKeyConnected => 'API Connected';

  @override
  String get settingsSound => 'Sound';

  @override
  String get settingsSoundVolume => 'Master Volume';

  @override
  String get settingsSoundMute => 'Mute';

  @override
  String get settingsSoundTest => 'Test Sound';

  @override
  String get settingsSoundVolumeHint =>
      'Volume slider - use left and right to adjust';

  @override
  String get settingsSoundMuteHint =>
      'Mute toggle - press to toggle mute on or off';

  @override
  String get settingsLanguageEnglishLabel => 'English language option';

  @override
  String get settingsLanguageChineseLabel => 'Chinese language option';

  @override
  String get settingsAbout => 'About';

  @override
  String settingsAboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get settingsAboutCredits => 'Powered by RAWG API';

  @override
  String get errorGenericTitle => 'Something Went Wrong';

  @override
  String get errorGenericMessage =>
      'An unexpected error occurred. Please try again.';

  @override
  String get errorDatabaseTitle => 'Database Error';

  @override
  String get errorDatabaseMessage =>
      'Failed to access the game database. Please restart the application.';

  @override
  String get errorApiTitle => 'Connection Error';

  @override
  String get errorApiMessage =>
      'Could not connect to game database. You can still play your games.';

  @override
  String get errorFileNotFoundTitle => 'Game Not Found';

  @override
  String get errorFileNotFoundMessage =>
      'The game executable could not be found. It may have been moved or deleted.';

  @override
  String get errorMissingExecutableTitle => 'Missing Executable';

  @override
  String get errorMissingExecutableMessage =>
      'The game executable is missing. Please browse for a new location.';

  @override
  String get emptyStateNoGamesTitle => 'No Games Yet';

  @override
  String get emptyStateNoGamesMessage => 'Add your first game to get started';

  @override
  String get emptyStateNoSearchResultsTitle => 'No Results';

  @override
  String get emptyStateNoSearchResultsMessage => 'Try a different search term';

  @override
  String get emptyStateApiUnreachableTitle => 'Can\'t Connect';

  @override
  String get emptyStateApiUnreachableMessage =>
      'Game info unavailable. You can still play your games.';

  @override
  String get favoritesAdded => 'Added to favorites';

  @override
  String get favoritesRemoved => 'Removed from favorites';

  @override
  String get favoritesEmptyState => 'No favorite games yet';

  @override
  String gameInfoPlayCount(int count) {
    return 'Played $count times';
  }

  @override
  String get gameInfoPlayCountNever => 'Never played';

  @override
  String gameInfoLastPlayed(String timeAgo) {
    return 'Last played: $timeAgo';
  }

  @override
  String get gameInfoLastPlayedNever => 'Never played';

  @override
  String get gameInfoFavoriteButton => 'Add to Favorites';

  @override
  String get gameInfoUnfavoriteButton => 'Remove from Favorites';

  @override
  String get gameInfoLaunchButton => 'Launch Game';

  @override
  String get gameInfoStopButton => 'Stop';

  @override
  String get gameInfoSettingsButton => 'Settings';

  @override
  String get gameInfoDeleteButton => 'Delete';

  @override
  String get dialogEditGameTitle => 'Edit Game';

  @override
  String get dialogEditGameTitleLabel => 'Title';

  @override
  String get dialogEditGameTitleHint => 'Enter game title';

  @override
  String get dialogEditGameExecutableLabel => 'Executable Path';

  @override
  String get dialogEditGameExecutableHint => 'Path to game executable';

  @override
  String get dialogEditGameBrowse => 'Browse';

  @override
  String get dialogEditGameArgumentsLabel => 'Launch Arguments';

  @override
  String get dialogEditGameArgumentsHint => 'e.g. -windowed --fullscreen';

  @override
  String get dialogDeleteGameTitle => 'Delete Game?';

  @override
  String dialogDeleteGameMessage(String gameName) {
    return 'Are you sure you want to remove \"$gameName\" from your library?';
  }

  @override
  String get dialogDeleteGameConfirm => 'Delete';

  @override
  String get gamepadAButton => 'A: Select';

  @override
  String get gamepadBButton => 'B: Back';

  @override
  String get gamepadXButton => 'X: Details';

  @override
  String get gamepadYButton => 'Y: Favorite';

  @override
  String get gamepadStartButton => 'Start: Menu';

  @override
  String get gamepadBackButton => 'Back: Home';

  @override
  String get gamepadNavSelect => 'Select';

  @override
  String get gamepadNavBack => 'Back';

  @override
  String get gamepadNavDetails => 'Details';

  @override
  String get gamepadNavFavorite => 'Favorite';

  @override
  String get gamepadNavMenu => 'Menu';

  @override
  String get gamepadNavHome => 'Home';

  @override
  String get gamepadNavConfirm => 'Confirm';

  @override
  String get gamepadNavCancel => 'Cancel';

  @override
  String get gamepadNavPlay => 'Play';

  @override
  String get gamepadNavToggle => 'Toggle';

  @override
  String get gamepadNavScreenshots => 'Screenshots';

  @override
  String get settingsGamepad => 'Gamepad';

  @override
  String get settingsGamepadConnected => 'Gamepad: Connected';

  @override
  String get settingsGamepadDisconnected => 'Gamepad: Not connected';

  @override
  String get settingsGamepadTest => 'Test Gamepad';

  @override
  String get gamepadTestTitle => 'Gamepad Test';

  @override
  String get gamepadTestConnected => 'Connected';

  @override
  String get gamepadTestDisconnected => 'No gamepad detected';

  @override
  String get gamepadTestConnectHelp => 'Connect a gamepad and press any button';

  @override
  String get gamepadTestInputLog => 'Input Log';

  @override
  String get gamepadTestNoGamepad => 'No gamepad detected';

  @override
  String get gamepadTestConnectInstructions =>
      'Connect a gamepad and press any button to start testing';

  @override
  String get timeAgoJustNow => 'just now';

  @override
  String timeAgoMinutes(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String timeAgoHours(int hours) {
    return '$hours hours ago';
  }

  @override
  String timeAgoDays(int days) {
    return '$days days ago';
  }

  @override
  String timeAgoWeeks(int weeks) {
    return '$weeks weeks ago';
  }

  @override
  String timeAgoMonths(int months) {
    return '$months months ago';
  }

  @override
  String timeAgoYears(int years) {
    return '$years years ago';
  }

  @override
  String get fileBrowserTitle => 'Select File';

  @override
  String get fileBrowserSelect => 'Select';

  @override
  String get fileBrowserCancel => 'Cancel';

  @override
  String get fileBrowserNoItems => 'No items';

  @override
  String get fileBrowserParentDirectory => 'Parent Directory';

  @override
  String fileBrowserSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get errorGameNotFound => 'Game not found';

  @override
  String get errorLoadFailed => 'Failed to load game';

  @override
  String get errorLaunchFailed => 'Failed to launch game';

  @override
  String get errorStopFailed => 'Failed to stop game';

  @override
  String get errorDeleteFailed => 'Failed to delete game';

  @override
  String get errorUpdateFailed => 'Failed to update game';
}
