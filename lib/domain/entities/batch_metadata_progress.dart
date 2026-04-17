import 'package:equatable/equatable.dart';

/// Progress information for batch metadata fetching.
class BatchMetadataProgress extends Equatable {
  /// Total number of games to process.
  final int total;

  /// Number of games successfully processed.
  final int completed;

  /// Number of games that failed.
  final int failed;

  /// Title of the current game being processed (null if complete).
  final String? currentGame;

  /// Whether the batch is complete.
  final bool isComplete;

  /// Error message if the batch failed entirely.
  final String? error;

  /// Progress percentage (0.0 to 1.0).
  double get progress => total > 0 ? (completed + failed) / total : 0.0;

  /// Number of remaining games to process.
  int get remaining => total - completed - failed;

  const BatchMetadataProgress({
    required this.total,
    required this.completed,
    required this.failed,
    this.currentGame,
    required this.isComplete,
    this.error,
  });

  @override
  List<Object?> get props => [
        total,
        completed,
        failed,
        currentGame,
        isComplete,
        error,
      ];
}
