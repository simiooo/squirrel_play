import 'package:squirrel_play/l10n/app_localizations.dart';

/// Localizes error messages using the provided [AppLocalizations].
///
/// This centralizes error message localization so that BLoCs can emit
/// localization keys instead of raw English strings.
String localizeError(
  AppLocalizations? l10n,
  String key, {
  String? details,
  String? gameName,
}) {
  switch (key) {
    // Steam Scanner import errors
    case 'steamScannerNoExecutable':
      return l10n?.steamScannerNoExecutable(gameName ?? '') ??
          '$gameName: No executable found';
    case 'steamScannerImportError':
      return l10n?.steamScannerImportError(gameName ?? '', details ?? '') ??
          '$gameName: $details';

    // Add Game
    case 'errorAddGameFailed':
      return l10n?.errorAddGameFailed(details ?? '') ??
          'Failed to add game: $details';
    case 'errorAddGamesFailed':
      return l10n?.errorAddGamesFailed(details ?? '') ??
          'Failed to add games: $details';

    // Quick Scan
    case 'errorScanFailed':
      return l10n?.errorScanFailed(details ?? '') ??
          'Scan failed: $details';

    // Game Library
    case 'errorDeleteFailed':
      final base = l10n?.errorDeleteFailed ?? 'Failed to delete game';
      return details != null ? '$base: $details' : base;
    case 'errorLoadGames':
      final base = l10n?.errorLoadGames ?? 'Failed to load games';
      return details != null ? '$base: $details' : base;

    // Home
    case 'errorLoadGamesFailed':
      final base = l10n?.errorLoadGames ?? 'Failed to load games';
      return details != null ? '$base: $details' : base;

    // Metadata
    case 'errorFetchMetadataFailed':
      return l10n?.errorFetchMetadataFailed(details ?? '') ??
          'Failed to fetch metadata: $details';
    case 'errorSearchFailed':
      return l10n?.errorSearchFailed(details ?? '') ??
          'Search failed: $details';
    case 'errorUpdateMetadataFailed':
      return l10n?.errorUpdateMetadataFailed(details ?? '') ??
          'Failed to update metadata: $details';
    case 'errorClearMetadataFailed':
      return l10n?.errorClearMetadataFailed(details ?? '') ??
          'Failed to clear metadata: $details';

    // Settings
    case 'errorLoadSettingsFailed':
      return l10n?.errorLoadSettingsFailed(details ?? '') ??
          'Failed to load settings: $details';

    default:
      return key;
  }
}
