import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/carrier/models/nawris_settlement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// سطر طلبية واحدة: لماذا تتحرك أو لا تتحرك، وما يستحق نظرة.
///
/// **كل نصّ فيه من الخادم** — لا سبب يُبنى هنا. والمعاينة والدفعة المنفَّذة ترسمانه معاً.
class NawrisSettlementLineTile extends StatelessWidget {
  const NawrisSettlementLineTile({
    required this.line,
    this.isLeftOut = false,
    this.onToggle,
    super.key,
  });

  final NawrisSettlementLine line;

  /// تركها الموظف في المعاينة: لم يصل مالها.
  final bool isLeftOut;

  /// حين يُعطى تظهر علامة تترك الطلبية أو تعيدها. في المعاينة وحدها.
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final text = context.textTheme;

    final (icon, tone) = switch (line.outcome) {
      NawrisSettlementOutcome.settled => (AppIcons.settled, scheme.primary),
      NawrisSettlementOutcome.rejected => (AppIcons.error, scheme.error),
      _ => (AppIcons.history, scheme.onSurfaceVariant),
    };

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (onToggle != null)
                Checkbox(
                  key: ValueKey('settlement-tick-${line.orderId}'),
                  value: !isLeftOut,
                  visualDensity: VisualDensity.compact,
                  onChanged: (_) => onToggle!(),
                )
              else ...[
                Icon(icon, size: 18.sp, color: tone),
                SizedBox(width: 8.w),
              ],
              Expanded(
                child: Text(
                  line.title,
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (line.isSettling || line.outcome == NawrisSettlementOutcome.leftOut)
                // وحده بلا اتجاه يحيط به: الفاصلة تقع في الجهة الخطأ داخل سطر عربي.
                Text(
                  '${line.heldAmount.grouped} د.ل',
                  textDirection: TextDirection.ltr,
                  style: text.titleSmall,
                ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            [
              'صف ${line.rowNumber}',
              if (line.rawCode case final code? when code.isNotEmpty) 'الكود $code',
              ?line.previousStatusLabel,
            ].join(' · '),
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (isLeftOut)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                'تبقى «تم الاستلام» ومالها عند النورس',
                style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          if (line.reason case final reason?)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(reason, style: text.bodyMedium?.copyWith(color: tone)),
            ),
          if (line.feeAmount.grouped != '0')
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Text(
                'أجرة النورس ${line.feeAmount.grouped} د.ل',
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          for (final warning in line.warnings)
            Padding(
              padding: EdgeInsets.only(top: 6.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.urgent, size: 15.sp, color: scheme.tertiary),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      warning.message,
                      style: text.bodySmall?.copyWith(color: scheme.tertiary),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
