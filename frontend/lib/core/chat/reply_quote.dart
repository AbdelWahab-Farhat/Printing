import 'package:dayaa/core/theme/app_tones.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/text_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الرسالةُ المقتبَسة، كما في بريمولا وتيليغرام: شريطٌ بلون العلامة، ومَن قالها، وسطرٌ منها.
///
/// في مكانين: **فوق الردّ داخل فقاعته** ([outgoing] يختار ألوان الفقاعة)، و**فوق صندوق الكتابة**
/// وصاحبُها يكتب ردّه ([onClose] يلغي الاقتباس). لمسُها في الفقاعة يقفز إلى الأصل ([onTap]).
class ReplyQuote extends StatelessWidget {
  const ReplyQuote({
    required this.authorName,
    required this.preview,
    this.isDeleted = false,
    this.outgoing = false,
    this.onTap,
    this.onClose,
    super.key,
  });

  final String? authorName;
  final String preview;
  final bool isDeleted;
  final bool outgoing;
  final VoidCallback? onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final inComposer = onClose != null;
    final bar = outgoing ? scheme.onOutgoingBubble : scheme.primary;
    final fill = inComposer
        ? scheme.surfaceContainerHigh
        : bar.withValues(alpha: outgoing ? 0.14 : 0.08);
    final ink = outgoing ? scheme.onOutgoingBubble : scheme.onSurface;
    final metaInk = outgoing ? scheme.outgoingMeta : scheme.onSurfaceVariant;

    return Semantics(
      button: onTap != null,
      label: 'ردّاً على ${authorName ?? 'رسالة'}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Container(
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(8.r),
            border: BorderDirectional(
              start: BorderSide(color: bar, width: 3.w),
            ),
          ),
          padding: EdgeInsetsDirectional.fromSTEB(8.w, 5.h, inComposer ? 2.w : 8.w, 5.h),
          child: Row(
            children: [
              if (inComposer) ...[
                Icon(AppIcons.reply, size: 20.sp, color: scheme.primary),
                SizedBox(width: 8.w),
              ],
              Flexible(
                fit: inComposer ? FlexFit.tight : FlexFit.loose,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (authorName case final name?)
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelMedium?.copyWith(
                          color: outgoing ? scheme.onOutgoingBubble : scheme.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: preview.readingDirection,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: isDeleted ? metaInk : ink,
                        fontStyle: isDeleted ? FontStyle.italic : null,
                      ),
                    ),
                  ],
                ),
              ),
              if (onClose case final close?)
                IconButton(
                  onPressed: close,
                  tooltip: 'إلغاء الردّ',
                  icon: Icon(AppIcons.close, size: 20.sp, color: scheme.onSurfaceVariant),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
