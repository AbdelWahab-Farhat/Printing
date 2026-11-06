import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/attachment_sheet.dart';
import 'package:dayaa/features/orders/models/receipt_rules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// يختار واصل الحوالة ويفحصه، ويعود به — أو بـnull لمن تراجع ولملفٍّ مرفوض، وقد قيل لماذا.
Future<PickedFile?> pickWalletReceipt(BuildContext context) async {
  final source = await showAttachmentSheet(context: context, title: 'إرفاق الواصل');

  if (source == null || !context.mounted) return null;

  final picked = await sl<AttachmentPicker>().pick(source);

  if (!context.mounted || picked.isEmpty) return null;

  final file = picked.first;
  final refusal = ReceiptRules.reject(file);

  if (refusal != null) {
    context.showError(refusal);

    return null;
  }

  return file;
}

/// صفُّ الواصل على ورقة محفظة — يقول وحده إنه مطلوب، ولا سطرَ تحته (٢٠٢٦-١٠-١٧).
class WalletReceiptRow extends StatelessWidget {
  const WalletReceiptRow({
    required this.receipt,
    required this.isMissing,
    required this.onPick,
    required this.onClear,
    super.key,
  });

  final PickedFile? receipt;
  final bool isMissing;
  final Future<void> Function() onPick;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final file = receipt;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isMissing ? scheme.errorContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
        border: isMissing ? Border.all(color: scheme.error) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.document, size: 18.sp, color: scheme.onSurfaceVariant),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  file?.name ?? 'الواصل — مطلوب مع الحوالة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: isMissing ? scheme.onErrorContainer : null,
                    fontWeight: file != null ? FontWeight.w700 : null,
                  ),
                ),
              ),
              if (file != null)
                IconButton(
                  icon: Icon(AppIcons.close, size: 18.sp),
                  tooltip: 'إزالة الواصل',
                  onPressed: onClear,
                ),
            ],
          ),
          SizedBox(height: 8.h),
          AppButton.tonal(
            label: file == null ? 'اختيار الواصل' : 'تغيير الواصل',
            icon: AppIcons.document,
            height: 42.h,
            onPressed: onPick,
          ),
        ],
      ),
    );
  }
}
