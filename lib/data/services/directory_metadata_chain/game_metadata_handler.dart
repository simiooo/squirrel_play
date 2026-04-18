import 'package:squirrel_play/data/services/directory_metadata_chain/directory_context.dart';

/// Abstract base class for the Chain of Responsibility pattern
/// for directory-level metadata parsing.
///
/// Handlers are linked together via [setNext]. Each handler can either
/// process the [DirectoryContext] or pass it to the next handler in the chain.
abstract class GameMetadataHandler {
  GameMetadataHandler? _nextHandler;

  /// Sets the next handler in the chain.
  void setNext(GameMetadataHandler handler) {
    _nextHandler = handler;
  }

  /// Handles the given [context].
  ///
  /// Subclasses should override this to process the context.
  /// If the handler cannot resolve the metadata, it should call
  /// `super.handle(context)` to pass to the next handler.
  Future<void> handle(DirectoryContext context) async {
    if (_nextHandler != null) {
      await _nextHandler!.handle(context);
    }
  }
}
