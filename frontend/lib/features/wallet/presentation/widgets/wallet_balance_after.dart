import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// الرصيدُ الحالي، ثم ما بعد الحركة ما إن يُكتب مبلغ. وتحت الصفر بلون الخطأ.
class WalletBalanceAfter extends StatelessWidget {
  const WalletBalanceAfter({
    required this.balance,
    required this.after,
    required this.afterLabel,
    super.key,
  });

  final String balance;

  /// الرصيد لو حُفظ ما كُتب، أو null ما لم يكن رقماً موجباً.
  final String? after;

  /// «الرصيد بعد التعديل»، «الرصيد بعد السحب».
  final String afterLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final shown = after ?? balance;
    final isBelowZero = shown.startsWith('-');

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              after == null ? 'الرصيد الحالي' : afterLabel,
              style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Text(
            '${shown.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: isBelowZero ? scheme.error : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
