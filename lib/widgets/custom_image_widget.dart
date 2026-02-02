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
      // Handle file URIs and absolute file paths
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

    // Theme-aware placeholder colors (fixes dark mode “mixed” look)
    final placeholderColor = theme.colorScheme.surfaceContainerHighest;
    final placeholderTrackColor =
        theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);

    // If no imageUrl, show placeholder consistently (avoid empty gaps)
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
        // Support both file:// URIs and raw paths
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
        return CachedNetworkImage(
          height: height,
          width: width,
          fit: fit ?? BoxFit.cover,
          imageUrl: url,
          color: color,
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
