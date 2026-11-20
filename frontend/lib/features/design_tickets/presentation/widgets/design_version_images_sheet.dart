import 'dart:async';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/core/widgets/picked_file_tiles.dart';
import 'package:dayaa/features/design_tickets/models/design_version_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «صور التصميم»: the images of one version, gathered one pick at a time.
///
/// Returns them in the order they were added, which is the order the server stores them in
/// (face 1 first). Null when the sheet is dismissed: nothing is uploaded.
Future<List<PickedFile>?> showDesignVersionImagesSheet({required BuildContext context}) {
  return showModalBottomSheet<List<PickedFile>>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => const DesignVersionImagesSheet(),
  );
}

/// **Built up, not picked in one go** (owner, 2026-11-20). A version used to be whatever one
/// trip to the picker returned, so the 2–6 images had to be selected together. That ruled out
/// the camera, which returns one photo, and any version whose faces sat in different places: the
/// front in the gallery, the logo in Files.
///
/// Each «إضافة صورة» asks for the source again and appends what comes back. Problems are said in
/// a line inside the sheet, not a snackbar, which would sit behind it.
class DesignVersionImagesSheet extends StatefulWidget {
  const DesignVersionImagesSheet({super.key});

  @override
  State<DesignVersionImagesSheet> createState() => _DesignVersionImagesSheetState();
}

class _DesignVersionImagesSheetState extends State<DesignVersionImagesSheet> {
  final List<PickedFile> _images = [];

  /// Why the last pick did not all go in. Cleared on the next add or removal.
  String? _notice;

  bool get _isFull => _images.length >= DesignVersionRules.maxImages;

  bool get _isEnough => _images.length >= DesignVersionRules.minImages;

  /// The same image picked twice. Its path is no help: the gallery hands back a fresh copy
  /// each time. Name and size together are what stay the same.
  bool _isAdded(PickedFile file) =>
      _images.any((image) => image.name == file.name && image.sizeBytes == file.sizeBytes);

  Future<void> _add() async {
    final source = await showAttachmentSheet(context: context, title: 'إضافة صورة');
    if (source == null || !mounted) return;

    final picked = await sl<AttachmentPicker>().pick(
      source,
      extensions: DesignVersionRules.extensions,
    );
    if (picked.isEmpty || !mounted) return;

    String? notice;

    setState(() {
      for (final file in picked) {
        if (!DesignVersionRules.isImage(file.name)) {
          notice = DesignVersionRules.notAnImage;
        } else if (_isAdded(file)) {
          notice = DesignVersionRules.duplicate;
        } else if (_isFull) {
          notice = DesignVersionRules.tooMany;
        } else {
          _images.add(file);
        }
      }

      _notice = notice;
    });
  }

  void _remove(PickedFile file) {
    setState(() {
      _images.remove(file);
      _notice = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final text = context.textTheme;
    final scheme = context.colorScheme;
    final notice = _notice;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'صور التصميم (${_images.length} من ${DesignVersionRules.maxImages})',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 4.h),
            Text(
              'صورتان على الأقل: وجه الكيس وظهره، أو قريبة للشعار. أضفها واحدة واحدة أو معاً',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
            SizedBox(height: 16.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                for (final image in _images)
                  PickedFileTile(file: image, onRemove: () => _remove(image)),
                if (!_isFull)
                  AddFileTile(label: 'إضافة صورة', onTap: () => unawaited(_add())),
              ],
            ),
            if (notice != null) ...[
              SizedBox(height: 10.h),
              Text(notice, style: text.bodySmall?.copyWith(color: scheme.error)),
            ],
            SizedBox(height: 20.h),
            AppButton(
              label: 'التالي',
              onPressed: _isEnough
                  ? () => Navigator.of(context).pop(List<PickedFile>.of(_images))
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
