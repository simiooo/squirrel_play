import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The application title displayed in window and top bar
  ///
  /// In en, this message translates to:
  /// **'Squirrel Play'**
  String get appTitle;

  /// Button label for adding a new game
  ///
  /// In en, this message translates to:
  /// **'Add Game'**
  String get topBarAddGame;

  /// Button label for navigating to game library page
  ///
  /// In en, this message translates to:
  /// **'Game Library'**
  String get topBarGameLibrary;

  /// Button label for rescanning directories
  ///
  /// In en, this message translates to:
  /// **'Rescan'**
  String get topBarRescan;

  /// Button label for opening settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get topBarSettings;

  /// Button label for navigating to home page
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get topBarHome;

  /// Title for the home page
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get pageHome;

  /// Title for the library page
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get pageLibrary;

  /// Title for the settings page
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get pageSettings;

  /// Message shown on home page when no games are added
  ///
  /// In en, this message translates to:
  /// **'No games yet. Add a game to get started.'**
  String get homeEmptyState;

  /// Message shown on library page when no games are added
  ///
  /// In en, this message translates to:
  /// **'Your game library is empty.'**
  String get libraryEmptyState;

  /// Format for displaying time in top bar
  ///
  /// In en, this message translates to:
  /// **'{hour}:{minute}'**
  String timeFormat(String hour, String minute);

  /// Accessibility hint for Add Game button
  ///
  /// In en, this message translates to:
  /// **'Add a new game to your library'**
  String get focusAddGameHint;

  /// Accessibility hint for Game Library button
  ///
  /// In en, this message translates to:
  /// **'View all games in your library'**
  String get focusGameLibraryHint;

  /// Accessibility hint for Rescan button
  ///
  /// In en, this message translates to:
  /// **'Rescan directories for new games'**
  String get focusRescanHint;

  /// Button label for refreshing game library
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get topBarRefresh;

  /// Message shown while scanning for games
  ///
  /// In en, this message translates to:
  /// **'Scanning...'**
  String get topBarScanning;

  /// Message shown when new games are found during scan
  ///
  /// In en, this message translates to:
  /// **'{count} new games found'**
  String topBarScanNewGames(int count);

  /// Message shown when no new games are found during scan
  ///
  /// In en, this message translates to:
  /// **'No new games found'**
  String get topBarScanNoNewGames;

  /// Message shown when no scan directories are configured
  ///
  /// In en, this message translates to:
  /// **'No directories configured'**
  String get topBarScanNoDirectories;

  /// Title for scan error message
  ///
  /// In en, this message translates to:
  /// **'Scan error'**
  String get topBarScanError;

  /// Accessibility hint for refresh button
  ///
  /// In en, this message translates to:
  /// **'Refresh game library'**
  String get topBarRefreshHint;

  /// Accessibility hint for Settings button
  ///
  /// In en, this message translates to:
  /// **'Open application settings'**
  String get focusSettingsHint;

  /// Accessibility hint for Home button
  ///
  /// In en, this message translates to:
  /// **'Return to home page'**
  String get focusHomeHint;

  /// Title for the Add Game dialog
  ///
  /// In en, this message translates to:
  /// **'Add Game'**
  String get dialogAddGameTitle;

  /// Tab label for manual game addition
  ///
  /// In en, this message translates to:
  /// **'Manual Add'**
  String get dialogAddGameManualTab;

  /// Tab label for directory scanning
  ///
  /// In en, this message translates to:
  /// **'Scan Directory'**
  String get dialogAddGameScanTab;

  /// Tab label for Steam games import
  ///
  /// In en, this message translates to:
  /// **'Steam Games'**
  String get dialogAddGameSteamTab;

  /// Button label to close a dialog
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get dialogClose;

  /// Button label for back navigation
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get buttonBack;

  /// Button label for cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get buttonCancel;

  /// Button label for save action
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get buttonSave;

  /// Button label for retry action
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get buttonRetry;

  /// Button label for confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get buttonConfirm;

  /// Accessibility hint for game cards
  ///
  /// In en, this message translates to:
  /// **'Game card - press A to select'**
  String get focusCardHint;

  /// Message shown when Rescan button is pressed
  ///
  /// In en, this message translates to:
  /// **'Rescan feature coming soon'**
  String get snackbarRescanPlaceholder;

  /// Placeholder text in unfinished dialog tabs
  ///
  /// In en, this message translates to:
  /// **'This feature will be available in a future update'**
  String get dialogPlaceholderText;

  /// Call-to-action button in empty state
  ///
  /// In en, this message translates to:
  /// **'Add your first game'**
  String get emptyStateAddGame;

  /// Subtitle message in empty home state
  ///
  /// In en, this message translates to:
  /// **'Add your first game to get started'**
  String get emptyStateSubtitle;

  /// Button label for scanning directory in empty state
  ///
  /// In en, this message translates to:
  /// **'Scan Directory'**
  String get buttonScanDirectory;

  /// Message shown when no description is available for a game
  ///
  /// In en, this message translates to:
  /// **'No description available'**
  String get noDescriptionAvailable;

  /// Error message when loading games fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load games'**
  String get errorLoadGames;

  /// Title for recently added games row on home page
  ///
  /// In en, this message translates to:
  /// **'Recently Added'**
  String get homeRowRecentlyAdded;

  /// Title for all games row on home page
  ///
  /// In en, this message translates to:
  /// **'All Games'**
  String get homeRowAllGames;

  /// Title for favorites row on home page
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get homeRowFavorites;

  /// Title for recently played games row on home page
  ///
  /// In en, this message translates to:
  /// **'Recently Played'**
  String get homeRowRecentlyPlayed;

  /// Title for featured games row on home page
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get homeRowFeatured;

  /// Button label to view all games in library
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAllGames;

  /// Message shown when launching a game
  ///
  /// In en, this message translates to:
  /// **'Launching {gameName}...'**
  String launchingGame(String gameName);

  /// Hint shown during game launch countdown
  ///
  /// In en, this message translates to:
  /// **'Press B to cancel'**
  String get launchCancelHint;

  /// Section title for language settings
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// Label for English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// Label for Chinese language option
  ///
  /// In en, this message translates to:
  /// **'Chinese (Simplified)'**
  String get settingsLanguageChinese;

  /// Section title for API key settings
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get settingsApiKey;

  /// Label for API key input field
  ///
  /// In en, this message translates to:
  /// **'RAWG API Key'**
  String get settingsApiKeyLabel;

  /// Placeholder text for API key input
  ///
  /// In en, this message translates to:
  /// **'Enter your RAWG API key'**
  String get settingsApiKeyPlaceholder;

  /// Help text for API key configuration
  ///
  /// In en, this message translates to:
  /// **'Get your free API key from rawg.io'**
  String get settingsApiKeyHelp;

  /// Label shown when API key is not configured
  ///
  /// In en, this message translates to:
  /// **'Degraded Mode'**
  String get settingsApiKeyDegraded;

  /// Label shown when API key is configured
  ///
  /// In en, this message translates to:
  /// **'API Connected'**
  String get settingsApiKeyConnected;

  /// Section title for sound settings
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingsSound;

  /// Label for volume slider
  ///
  /// In en, this message translates to:
  /// **'Master Volume'**
  String get settingsSoundVolume;

  /// Label for mute toggle
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get settingsSoundMute;

  /// Label for test sound button
  ///
  /// In en, this message translates to:
  /// **'Test Sound'**
  String get settingsSoundTest;

  /// Accessibility hint for volume slider
  ///
  /// In en, this message translates to:
  /// **'Volume slider - use left and right to adjust'**
  String get settingsSoundVolumeHint;

  /// Accessibility hint for mute switch
  ///
  /// In en, this message translates to:
  /// **'Mute toggle - press to toggle mute on or off'**
  String get settingsSoundMuteHint;

  /// Accessibility label for English language option
  ///
  /// In en, this message translates to:
  /// **'English language option'**
  String get settingsLanguageEnglishLabel;

  /// Accessibility label for Chinese language option
  ///
  /// In en, this message translates to:
  /// **'Chinese language option'**
  String get settingsLanguageChineseLabel;

  /// Section title for about section
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// Version information in about section
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String settingsAboutVersion(String version);

  /// Credits in about section
  ///
  /// In en, this message translates to:
  /// **'Powered by RAWG API'**
  String get settingsAboutCredits;

  /// Title for generic error
  ///
  /// In en, this message translates to:
  /// **'Something Went Wrong'**
  String get errorGenericTitle;

  /// Message for generic error
  ///
  /// In en, this message translates to:
  /// **'An unexpected error occurred. Please try again.'**
  String get errorGenericMessage;

  /// Title for database error
  ///
  /// In en, this message translates to:
  /// **'Database Error'**
  String get errorDatabaseTitle;

  /// Message for database error
  ///
  /// In en, this message translates to:
  /// **'Failed to access the game database. Please restart the application.'**
  String get errorDatabaseMessage;

  /// Title for API error
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get errorApiTitle;

  /// Message for API error
  ///
  /// In en, this message translates to:
  /// **'Could not connect to game database. You can still play your games.'**
  String get errorApiMessage;

  /// Title for file not found error
  ///
  /// In en, this message translates to:
  /// **'Game Not Found'**
  String get errorFileNotFoundTitle;

  /// Message for file not found error
  ///
  /// In en, this message translates to:
  /// **'The game executable could not be found. It may have been moved or deleted.'**
  String get errorFileNotFoundMessage;

  /// Title for missing executable error
  ///
  /// In en, this message translates to:
  /// **'Missing Executable'**
  String get errorMissingExecutableTitle;

  /// Message for missing executable error
  ///
  /// In en, this message translates to:
  /// **'The game executable is missing. Please browse for a new location.'**
  String get errorMissingExecutableMessage;

  /// Title for no games empty state
  ///
  /// In en, this message translates to:
  /// **'No Games Yet'**
  String get emptyStateNoGamesTitle;

  /// Message for no games empty state
  ///
  /// In en, this message translates to:
  /// **'Add your first game to get started'**
  String get emptyStateNoGamesMessage;

  /// Title for no search results empty state
  ///
  /// In en, this message translates to:
  /// **'No Results'**
  String get emptyStateNoSearchResultsTitle;

  /// Message for no search results empty state
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get emptyStateNoSearchResultsMessage;

  /// Title for API unreachable empty state
  ///
  /// In en, this message translates to:
  /// **'Can\'t Connect'**
  String get emptyStateApiUnreachableTitle;

  /// Message for API unreachable empty state
  ///
  /// In en, this message translates to:
  /// **'Game info unavailable. You can still play your games.'**
  String get emptyStateApiUnreachableMessage;

  /// Message shown when game is added to favorites
  ///
  /// In en, this message translates to:
  /// **'Added to favorites'**
  String get favoritesAdded;

  /// Message shown when game is removed from favorites
  ///
  /// In en, this message translates to:
  /// **'Removed from favorites'**
  String get favoritesRemoved;

  /// Message shown when no favorites exist
  ///
  /// In en, this message translates to:
  /// **'No favorite games yet'**
  String get favoritesEmptyState;

  /// Display of play count in game info
  ///
  /// In en, this message translates to:
  /// **'Played {count} times'**
  String gameInfoPlayCount(int count);

  /// Display when game has never been played
  ///
  /// In en, this message translates to:
  /// **'Never played'**
  String get gameInfoPlayCountNever;

  /// Display of last played time in game info
  ///
  /// In en, this message translates to:
  /// **'Last played: {timeAgo}'**
  String gameInfoLastPlayed(String timeAgo);

  /// Display when game has never been played
  ///
  /// In en, this message translates to:
  /// **'Never played'**
  String get gameInfoLastPlayedNever;

  /// Button label to add game to favorites
  ///
  /// In en, this message translates to:
  /// **'Add to Favorites'**
  String get gameInfoFavoriteButton;

  /// Button label to remove game from favorites
  ///
  /// In en, this message translates to:
  /// **'Remove from Favorites'**
  String get gameInfoUnfavoriteButton;

  /// Button label to launch game
  ///
  /// In en, this message translates to:
  /// **'Launch Game'**
  String get gameInfoLaunchButton;

  /// Button label to stop a running game
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get gameInfoStopButton;

  /// Button label to open game settings/edit dialog
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get gameInfoSettingsButton;

  /// Button label to delete a game from the library
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get gameInfoDeleteButton;

  /// Title for the Edit Game dialog
  ///
  /// In en, this message translates to:
  /// **'Edit Game'**
  String get dialogEditGameTitle;

  /// Label for the game title input field
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get dialogEditGameTitleLabel;

  /// Hint text for the game title input field
  ///
  /// In en, this message translates to:
  /// **'Enter game title'**
  String get dialogEditGameTitleHint;

  /// Label for the executable path input field
  ///
  /// In en, this message translates to:
  /// **'Executable Path'**
  String get dialogEditGameExecutableLabel;

  /// Hint text for the executable path input field
  ///
  /// In en, this message translates to:
  /// **'Path to game executable'**
  String get dialogEditGameExecutableHint;

  /// Button label to browse for executable file
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get dialogEditGameBrowse;

  /// Label for the launch arguments input field
  ///
  /// In en, this message translates to:
  /// **'Launch Arguments'**
  String get dialogEditGameArgumentsLabel;

  /// Hint text for the launch arguments input field
  ///
  /// In en, this message translates to:
  /// **'e.g. -windowed --fullscreen'**
  String get dialogEditGameArgumentsHint;

  /// Title for the Delete Game confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete Game?'**
  String get dialogDeleteGameTitle;

  /// Confirmation message for deleting a game
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove \"{gameName}\" from your library?'**
  String dialogDeleteGameMessage(String gameName);

  /// Button label to confirm deletion of a game
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get dialogDeleteGameConfirm;

  /// Gamepad hint for A button
  ///
  /// In en, this message translates to:
  /// **'A: Select'**
  String get gamepadAButton;

  /// Gamepad hint for B button
  ///
  /// In en, this message translates to:
  /// **'B: Back'**
  String get gamepadBButton;

  /// Gamepad hint for X button
  ///
  /// In en, this message translates to:
  /// **'X: Details'**
  String get gamepadXButton;

  /// Gamepad hint for Y button
  ///
  /// In en, this message translates to:
  /// **'Y: Favorite'**
  String get gamepadYButton;

  /// Gamepad hint for Start button
  ///
  /// In en, this message translates to:
  /// **'Start: Menu'**
  String get gamepadStartButton;

  /// Gamepad hint for Back button
  ///
  /// In en, this message translates to:
  /// **'Back: Home'**
  String get gamepadBackButton;

  /// Gamepad nav bar hint for select action
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get gamepadNavSelect;

  /// Gamepad nav bar hint for back action
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get gamepadNavBack;

  /// Gamepad nav bar hint for details action
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get gamepadNavDetails;

  /// Gamepad nav bar hint for favorite action
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get gamepadNavFavorite;

  /// Gamepad nav bar hint for menu action
  ///
  /// In en, this message translates to:
  /// **'Menu'**
  String get gamepadNavMenu;

  /// Gamepad nav bar hint for home action
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get gamepadNavHome;

  /// Gamepad nav bar hint for confirm action
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get gamepadNavConfirm;

  /// Gamepad nav bar hint for cancel action
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gamepadNavCancel;

  /// Gamepad nav bar hint for play action
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get gamepadNavPlay;

  /// Gamepad nav bar hint for toggle action
  ///
  /// In en, this message translates to:
  /// **'Toggle'**
  String get gamepadNavToggle;

  /// Gamepad nav bar hint for screenshots action
  ///
  /// In en, this message translates to:
  /// **'Screenshots'**
  String get gamepadNavScreenshots;

  /// Section title for gamepad settings
  ///
  /// In en, this message translates to:
  /// **'Gamepad'**
  String get settingsGamepad;

  /// Label shown when gamepad is connected
  ///
  /// In en, this message translates to:
  /// **'Gamepad: Connected'**
  String get settingsGamepadConnected;

  /// Label shown when gamepad is not connected
  ///
  /// In en, this message translates to:
  /// **'Gamepad: Not connected'**
  String get settingsGamepadDisconnected;

  /// Button label for gamepad test
  ///
  /// In en, this message translates to:
  /// **'Test Gamepad'**
  String get settingsGamepadTest;

  /// Title for the gamepad test page
  ///
  /// In en, this message translates to:
  /// **'Gamepad Test'**
  String get gamepadTestTitle;

  /// Status shown when gamepad is connected
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get gamepadTestConnected;

  /// Status shown when no gamepad is connected
  ///
  /// In en, this message translates to:
  /// **'No gamepad detected'**
  String get gamepadTestDisconnected;

  /// Help text for connecting a gamepad
  ///
  /// In en, this message translates to:
  /// **'Connect a gamepad and press any button'**
  String get gamepadTestConnectHelp;

  /// Title for the input log section
  ///
  /// In en, this message translates to:
  /// **'Input Log'**
  String get gamepadTestInputLog;

  /// Message shown when no gamepad is detected
  ///
  /// In en, this message translates to:
  /// **'No gamepad detected'**
  String get gamepadTestNoGamepad;

  /// Instructions for connecting a gamepad
  ///
  /// In en, this message translates to:
  /// **'Connect a gamepad and press any button to start testing'**
  String get gamepadTestConnectInstructions;

  /// Time ago format for very recent
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeAgoJustNow;

  /// Time ago format for minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String timeAgoMinutes(int minutes);

  /// Time ago format for hours
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String timeAgoHours(int hours);

  /// Time ago format for days
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String timeAgoDays(int days);

  /// Time ago format for weeks
  ///
  /// In en, this message translates to:
  /// **'{weeks} weeks ago'**
  String timeAgoWeeks(int weeks);

  /// Time ago format for months
  ///
  /// In en, this message translates to:
  /// **'{months} months ago'**
  String timeAgoMonths(int months);

  /// Time ago format for years
  ///
  /// In en, this message translates to:
  /// **'{years} years ago'**
  String timeAgoYears(int years);

  /// Title for the file browser dialog
  ///
  /// In en, this message translates to:
  /// **'Select File'**
  String get fileBrowserTitle;

  /// Button label to confirm file selection
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get fileBrowserSelect;

  /// Button label to cancel file selection
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get fileBrowserCancel;

  /// Message shown when directory is empty
  ///
  /// In en, this message translates to:
  /// **'No items'**
  String get fileBrowserNoItems;

  /// Label for navigating to parent directory
  ///
  /// In en, this message translates to:
  /// **'Parent Directory'**
  String get fileBrowserParentDirectory;

  /// Message showing number of selected items
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String fileBrowserSelectedCount(int count);

  /// Error message when game is not found
  ///
  /// In en, this message translates to:
  /// **'Game not found'**
  String get errorGameNotFound;

  /// Error message when loading game fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load game'**
  String get errorLoadFailed;

  /// Error message when launching game fails
  ///
  /// In en, this message translates to:
  /// **'Failed to launch game'**
  String get errorLaunchFailed;

  /// Error message when stopping game fails
  ///
  /// In en, this message translates to:
  /// **'Failed to stop game'**
  String get errorStopFailed;

  /// Error message when deleting game fails
  ///
  /// In en, this message translates to:
  /// **'Failed to delete game'**
  String get errorDeleteFailed;

  /// Error message when updating game fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update game'**
  String get errorUpdateFailed;

  /// Label for the executable file picker in manual add tab
  ///
  /// In en, this message translates to:
  /// **'Executable File'**
  String get manualAddExecutableLabel;

  /// Button label to browse for executable file
  ///
  /// In en, this message translates to:
  /// **'Browse...'**
  String get manualAddBrowseButton;

  /// Placeholder text when no file is selected
  ///
  /// In en, this message translates to:
  /// **'No file selected'**
  String get manualAddNoFileSelected;

  /// Error message for invalid executable file
  ///
  /// In en, this message translates to:
  /// **'Invalid file'**
  String get manualAddInvalidFileError;

  /// Label for the game name input field
  ///
  /// In en, this message translates to:
  /// **'Game Name'**
  String get manualAddGameNameLabel;

  /// Hint text for the game name input field
  ///
  /// In en, this message translates to:
  /// **'Enter game name'**
  String get manualAddGameNameHint;

  /// Error message for invalid game name
  ///
  /// In en, this message translates to:
  /// **'Invalid name'**
  String get manualAddInvalidNameError;

  /// Button label to confirm adding a game manually
  ///
  /// In en, this message translates to:
  /// **'Add Game'**
  String get manualAddConfirmButton;

  /// Button label to add a directory for scanning
  ///
  /// In en, this message translates to:
  /// **'Add Directory'**
  String get scanDirectoryAddDirectoryButton;

  /// Button label to start scanning directories
  ///
  /// In en, this message translates to:
  /// **'Start Scan'**
  String get scanDirectoryStartScanButton;

  /// Status text showing found and selected executable counts
  ///
  /// In en, this message translates to:
  /// **'Found {totalCount} executables ({selectedCount} selected)'**
  String scanDirectoryFoundExecutables(int totalCount, int selectedCount);

  /// Button label to select all discovered executables
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get scanDirectorySelectAllButton;

  /// Button label to deselect all discovered executables
  ///
  /// In en, this message translates to:
  /// **'Select None'**
  String get scanDirectorySelectNoneButton;

  /// Button label to add selected games
  ///
  /// In en, this message translates to:
  /// **'Add {count} Games'**
  String scanDirectoryAddGamesButton(int count);

  /// Title shown when no executables are found during scan
  ///
  /// In en, this message translates to:
  /// **'No executables found'**
  String get scanDirectoryNoExecutablesTitle;

  /// Subtitle suggesting actions when no executables are found
  ///
  /// In en, this message translates to:
  /// **'Try selecting a different directory or check that .exe files exist.'**
  String get scanDirectoryNoExecutablesSubtitle;

  /// Button label to choose different directories after empty scan
  ///
  /// In en, this message translates to:
  /// **'Select Different Directories'**
  String get scanDirectorySelectDifferentDirectories;

  /// Message shown while adding discovered games
  ///
  /// In en, this message translates to:
  /// **'Adding games...'**
  String get scanDirectoryAddingGames;

  /// Message shown while initializing Steam scanner
  ///
  /// In en, this message translates to:
  /// **'Initializing...'**
  String get steamGamesInitializing;

  /// Label showing the default Steam installation path
  ///
  /// In en, this message translates to:
  /// **'Default: {path}'**
  String steamGamesDefaultPath(String path);

  /// Button label to browse for Steam installation folder
  ///
  /// In en, this message translates to:
  /// **'Browse for Steam Folder'**
  String get steamGamesBrowseSteamFolder;

  /// Label for the current Steam path display
  ///
  /// In en, this message translates to:
  /// **'Steam Path:'**
  String get steamGamesSteamPathLabel;

  /// Button label to select all available Steam games
  ///
  /// In en, this message translates to:
  /// **'Select All'**
  String get steamGamesSelectAllButton;

  /// Button label to deselect all Steam games
  ///
  /// In en, this message translates to:
  /// **'Select None'**
  String get steamGamesSelectNoneButton;

  /// Status text showing found Steam games and already added count
  ///
  /// In en, this message translates to:
  /// **'Found {count} games ({alreadyAddedCount} already added)'**
  String steamGamesFoundGames(int count, int alreadyAddedCount);

  /// Message shown when no Steam games are detected
  ///
  /// In en, this message translates to:
  /// **'No Steam games found'**
  String get steamGamesNoGamesFound;

  /// Label showing the Steam application ID
  ///
  /// In en, this message translates to:
  /// **'App ID: {appId}'**
  String steamGamesAppId(String appId);

  /// Badge label shown for games already in the library
  ///
  /// In en, this message translates to:
  /// **'Already Added'**
  String get steamGamesAlreadyAdded;

  /// Message shown while importing Steam games
  ///
  /// In en, this message translates to:
  /// **'Importing games...'**
  String get steamGamesImporting;

  /// Progress text showing completed and total imports
  ///
  /// In en, this message translates to:
  /// **'{completed} of {total}'**
  String steamGamesImportProgress(int completed, int total);

  /// Title shown when Steam game import is complete
  ///
  /// In en, this message translates to:
  /// **'Import Complete!'**
  String get steamGamesImportComplete;

  /// Message showing number of successfully imported games
  ///
  /// In en, this message translates to:
  /// **'{count} games imported'**
  String steamGamesImportedCount(int count);

  /// Message showing number of skipped games during import
  ///
  /// In en, this message translates to:
  /// **'{count} skipped'**
  String steamGamesSkippedCount(int count);

  /// Label for the errors section in import complete state
  ///
  /// In en, this message translates to:
  /// **'Errors:'**
  String get steamGamesErrorsLabel;

  /// Button label to import selected Steam games when none selected
  ///
  /// In en, this message translates to:
  /// **'Import Selected Games'**
  String get steamGamesImportButton;

  /// Button label to import selected Steam games with count
  ///
  /// In en, this message translates to:
  /// **'Import {count} Games'**
  String steamGamesImportCountButton(int count);

  /// Gamepad nav bar hint for open action
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get gamepadNavOpen;

  /// Gamepad nav bar hint for select current directory action
  ///
  /// In en, this message translates to:
  /// **'Select Current'**
  String get gamepadNavSelectCurrent;

  /// Message shown while detecting Steam installation
  ///
  /// In en, this message translates to:
  /// **'Detecting Steam installation...'**
  String get steamScannerDetecting;

  /// Error when Steam cannot be auto-detected
  ///
  /// In en, this message translates to:
  /// **'Steam installation not found. Please specify the path manually.'**
  String get steamScannerNotFound;

  /// Error when Steam detection throws an exception
  ///
  /// In en, this message translates to:
  /// **'Error detecting Steam: {error}'**
  String steamScannerDetectError(String error);

  /// Message shown while validating a manually-set Steam path
  ///
  /// In en, this message translates to:
  /// **'Validating Steam path...'**
  String get steamScannerValidating;

  /// Error when user-provided Steam path is invalid
  ///
  /// In en, this message translates to:
  /// **'Invalid Steam path. Please check the path and try again.'**
  String get steamScannerInvalidPath;

  /// Error when path validation throws an exception
  ///
  /// In en, this message translates to:
  /// **'Error validating path: {error}'**
  String steamScannerValidateError(String error);

  /// Error when scan is requested before setting a path
  ///
  /// In en, this message translates to:
  /// **'No Steam path set. Please detect or specify Steam path first.'**
  String get steamScannerNoPathSet;

  /// Message shown while scanning Steam libraries
  ///
  /// In en, this message translates to:
  /// **'Scanning Steam libraries...'**
  String get steamScannerScanning;

  /// Error when library scan throws an exception
  ///
  /// In en, this message translates to:
  /// **'Error scanning library: {error}'**
  String steamScannerScanError(String error);

  /// Error detail for a game with no executable
  ///
  /// In en, this message translates to:
  /// **'{gameName}: No executable found'**
  String steamScannerNoExecutable(String gameName);

  /// Error detail when importing a specific game fails
  ///
  /// In en, this message translates to:
  /// **'{gameName}: {error}'**
  String steamScannerImportError(String gameName, String error);

  /// Error when manual game addition fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add game: {error}'**
  String errorAddGameFailed(String error);

  /// Error when batch-adding scanned games fails
  ///
  /// In en, this message translates to:
  /// **'Failed to add games: {error}'**
  String errorAddGamesFailed(String error);

  /// Error when the background quick scan fails
  ///
  /// In en, this message translates to:
  /// **'Scan failed: {error}'**
  String errorScanFailed(String error);

  /// Error when loading settings fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load settings: {error}'**
  String errorLoadSettingsFailed(String error);

  /// Error when fetching game metadata fails
  ///
  /// In en, this message translates to:
  /// **'Failed to fetch metadata: {error}'**
  String errorFetchMetadataFailed(String error);

  /// Error when manual metadata search fails
  ///
  /// In en, this message translates to:
  /// **'Search failed: {error}'**
  String errorSearchFailed(String error);

  /// Error when selecting a metadata match fails
  ///
  /// In en, this message translates to:
  /// **'Failed to update metadata: {error}'**
  String errorUpdateMetadataFailed(String error);

  /// Error when clearing metadata fails
  ///
  /// In en, this message translates to:
  /// **'Failed to clear metadata: {error}'**
  String errorClearMetadataFailed(String error);

  /// Input log type label for button events
  ///
  /// In en, this message translates to:
  /// **'BUTTON'**
  String get gamepadTestButton;

  /// Input log type label for axis events
  ///
  /// In en, this message translates to:
  /// **'AXIS'**
  String get gamepadTestAxis;

  /// Input log type label for gamepad connection events
  ///
  /// In en, this message translates to:
  /// **'CONNECT'**
  String get gamepadTestConnect;

  /// Input log type label for gamepad disconnection events
  ///
  /// In en, this message translates to:
  /// **'DISCONNECT'**
  String get gamepadTestDisconnect;

  /// Label for a button press action in input log
  ///
  /// In en, this message translates to:
  /// **'pressed'**
  String get gamepadTestPressed;

  /// Label for a button release action in input log
  ///
  /// In en, this message translates to:
  /// **'released'**
  String get gamepadTestReleased;

  /// Log message when a gamepad is connected
  ///
  /// In en, this message translates to:
  /// **'Gamepad connected: {name}'**
  String gamepadTestGamepadConnected(String name);

  /// Fallback label for unknown gamepad name
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get gamepadTestUnknown;

  /// Log message when a gamepad is disconnected
  ///
  /// In en, this message translates to:
  /// **'Gamepad disconnected'**
  String get gamepadTestGamepadDisconnected;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
