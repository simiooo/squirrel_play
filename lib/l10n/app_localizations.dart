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
