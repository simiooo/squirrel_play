import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/domain/entities/scan_directory.dart';
import 'package:squirrel_play/presentation/widgets/focusable_button.dart';

/// A section for managing saved scan directories.
///
/// Displays a list of saved directories with delete buttons.
/// Each item is gamepad-focusable.
class ManageDirectoriesSection extends StatelessWidget {
  /// Creates the manage directories section.
  const ManageDirectoriesSection({
    super.key,
    required this.directories,
    required this.onRemove,
  });

  /// List of saved directories.
  final List<ScanDirectory> directories;

  /// Callback when a directory is removed.
  final ValueChanged<String> onRemove;

  @override
  Widget build(BuildContext context) {
    if (directories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 48,
              color: AppColors.textMuted.withAlpha(128),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No directories added',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Add directories to scan for games',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Saved Directories (${directories.length})',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: ListView.builder(
            itemCount: directories.length,
            itemBuilder: (context, index) {
              final dir = directories[index];
              return _DirectoryListItem(
                directory: dir,
                onRemove: () => onRemove(dir.id),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DirectoryListItem extends StatefulWidget {
  const _DirectoryListItem({
    required this.directory,
    required this.onRemove,
  });

  final ScanDirectory directory;
  final VoidCallback onRemove;

  @override
  State<_DirectoryListItem> createState() => _DirectoryListItemState();
}

class _DirectoryListItemState extends State<_DirectoryListItem> {
  late final FocusNode _deleteFocusNode;

  @override
  void initState() {
    super.initState();
    _deleteFocusNode = FocusNode(debugLabel: 'DeleteDir_${widget.directory.id}');
  }

  @override
  void dispose() {
    _deleteFocusNode.dispose();
    super.dispose();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never scanned';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.small),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_outlined,
            size: 20,
            color: AppColors.textMuted,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.directory.path,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
                Text(
                  'Last scanned: ${_formatDate(widget.directory.lastScannedDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          FocusableButton(
            focusNode: _deleteFocusNode,
            label: 'Remove',
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
