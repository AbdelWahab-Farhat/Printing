import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';

/// One value that can be lifted out of the app, with no label above it.
///
/// Distinct from the labelled two-line form a shop's address still needs:
/// «الموقع» over «طرابلس · سوق الجمعة» has to say which of the two lines it is. A phone number
/// under a customer's name does not — nothing else there could be mistaken for one.
class CopyText extends StatelessWidget {
  const CopyText({
    required this.value,
    required this.copiedMessage,
    required this.icon,
    this.style,
    super.key,
  });

  final String value;
  final String copiedMessage;
  final IconData icon;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        unawaited(Clipboard.setData(ClipboardData(text: value)));
        context.showSuccess(copiedMessage);
      },
      borderRadius: BorderRadius.circular(8.r),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: context.colorScheme.onSurfaceVariant),
            SizedBox(width: 6.w),
            Flexible(
              child: Text(
                value,
                // A Libyan number reads left-to-right even inside this RTL row.
                textDirection: TextDirection.ltr,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style,
              ),
            ),
            SizedBox(width: 6.w),
            Icon(AppIcons.copy, size: 14.sp, color: context.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
