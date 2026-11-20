import 'package:dayaa/core/files/local_files.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A file picked but not sent yet: the image itself, or a PDF by its name, with a button that
/// takes it off the list.
///
/// Shared by every screen that gathers files before one request: «طلب تصميم» and the images of
/// a design version. The two must look the same, because they are the same gesture.
class PickedFileTile extends StatelessWidget {
  const PickedFileTile({required this.file, required this.onRemove, super.key});

  final PickedFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isPdf = file.name.toLowerCase().endsWith('.pdf');

    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: isPdf
              ? Container(
                  width: 76.w,
                  height: 76.w,
                  padding: EdgeInsets.all(6.w),
                  color: scheme.surfaceContainerLow,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(AppIcons.pdf, color: scheme.onSurfaceVariant),
                      SizedBox(height: 4.h),
                      Text(
                        file.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.bodySmall,
                      ),
                    ],
                  ),
                )
              : Image(
                  image: LocalFiles.image(file.path),
                  width: 76.w,
                  height: 76.w,
                  fit: BoxFit.cover,
                ),
        ),
        PositionedDirectional(
          top: -8.h,
          end: -8.w,
          child: Material(
            color: scheme.surface,
            shape: CircleBorder(side: BorderSide(color: scheme.outlineVariant)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Icon(AppIcons.close, size: 16.sp, semanticLabel: 'إزالة المرفق'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The empty square after the picked files that adds another.
class AddFileTile extends StatelessWidget {
  const AddFileTile({required this.onTap, this.label = 'إضافة مرفق', super.key});

  final VoidCallback onTap;

  /// Read out by a screen reader; the square itself shows only the icon.
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Container(
          width: 76.w,
          height: 76.w,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Icon(AppIcons.attach, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
