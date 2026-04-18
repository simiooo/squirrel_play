import 'package:squirrel_play/core/utils/filename_cleaner.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/directory_context.dart';
import 'package:squirrel_play/data/services/directory_metadata_chain/game_metadata_handler.dart';

/// Terminal handler that generates a game title from the executable filename.
///
/// Uses [FilenameCleaner.cleanForDisplay] to produce a human-readable title.
/// This handler never delegates to the next handler — it always succeeds.
class DefaultMetadataHandler extends GameMetadataHandler {
  @override
  Future<void> handle(DirectoryContext context) async {
    context.title = FilenameCleaner.cleanForDisplay(context.fileName);
    // Terminal handler — do not call super.handle(context)
  }
}
