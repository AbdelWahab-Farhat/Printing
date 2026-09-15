import 'package:cached_network_image/cached_network_image.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
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
              // What has to change — the whole reason this round happened.
              if (version.reviewNote != null && version.reviewNote!.isNotEmpty) ...[
                SizedBox(height: 10.h),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    color: scheme.errorContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المطلوب تعديله',
                        style: text.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: scheme.onErrorContainer,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        version.reviewNote!,
                        style: text.bodySmall?.copyWith(color: scheme.onErrorContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
