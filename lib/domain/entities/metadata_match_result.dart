import 'package:equatable/equatable.dart';

/// Result of a metadata matching operation.
class MetadataMatchResult extends Equatable {
  /// The matched game's external ID (e.g., RAWG game ID).
  final String gameId;

  /// The matched game's name.
  final String gameName;

  /// Confidence score (0.0 to 1.0) of the match.
  final double confidence;

  /// Whether this match was made automatically (confidence >= threshold).
  final bool isAutoMatch;

  /// Alternative matches that were considered.
  final List<MetadataAlternative> alternatives;

  const MetadataMatchResult({
    required this.gameId,
    required this.gameName,
    required this.confidence,
    required this.isAutoMatch,
    this.alternatives = const [],
  });

  /// Creates a copy with the given fields replaced.
  MetadataMatchResult copyWith({
    String? gameId,
    String? gameName,
    double? confidence,
    bool? isAutoMatch,
    List<MetadataAlternative>? alternatives,
  }) {
    return MetadataMatchResult(
      gameId: gameId ?? this.gameId,
      gameName: gameName ?? this.gameName,
      confidence: confidence ?? this.confidence,
      isAutoMatch: isAutoMatch ?? this.isAutoMatch,
      alternatives: alternatives ?? this.alternatives,
    );
  }

  @override
  List<Object?> get props => [
        gameId,
        gameName,
        confidence,
        isAutoMatch,
        alternatives,
      ];
}

/// Alternative match option for manual selection.
class MetadataAlternative extends Equatable {
  /// The alternative game's external ID.
  final String gameId;

  /// The alternative game's name.
  final String gameName;

  /// Confidence score for this alternative.
  final double confidence;

  /// Cover image URL (if available).
  final String? coverImageUrl;

  /// Release year (if available).
  final String? releaseYear;

  const MetadataAlternative({
    required this.gameId,
    required this.gameName,
    required this.confidence,
    this.coverImageUrl,
    this.releaseYear,
  });

  @override
  List<Object?> get props => [
        gameId,
        gameName,
        confidence,
        coverImageUrl,
        releaseYear,
      ];
}
