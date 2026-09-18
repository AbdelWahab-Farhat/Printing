import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// The product's picture, or the glyph that stands in for one.
///
/// A product with no photograph and a photograph that will not load are the same thing to
/// somebody looking at it, so they are drawn the same way.
///
/// **Shared rather than copied**, because the basket draws the same square the catalogue does and
/// two of these would be two answers to "what does a product with no photo look like". It fills
/// whatever it is given — the caller decides the size and the corners, since a grid tile and a
/// basket line want different ones.
class ProductThumbnail extends StatelessWidget {
  const ProductThumbnail({required this.image, super.key});

  /// The photograph's URL, or null for a product that has none.
  final String? image;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(AppIcons.products, size: 30.sp, color: scheme.onSurfaceVariant),
      ),
    );

    final url = image;
    if (url == null) return placeholder;

    return CachedNetworkImage(
      imageUrl: url,
      fit: BoxFit.cover,
      placeholder: (context, _) => ColoredBox(color: scheme.surfaceContainerHigh),
      errorWidget: (context, _, _) => placeholder,
    );
  }
}
