import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/features/customers/models/customer_design.dart';

/// One design, as a picture of itself.
///
/// Used by the library's grid and by every picker that offers a design, so a file looks the
/// same wherever it is chosen from — and so the caching rule below is written once.
///
/// **Keyed by the design, never by the URL.** The API signs these per request, so the address
/// of one unchanging file is different on every load; cached under the URL, nothing would ever
/// be a cache hit and a grid would download itself again on every refresh. Safe precisely
/// because a design's bytes can never be replaced — there is no endpoint for it, by design.
///
/// Falls back to a glyph rather than a broken image when there is nothing to draw: a PDF today
/// (the backend renders no first page yet) and any design whose signed link did not come with
/// the row.
class DesignThumbnail extends StatelessWidget {
  const DesignThumbnail({required this.design, this.size, this.radius, super.key});

  final CustomerDesign design;

  /// A square of this side. Null fills whatever box the caller put it in — which is what the
  /// library's grid wants and what a row does not.
  final double? size;

  final double? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final url = design.thumbnailUrl;
    final corner = BorderRadius.circular(radius ?? 10.r);

    final child = url == null
        ? ColoredBox(
            color: scheme.surfaceContainerHigh,
            child: Center(
              child: Icon(
                design.kind == DesignKind.pdf ? AppIcons.pdf : AppIcons.document,
                size: (size == null ? 40 : size! * 0.5).sp,
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            cacheKey: 'customer-design-${design.id}',
            placeholder: (context, _) => ColoredBox(color: scheme.surfaceContainerHigh),
            errorWidget: (context, _, _) => ColoredBox(
              color: scheme.surfaceContainerHigh,
              child: Center(
                child: Icon(
                  AppIcons.offline,
                  size: (size == null ? 28 : size! * 0.45).sp,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          );

    final clipped = ClipRRect(borderRadius: corner, child: child);

    return size == null
        ? clipped
        : SizedBox(width: size!.w, height: size!.w, child: clipped);
  }
}
