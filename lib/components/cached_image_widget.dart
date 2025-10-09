import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

class CachedImageWidget extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool showShimmer;
  final Color? shimmerBaseColor;
  final Color? shimmerHighlightColor;

  const CachedImageWidget({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.showShimmer = true,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => _buildPlaceholder(),
      errorWidget: (context, url, error) => _buildErrorWidget(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 300),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;

    if (showShimmer) {
      return Shimmer.fromColors(
        baseColor: shimmerBaseColor ?? Colors.grey[300]!,
        highlightColor: shimmerHighlightColor ?? Colors.grey[100]!,
        child: Container(
          width: width,
          height: height,
          color: Colors.white,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    if (errorWidget != null) return errorWidget!;

    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.broken_image_outlined,
            size: (width != null && height != null) 
                ? (width! < height! ? width! * 0.3 : height! * 0.3)
                : 40,
            color: Colors.grey[400],
          ),
          if (width == null || width! > 100) ...[
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

/// Specialized widget for product images
class ProductImageWidget extends StatelessWidget {
  final String imageUrl;
  final double size;
  final VoidCallback? onTap;

  const ProductImageWidget({
    super.key,
    required this.imageUrl,
    this.size = 120,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CachedImageWidget(
          imageUrl: imageUrl,
          width: size,
          height: size,
          borderRadius: BorderRadius.circular(12),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Widget for banner images
class BannerImageWidget extends StatelessWidget {
  final String imageUrl;
  final double height;
  final VoidCallback? onTap;

  const BannerImageWidget({
    super.key,
    required this.imageUrl,
    this.height = 200,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CachedImageWidget(
          imageUrl: imageUrl,
          height: height,
          borderRadius: BorderRadius.circular(12),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Widget for category icons
class CategoryIconWidget extends StatelessWidget {
  final String imageUrl;
  final double size;
  final VoidCallback? onTap;

  const CategoryIconWidget({
    super.key,
    required this.imageUrl,
    this.size = 60,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: CachedImageWidget(
          imageUrl: imageUrl,
          width: size,
          height: size,
          borderRadius: BorderRadius.circular(size / 2),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

/// Widget for profile avatars
class ProfileAvatarWidget extends StatelessWidget {
  final String? imageUrl;
  final double size;
  final String? initials;
  final VoidCallback? onTap;

  const ProfileAvatarWidget({
    super.key,
    this.imageUrl,
    this.size = 50,
    this.initials,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[300]!, width: 2),
        ),
        child: ClipOval(
          child: imageUrl != null && imageUrl!.isNotEmpty
              ? CachedImageWidget(
                  imageUrl: imageUrl!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  showShimmer: false,
                  errorWidget: _buildDefaultAvatar(),
                )
              : _buildDefaultAvatar(),
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      width: size,
      height: size,
      color: Colors.grey[200],
      child: Center(
        child: initials != null && initials!.isNotEmpty
            ? Text(
                initials!.toUpperCase(),
                style: TextStyle(
                  fontSize: size * 0.4,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              )
            : Icon(
                Icons.person,
                size: size * 0.6,
                color: Colors.grey[400],
              ),
      ),
    );
  }
}
