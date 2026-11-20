import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/core/print_colors/print_colors_view.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/image_viewer.dart';
import 'package:dayaa/features/customers/models/customer_design.dart';
import 'package:dayaa/features/design_tickets/models/design_ticket_file.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// One file on a ticket, drawn as a picture of itself.
///
/// **Keyed by the file, never by the URL.** The API signs these per request, so the address of
/// one unchanging file differs on every load; cached under the URL nothing would ever be a cache
/// hit and the timeline would download itself again on every refresh. Safe precisely because a
/// version's bytes can never be replaced — there is no endpoint for it, by design.
///
/// Falls back to a glyph rather than a broken image when there is nothing to draw: a PDF today
/// (the backend renders no first page yet), and any file whose signed link did not arrive.
class DesignTicketFileThumbnail extends StatelessWidget {
  const DesignTicketFileThumbnail({required this.file, this.size, this.radius, super.key});

  final DesignTicketFile file;

  /// A square of this side. Null fills whatever box the caller put it in.
  final double? size;

  final double? radius;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final url = file.thumbnailUrl;
    final corner = BorderRadius.circular(radius ?? 10.r);

    final child = url == null
        ? ColoredBox(
            color: scheme.surfaceContainerHigh,
            child: Center(
              child: Icon(
                file.fileKind == DesignKind.pdf ? AppIcons.pdf : AppIcons.document,
                size: (size == null ? 40 : size! * 0.5).sp,
                color: scheme.onSurfaceVariant,
              ),
            ),
          )
        : CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            cacheKey: 'design-ticket-file-${file.id}',
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

    return size == null ? clipped : SizedBox(width: size!.w, height: size!.w, child: clipped);
  }
}

/// The cache key of one image of a version. Face 1 keeps the key the version always had, so a
/// thumbnail cached before versions had several images is still a hit.
String designVersionFaceCacheKey(DesignTicketFile version, int position) => position == 1
    ? 'design-ticket-file-${version.id}'
    : 'design-ticket-file-${version.id}-face-$position';

/// A version's images as a row of small squares (DESIGN-VERSION-IMAGES.md).
///
/// Under the tile's header it shows the images after the first, which the header already draws;
/// in the review sheet it shows all of them, each opening the viewer on itself. Nothing at all
/// when there is nothing to add.
class DesignVersionFacesStrip extends StatelessWidget {
  const DesignVersionFacesStrip({required this.version, this.includeFirst = false, super.key});

  final DesignTicketFile version;

  /// Whether face 1 is in the row too — false where something above already draws it.
  final bool includeFirst;

  void _open(BuildContext context, int position) {
    final faces = [for (final face in version.images) if (face.fileUrl != null) face];

    unawaited(
      openImageViewer(
        context,
        urls: [for (final face in faces) face.fileUrl!],
        initialIndex: faces.indexWhere((face) => face.position == position),
        cacheKeys: [for (final face in faces) designVersionFaceCacheKey(version, face.position)],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shown = version.images.skip(includeFirst ? 0 : 1).toList();

    if (shown.isEmpty || (includeFirst && shown.length < 2)) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 10.h),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          for (final face in shown)
            InkWell(
              onTap: face.fileUrl == null ? null : () => _open(context, face.position),
              borderRadius: BorderRadius.circular(8.r),
              child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: SizedBox(
                width: 44.w,
                height: 44.w,
                child: face.fileUrl == null
                    ? ColoredBox(color: scheme.surfaceContainerHigh)
                    : CachedNetworkImage(
                        imageUrl: face.fileUrl!,
                        fit: BoxFit.cover,
                        cacheKey: designVersionFaceCacheKey(version, face.position),
                        placeholder: (context, _) =>
                            ColoredBox(color: scheme.surfaceContainerHigh),
                        errorWidget: (context, _, _) => ColoredBox(
                          color: scheme.surfaceContainerHigh,
                          child: Icon(
                            AppIcons.offline,
                            size: 18.sp,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
              ),
            ),
            ),
        ],
      ),
    );
  }
}

/// One version in the timeline: the picture, its number, and the verdict it got.
///
/// **The review note is the load-bearing part.** A version turned back without the words is a
/// count rather than a conversation, which is why the server refuses one — and why this tile
/// gives the note its own block rather than a line that can be truncated away.
class DesignVersionTile extends StatelessWidget {
  const DesignVersionTile({required this.version, required this.onTap, super.key});

  final DesignTicketFile version;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    return Card(
      margin: EdgeInsets.only(bottom: 10.h),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DesignTicketFileThumbnail(file: version, size: 56),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          version.label,
                          style: text.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (version.uploader != null) ...[
                          SizedBox(height: 2.h),
                          Text(
                            version.uploader!.name,
                            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        ],
                        if (version.note != null && version.note!.isNotEmpty) ...[
                          SizedBox(height: 6.h),
                          Text(version.note!, style: text.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  if (version.statusLabel != null)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: version.isApproved
                            ? scheme.primaryContainer
                            : version.needsChanges
                            ? scheme.errorContainer
                            : scheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        version.statusLabel!,
                        style: text.labelSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                ],
              ),
              // The version's other images — the back of the bag, the close-up.
              DesignVersionFacesStrip(version: version),
              // The inks the designer says this version was drawn in — what the reviewer checks
              // before approving, and what goes into the customer's library with the file.
              if (version.printColors.isNotEmpty) ...[
                SizedBox(height: 10.h),
                PrintColorsView(colors: version.printColors),
              ],
              // The reviewer's words, headed and coloured by **the verdict they came with**.
              //
              // This box was red and headed «المطلوب تعديله» on any note at all, so a version
              // the reviewer had *approved* with a word of praise was drawn as a rejection —
              // a green «معتمد» pill a centimetre above a red «المطلوب تعديله» saying the
              // opposite. The note does not know what it is; the status does.
              if (version.reviewNote case final note? when note.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Builder(
                  builder: (context) {
                    final (heading, background, foreground) = version.needsChanges
                        ? (
                            'المطلوب تعديله',
                            scheme.errorContainer.withValues(alpha: 0.5),
                            scheme.onErrorContainer,
                          )
                        : (
                            'ملاحظة المُراجِع',
                            scheme.surfaceContainerHighest,
                            scheme.onSurface,
                          );

                    return Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: background,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heading,
                            style: text.labelSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: foreground,
                            ),
                          ),
                          SizedBox(height: 4.h),
                          Text(note, style: text.bodySmall?.copyWith(color: foreground)),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
