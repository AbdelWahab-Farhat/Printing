import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/files/attachment_picker.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';

/// «من أين تريد إضافة الملف؟» — the sheet WhatsApp taught everybody to read.
///
/// Three round targets in a row rather than a list of text rows, and that is not decoration:
/// the shape is the one every person using this app already knows from their messaging app, so
/// nobody reads it the first time. The glyph and its colour say what each one is before the
/// word underneath is read.
///
/// **It picks nothing.** It answers which [AttachmentSource] the user chose and closes; the
/// caller takes that to [AttachmentPicker]. That split is what lets this be tested without a
/// platform channel, and what lets the same sheet serve an order's designs later without
/// knowing anything about customers.
///
/// Returns null when the user dismisses it — backing out is an ordinary ending and nothing
/// should be reported about it.
Future<AttachmentSource?> showAttachmentSheet({
  required BuildContext context,
  String title = 'إضافة تصميم',
  List<AttachmentSource> sources = AttachmentSource.values,
}) {
  return showModalBottomSheet<AttachmentSource>(
    context: context,
    // The rounded top and the scrim come from the theme; only the shape is set here, because a
    // sheet with square corners under an app whose every card is rounded reads as another app.
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
    ),
    builder: (context) => _AttachmentSheet(title: title, sources: sources),
  );
}

class _AttachmentSheet extends StatelessWidget {
  const _AttachmentSheet({required this.title, required this.sources});

  final String title;
  final List<AttachmentSource> sources;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      // The home indicator on a modern iPhone sits exactly where the bottom row of a sheet
      // does, and a label under it is a label nobody can read.
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: context.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 18.h),
            Row(
              // Spread rather than centred, so the three keep the same places whether all
              // three are offered or only two.
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [for (final source in sources) _SourceButton(source: source)],
            ),
          ],
        ),
      ),
    );
  }
}

class _SourceButton extends StatelessWidget {
  const _SourceButton({required this.source});

  final AttachmentSource source;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // A colour per source, so the three are told apart before the label is read — and always
    // the same colour, so «الكاميرا» is in the same place and the same green every time.
    final (label, icon, background, foreground) = switch (source) {
      AttachmentSource.documents => (
        'مستندات',
        AppIcons.document,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
      AttachmentSource.photos => (
        'صور',
        AppIcons.photos,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      AttachmentSource.camera => (
        'الكاميرا',
        AppIcons.camera,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
    };

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(source),
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58.w,
                height: 58.w,
                decoration: BoxDecoration(color: background, shape: BoxShape.circle),
                child: Icon(icon, size: 26.sp, color: foreground),
              ),
              SizedBox(height: 8.h),
              Text(
                label,
                style: context.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
