import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/data/services/sound_service.dart';
import 'package:squirrel_play/domain/entities/metadata_match_result.dart';
import 'package:squirrel_play/presentation/widgets/cached_game_image.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// Dialog for manually searching and selecting game metadata.
///
/// Shows a search input and results list for when automatic matching fails.
class MetadataSearchDialog extends StatefulWidget {
  /// The game title to search for.
  final String gameTitle;

  /// Alternative matches from the initial search.
  final List<MetadataAlternative> initialAlternatives;

  /// Callback when a match is selected.
  final Function(String externalId) onSelect;

  /// Callback when search is performed.
  final Function(String query) onSearch;

  /// Current search results.
  final List<MetadataAlternative> searchResults;

  /// Whether a search is in progress.
  final bool isSearching;

  const MetadataSearchDialog({
    super.key,
    required this.gameTitle,
    required this.initialAlternatives,
    required this.onSelect,
    required this.onSearch,
    required this.searchResults,
    required this.isSearching,
  });

  @override
  State<MetadataSearchDialog> createState() => _MetadataSearchDialogState();
}

class _MetadataSearchDialogState extends State<MetadataSearchDialog> {
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _resultsFocusNodes = <FocusNode>[];
  final _selectButtonFocusNode = FocusNode();
  final _cancelButtonFocusNode = FocusNode();

  MetadataAlternative? _selectedAlternative;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.gameTitle;
    _createFocusNodes();

    // Auto-focus first element after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  @override
  void didUpdateWidget(MetadataSearchDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchResults.length != oldWidget.searchResults.length) {
      _createFocusNodes();
    }
  }

  void _createFocusNodes() {
    // Dispose old nodes
    for (final node in _resultsFocusNodes) {
      node.dispose();
    }
    _resultsFocusNodes.clear();

    // Create new nodes for results
    for (var i = 0; i < widget.searchResults.length; i++) {
      _resultsFocusNodes.add(FocusNode());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    for (final node in _resultsFocusNodes) {
      node.dispose();
    }
    _selectButtonFocusNode.dispose();
    _cancelButtonFocusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    SoundService.instance.playFocusSelect();
    widget.onSearch(_searchController.text);
  }

  void _selectAlternative(MetadataAlternative alternative) {
    SoundService.instance.playFocusSelect();
    setState(() {
      _selectedAlternative = alternative;
    });
  }

  void _confirmSelection() {
    if (_selectedAlternative != null) {
      SoundService.instance.playFocusSelect();
      widget.onSelect(_selectedAlternative!.gameId);
      Navigator.of(context).pop();
    }
  }

  void _cancel() {
    SoundService.instance.playFocusBack();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final results = widget.searchResults.isNotEmpty
        ? widget.searchResults
        : widget.initialAlternatives;

    return KeyboardListener(
      focusNode: FocusNode(debugLabel: 'MetadataSearchDialogKeyboardListener'),
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          switch (event.logicalKey) {
            case LogicalKeyboardKey.escape:
              _cancel();
              return;
          }
        }
      },
      child: Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.large),
          border: Border.all(
            color: AppColors.surfaceElevated,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Correct Game',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Search for "${widget.gameTitle}"',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            // Search input
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search for a game...',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.surfaceElevated,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadii.medium),
                    borderSide: const BorderSide(
                      color: AppColors.primaryAccent,
                      width: 2,
                    ),
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: widget.isSearching
                      ? Container(
                          width: 20,
                          height: 20,
                          margin: const EdgeInsets.all(12),
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primaryAccent,
                            ),
                          ),
                        )
                      : null,
                ),
                onSubmitted: (_) => _performSearch(),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Results list
            Flexible(
              child: results.isEmpty && !widget.isSearching
                  ? Center(
                      child: Text(
                        'No results found. Try a different search.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      itemCount: results.length,
                      itemBuilder: (context, index) {
                        final alternative = results[index];
                        final isSelected = _selectedAlternative?.gameId ==
                            alternative.gameId;

                        return _buildResultItem(
                          alternative: alternative,
                          isSelected: isSelected,
                          focusNode: _resultsFocusNodes[index],
                          onTap: () => _selectAlternative(alternative),
                        );
                      },
                    ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FocusableButton(
                    focusNode: _cancelButtonFocusNode,
                    onPressed: _cancel,
                    label: 'Cancel',
                  ),
                  const SizedBox(width: AppSpacing.md),
                  FocusableButton(
                    focusNode: _selectButtonFocusNode,
                    onPressed: _selectedAlternative != null
                        ? _confirmSelection
                        : () {},
                    label: 'Select',
                    isPrimary: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildResultItem({
    required MetadataAlternative alternative,
    required bool isSelected,
    required FocusNode focusNode,
    required VoidCallback onTap,
  }) {
    return FocusableActionDetector(
      focusNode: focusNode,
      onFocusChange: (hasFocus) {
        if (hasFocus) {
          SoundService.instance.playFocusMove();
        }
      },
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap();
            return null;
          },
        ),
      },
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryAccent.withAlpha(51)
                : focusNode.hasFocus
                    ? AppColors.surfaceElevated
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadii.medium),
            border: Border.all(
              color: isSelected
                  ? AppColors.primaryAccent
                  : focusNode.hasFocus
                      ? AppColors.primaryAccent.withAlpha(128)
                      : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadii.small),
                child: CachedGameImage(
                  imageUrl: alternative.coverImageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: AppSpacing.md),

              // Game info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alternative.gameName,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (alternative.releaseYear != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        alternative.releaseYear!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Match: ${(alternative.confidence * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Selection indicator
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: AppColors.primaryAccent,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}