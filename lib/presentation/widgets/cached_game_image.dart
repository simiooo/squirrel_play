import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:squirrel_play/core/theme/design_tokens.dart';

/// Cached game image widget using cached_network_image.
///
/// Displays game covers or hero images with:
/// - Local caching for offline viewing
/// - Shimmer placeholder while loading
/// - Error fallback to an alternative URL, then gradient
/// - Fade-in animation when loaded
class CachedGameImage extends StatefulWidget {
  /// The primary image URL to load.
  final String? imageUrl;

  /// Fallback URL tried when the primary URL fails.
  final String? fallbackImageUrl;

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
    this.fallbackImageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor,
    this.showOverlay = false,
  });

  @override
  State<CachedGameImage> createState() => _CachedGameImageState();
}

class _CachedGameImageState extends State<CachedGameImage> {
  bool _hasError = false;

  @override
  void didUpdateWidget(CachedGameImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state when the URL changes
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.fallbackImageUrl != widget.fallbackImageUrl) {
      _hasError = false;
    }
  }

  String? get _effectiveUrl {
    if (!_hasError) {
      return widget.imageUrl;
    }
    return widget.fallbackImageUrl;
  }

  @override
  Widget build(BuildContext context) {
    final url = _effectiveUrl;

    if (url == null || url.isEmpty) {
      return _buildPlaceholder();
    }

    return ClipRRect(
      borderRadius: widget.borderRadius ?? BorderRadius.zero,
      child: CachedNetworkImage(
        imageUrl: url,
        width: widget.width,
        height: widget.height,
        fit: widget.fit,
        fadeInDuration: const Duration(milliseconds: 300),
        fadeOutDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => _buildShimmerPlaceholder(),
        errorWidget: (context, url, error) {
          if (!_hasError && widget.fallbackImageUrl != null) {
            // Schedule retry with fallback URL
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                });
              }
            });
            return _buildShimmerPlaceholder();
          }
          return _buildPlaceholder();
        },
        imageBuilder: (context, imageProvider) {
          return Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: imageProvider,
                fit: widget.fit,
              ),
            ),
            child: widget.showOverlay ? _buildOverlay() : null,
          );
        },
      ),
    );
  }

  Widget _buildPlaceholder() {
    final baseColor = widget.placeholderColor ?? AppColors.surfaceElevated;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            baseColor,
            Color.lerp(baseColor, Colors.black, 0.3) ?? baseColor,
          ],
        ),
        borderRadius: widget.borderRadius,
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
        width: widget.width,
        height: widget.height,
        color: AppColors.surfaceElevated,
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
