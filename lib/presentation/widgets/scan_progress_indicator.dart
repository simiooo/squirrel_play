import 'package:flutter/material.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';

/// A progress indicator for directory scanning.
///
/// Displays:
/// - Progress bar
/// - Directories scanned count
/// - Files found count
/// - Current path being scanned
class ScanProgressIndicator extends StatelessWidget {
  /// Creates the scan progress indicator.
  const ScanProgressIndicator({
    super.key,
    required this.directoriesScanned,
    required this.filesFound,
    required this.currentPath,
  });

  /// Number of directories scanned so far.
  final int directoriesScanned;

  /// Number of executable files found so far.
  final int filesFound;

  /// Current directory being scanned.
  final String currentPath;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.small),
          child: const LinearProgressIndicator(
            value: null, // Indeterminate
            backgroundColor: AppColors.surface,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primaryAccent,
            ),
            minHeight: 8,
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Stats
        Row(
          children: [
            Expanded(
              child: _buildStat(
                context,
                icon: Icons.folder_outlined,
                label: 'Directories',
                value: directoriesScanned.toString(),
              ),
            ),
            Expanded(
              child: _buildStat(
                context,
                icon: Icons.file_present_outlined,
                label: 'Files Found',
                value: filesFound.toString(),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Current path
        Text(
          'Scanning:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.small),
          ),
          child: Text(
            currentPath.isEmpty ? 'Starting scan...' : currentPath,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontFamily: 'monospace',
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: AppColors.textMuted,
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
