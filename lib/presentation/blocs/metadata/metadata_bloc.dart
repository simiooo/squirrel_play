import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squirrel_play/data/repositories/metadata_repository_impl.dart';
import 'package:squirrel_play/domain/entities/batch_metadata_progress.dart';
import 'package:squirrel_play/domain/entities/game.dart';
import 'package:squirrel_play/domain/repositories/game_repository.dart';
import 'package:squirrel_play/domain/repositories/metadata_repository.dart';

import 'package:squirrel_play/presentation/blocs/metadata/metadata_event.dart';
import 'package:squirrel_play/presentation/blocs/metadata/metadata_state.dart';

/// BLoC for managing metadata fetching and matching.
///
/// Handles:
/// - Automatic metadata fetch on game add
/// - Batch metadata fetching with progress
/// - Manual search for correcting mismatches
/// - Retry logic for failed fetches
class MetadataBloc extends Bloc<MetadataEvent, MetadataState> {
  final MetadataRepository _metadataRepository;
  final GameRepository _gameRepository;

  /// Subscription to batch progress updates.
  StreamSubscription<BatchMetadataProgress>? _batchProgressSubscription;

  MetadataBloc({
    required MetadataRepository metadataRepository,
    required GameRepository gameRepository,
  })  : _metadataRepository = metadataRepository,
        _gameRepository = gameRepository,
        super(const MetadataInitial()) {
    on<FetchMetadata>(_onFetchMetadata);
    on<BatchFetchMetadata>(_onBatchFetchMetadata);
    on<ManualSearch>(_onManualSearch);
    on<SelectMatch>(_onSelectMatch);
    on<RetryFetch>(_onRetryFetch);
    on<ClearMetadata>(_onClearMetadata);
    on<RefetchMetadata>(_onRefetchMetadata);
  }

  Future<void> _onFetchMetadata(
    FetchMetadata event,
    Emitter<MetadataState> emit,
  ) async {
    emit(MetadataLoading(
      gameId: event.gameId,
      gameTitle: event.gameTitle,
    ));

    try {
      // Check if already cached
      final cached = await _metadataRepository.getMetadataForGame(event.gameId);
      if (cached != null) {
        emit(MetadataLoaded(metadata: cached));
        return;
      }

      // Fetch from API
      final metadata = await _metadataRepository.fetchAndCacheMetadata(
        event.gameId,
        event.executablePath?.split('\\').last ?? event.gameTitle,
      );

      emit(MetadataLoaded(metadata: metadata));
    } on MetadataMatchRequiredException catch (e) {
      emit(MetadataMatchRequired(
        gameId: event.gameId,
        gameTitle: event.gameTitle,
        alternatives: e.alternatives,
      ));
    } catch (e) {
      emit(MetadataError(
        gameId: event.gameId,
        message: 'Failed to fetch metadata: $e',
        isRetryable: true,
      ));
    }
  }

  Future<void> _onBatchFetchMetadata(
    BatchFetchMetadata event,
    Emitter<MetadataState> emit,
  ) async {
    // Cancel any existing subscription
    await _batchProgressSubscription?.cancel();

    // Get games
    final games = <Game>[];
    for (final gameId in event.gameIds) {
      final game = await _gameRepository.getGameById(gameId);
      if (game != null) {
        games.add(game);
      }
    }

    if (games.isEmpty) {
      emit(const MetadataBatchProgress(
        total: 0,
        completed: 0,
        failed: 0,
        isComplete: true,
      ));
      return;
    }

    // Start batch fetch first (this will trigger progress updates)
    final batchFuture = _metadataRepository.batchFetchMetadata(games);

    // Collect progress updates and emit them
    await emit.forEach<BatchMetadataProgress>(
      _metadataRepository.batchProgressStream,
      onData: (progress) => MetadataBatchProgress(
        total: progress.total,
        completed: progress.completed,
        failed: progress.failed,
        currentGame: progress.currentGame,
        isComplete: progress.isComplete,
      ),
    );

    // Wait for batch to complete
    await batchFuture;
  }

  Future<void> _onManualSearch(
    ManualSearch event,
    Emitter<MetadataState> emit,
  ) async {
    emit(const MetadataLoading());

    try {
      final results = await _metadataRepository.manualSearch(event.query);

      emit(MetadataSearchResults(
        query: event.query,
        results: results,
      ));
    } catch (e) {
      emit(MetadataError(
        gameId: '',
        message: 'Search failed: $e',
        isRetryable: true,
      ));
    }
  }

  Future<void> _onSelectMatch(
    SelectMatch event,
    Emitter<MetadataState> emit,
  ) async {
    emit(MetadataLoading(gameId: event.gameId));

    try {
      final metadata = await _metadataRepository.updateMetadata(
        event.gameId,
        event.externalId,
      );

      emit(MetadataLoaded(metadata: metadata));
    } catch (e) {
      emit(MetadataError(
        gameId: event.gameId,
        message: 'Failed to update metadata: $e',
        isRetryable: true,
      ));
    }
  }

  Future<void> _onRetryFetch(
    RetryFetch event,
    Emitter<MetadataState> emit,
  ) async {
    // Retry is the same as fetch
    add(FetchMetadata(
      gameId: event.gameId,
      gameTitle: event.gameTitle,
    ));
  }

  Future<void> _onClearMetadata(
    ClearMetadata event,
    Emitter<MetadataState> emit,
  ) async {
    try {
      await _metadataRepository.clearMetadata(event.gameId);
      emit(const MetadataInitial());
    } catch (e) {
      emit(MetadataError(
        gameId: event.gameId,
        message: 'Failed to clear metadata: $e',
        isRetryable: false,
      ));
    }
  }

  Future<void> _onRefetchMetadata(
    RefetchMetadata event,
    Emitter<MetadataState> emit,
  ) async {
    // Clear existing metadata first
    try {
      await _metadataRepository.clearMetadata(event.gameId);
    } catch (_) {
      // Ignore errors on clear
    }

    // Then fetch fresh
    add(FetchMetadata(
      gameId: event.gameId,
      gameTitle: event.gameTitle,
      executablePath: event.gameTitle,
    ));
  }

  @override
  Future<void> close() {
    _batchProgressSubscription?.cancel();
    return super.close();
  }
}
