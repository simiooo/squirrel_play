import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';

/// Loading state widget for the home page.
///
/// Shows shimmer/skeleton cards while fetching games.
/// Features:
/// - 3 skeleton rows with 4-5 cards each
/// - Pulsing animation on skeleton elements
/// - Gradient placeholder for background area
class LoadingHomeState extends StatelessWidget {
  /// Creates a LoadingHomeState widget.
  const LoadingHomeState({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Background placeholder area
        _buildBackgroundPlaceholder(),
        const SizedBox(height: AppSpacing.xl),

        // Skeleton rows
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl),
            itemCount: 3,
            itemBuilder: (context, rowIndex) {
              return _buildSkeletonRow(context, rowIndex);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBackgroundPlaceholder() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.surface.withAlpha(128),
            AppColors.background,
          ],
        ),
      ),
      child: Shimmer.fromColors(
        baseColor: AppColors.surface.withAlpha(77),
        highlightColor: AppColors.surfaceElevated.withAlpha(128),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface.withAlpha(128),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonRow(BuildContext context, int rowIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row header skeleton
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Shimmer.fromColors(
              baseColor: AppColors.surface.withAlpha(128),
              highlightColor: AppColors.surfaceElevated.withAlpha(179),
              child: Container(
                width: 150,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.small),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Card skeletons
          SizedBox(
            height: _getCardHeight(context),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              itemCount: 5,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(
                    right: index < 4 ? AppSpacing.lg : 0,
                  ),
                  child: _buildSkeletonCard(context),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    final size = CardDimensions.getSize(breakpoint);

    return Shimmer.fromColors(
      baseColor: AppColors.surface.withAlpha(128),
      highlightColor: AppColors.surfaceElevated.withAlpha(179),
      child: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadii.medium),
        ),
      ),
    );
  }

  double _getCardHeight(BuildContext context) {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    return CardDimensions.getHeight(breakpoint);
  }
}
