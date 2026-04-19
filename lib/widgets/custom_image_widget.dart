import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';

extension ImageTypeExtension on String {
  ImageType get imageType {
    final v = trim();

    if (v.startsWith('http://') || v.startsWith('https://')) {
      return ImageType.network;
    } else if (v.toLowerCase().endsWith('.svg')) {
      return ImageType.svg;
    } else if (v.startsWith('file://') || v.startsWith('/')) {
      return ImageType.file;
    } else {
      return ImageType.png;
    }
  }
}

enum ImageType { svg, png, network, file, unknown }

class CustomImageWidget extends StatelessWidget {
  const CustomImageWidget({
    super.key,
    this.imageUrl,
    this.height,
    this.width,
    this.color,
    this.fit,
    this.alignment,
    this.onTap,
    this.radius,
    this.margin,
    this.border,
    this.placeHolder = 'assets/images/no-image.jpg',
    this.errorWidget,
    this.semanticLabel,
    // Optional explicit cache dimensions.
    // If not set, we derive a sensible default from width/height.
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String? imageUrl;
  final double? height;
  final double? width;
  final BoxFit? fit;
  final String placeHolder;
  final Color? color;
  final Alignment? alignment;
  final VoidCallback? onTap;
  final BorderRadius? radius;
  final EdgeInsetsGeometry? margin;
  final BoxBorder? border;
  final Widget? errorWidget;
  final String? semanticLabel;
  final int? memCacheWidth;
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    final child = _buildWidget(context);

    return alignment != null
        ? Align(alignment: alignment!, child: child)
        : child;
  }

  Widget _buildWidget(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: _buildClippedWithBorder(context),
      ),
    );
  }

  Widget _buildClippedWithBorder(BuildContext context) {
    Widget image = _buildImageWithBorder(context);

    if (radius != null) {
      image = ClipRRect(
        borderRadius: radius ?? BorderRadius.zero,
        child: image,
      );
    }

    return image;
  }

  Widget _buildImageWithBorder(BuildContext context) {
    final imageView = _buildImageView(context);

    if (border != null) {
      return Container(
        decoration: BoxDecoration(
          border: border,
          borderRadius: radius,
        ),
        child: imageView,
      );
    }

    return imageView;
  }

  Widget _buildImageView(BuildContext context) {
    final theme = Theme.of(context);
    final dpr = MediaQuery.of(context).devicePixelRatio;

    final placeholderColor = theme.colorScheme.surfaceContainerHighest;
    final placeholderTrackColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    if (imageUrl == null || imageUrl!.trim().isEmpty) {
      return Image.asset(
        placeHolder,
        height: height,
        width: width,
        fit: fit ?? BoxFit.cover,
        semanticLabel: semanticLabel,
      );
    }

    final url = imageUrl!.trim();

    switch (url.imageType) {
      case ImageType.svg:
        return SizedBox(
          height: height,
          width: width,
          child: SvgPicture.asset(
            url,
            height: height,
            width: width,
            fit: fit ?? BoxFit.contain,
            colorFilter: color != null
                ? ColorFilter.mode(color!, BlendMode.srcIn)
                : null,
            semanticsLabel: semanticLabel,
          ),
        );

      case ImageType.file:
        final filePath =
            url.startsWith('file://') ? Uri.parse(url).toFilePath() : url;
        return Image.file(
          File(filePath),
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          color: color,
          semanticLabel: semanticLabel,
        );

      case ImageType.network:
        // Derive cache dimensions from widget size * device pixel ratio.
        // This ensures images are decoded at display resolution, not full
        // resolution. For a 160px wide card on a 3x screen, we cache at
        // 480px — sharp but ~9x less memory than a 1440px source image.
        // Cap at 1200px to avoid decoding giant images on large screens.
        // Guard against infinite/NaN layout dimensions (e.g. when widget is
        // inside an unbounded Column or ListView without explicit size).
        // Multiplying double.infinity by dpr produces infinity, causing
        // "Unsupported operation: Infinity or NaN toInt" on .ceil().
        final safeWidth = (width != null && width!.isFinite) ? width! : null;
        final safeHeight = (height != null && height!.isFinite) ? height! : null;
        final cacheW = memCacheWidth ??
            (safeWidth != null ? (safeWidth * dpr).ceil().clamp(1, 1200) : 800);
        final cacheH = memCacheHeight ??
            (safeHeight != null ? (safeHeight * dpr).ceil().clamp(1, 1200) : null);

        return CachedNetworkImage(
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          imageUrl: url,
          color: color,
          memCacheWidth: cacheW,
          memCacheHeight: cacheH,
          maxWidthDiskCache: 1200,
          maxHeightDiskCache: 1200,
          placeholder: (context, _) => SizedBox(
            height: height,
            width: width,
            child: LinearProgressIndicator(
              color: placeholderColor,
              backgroundColor: placeholderTrackColor,
            ),
          ),
          errorWidget: (context, _, __) =>
              errorWidget ??
              Image.asset(
                placeHolder,
                height: height,
                width: width,
                fit: fit ?? BoxFit.cover,
                semanticLabel: semanticLabel,
              ),
        );

      case ImageType.png:
      default:
        return Image.asset(
          url,
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          color: color,
          semanticLabel: semanticLabel,
        );
    }
  }
}