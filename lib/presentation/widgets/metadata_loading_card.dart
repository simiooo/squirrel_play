import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';
import 'package:squirrel_play/core/utils/breakpoints.dart';

/// Shimmer/skeleton loading card for metadata fetching.
///
/// Shows a pulsing placeholder while game metadata is being fetched.
/// Uses design token colors for shimmer base and highlight.
class MetadataLoadingCard extends StatelessWidget {
  /// Optional color for the placeholder base.
  final Color? baseColor;

  /// Optional color for the shimmer highlight.
  final Color? highlightColor;

  const MetadataLoadingCard({
    super.key,
    this.baseColor,
    this.highlightColor,
  });

  @override
  Widget build(BuildContext context) {
    final breakpoint = Breakpoints.getBreakpointFromContext(context);
    final cardSize = CardDimensions.getSize(breakpoint);

    final shimmerBase = baseColor ?? AppColors.surface;
    final shimmerHighlight = highlightColor ?? AppColors.surfaceElevated;

    return Container(
      width: cardSize.width,
      height: cardSize.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        color: shimmerBase,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadii.medium),
        child: Shimmer.fromColors(
          baseColor: shimmerBase,
          highlightColor: shimmerHighlight,
          period: const Duration(milliseconds: 1500),
          direction: ShimmerDirection.ltr,
          child: Container(
            decoration: BoxDecoration(
              color: shimmerHighlight,
              borderRadius: BorderRadius.circular(AppRadii.medium),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Title placeholder
                Container(
                  margin: const EdgeInsets.all(AppSpacing.md),
                  height: 20,
                  decoration: BoxDecoration(
                    color: shimmerHighlight,
                    borderRadius: BorderRadius.circular(AppRadii.small),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
