import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';

/// Cached game image widget using cached_network_image.
///
/// Displays game covers or hero images with:
/// - Local caching for offline viewing
/// - Shimmer placeholder while loading
/// - Error fallback to gradient
/// - Fade-in animation when loaded
class CachedGameImage extends StatelessWidget {
  /// The image URL to load.
  final String? imageUrl;

  /// Width of the image.
  final double? width;

  /// Height of the image.
  final double? height;

  /// How the image should fit.
  final BoxFit fit;

  /// Border radius for the image.
  final BorderRadius? borderRadius;

  /// Base color for the shimmer placeholder.
  final Color? placeholderColor;

  /// Whether to show a dark overlay for text readability.
  final bool showOverlay;

  const CachedGameImage({
    super.key,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor,
    this.showOverlay = false,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    if (url == null || url.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
        imageBuilder: (context, imageProvider) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: fit,
              ),
            ),
            child: showOverlay ? _buildOverlay() : null,
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    final baseColor = placeholderColor ?? AppColors.surfaceElevated;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.3) ?? baseColor,
          ],
        ),
        borderRadius: borderRadius,
      ),
      child: Center(
        child: Icon(
          Icons.videogame_asset_outlined,
          size: 48,
          color: AppColors.textMuted.withAlpha(128),
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceElevated,
      period: const Duration(milliseconds: 1500),
      child: Container(
        width: width,
        height: height,
        color: AppColors.surfaceElevated,
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: borderRadius,
      ),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.broken_image_outlined,
              size: 32,
              color: AppColors.textMuted,
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Image unavailable',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.background.withAlpha(204),
          ],
          stops: const [0.5, 1.0],
        ),
      ),
    );
  }
}
