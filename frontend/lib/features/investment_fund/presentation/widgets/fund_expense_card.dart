import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/fund_expense.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_status_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مصروفٌ في «مصاريف الصندوق» — كم خرج، ولماذا، و**في أيّ فترة**.
///
/// **على شكل `PeriodExpenseCard`** في شاشة الفترة، بلا نصيب المستثمرين: ذاك جوابُ فترةٍ بعينها،
/// واللمسةُ ([onTap]) تفتحها عليه.
///
/// **والفترةُ شريحةٌ بلون حالتها بجانب المبلغ** — طلبُ المالك 2026-10-12: «وبجانبها الفترة الخاصة
/// بها». وما لا يُعدّ يُرسم مشطوباً ويقول لماذا، ولا يُخفى.
class FundExpenseCard extends StatelessWidget {
  const FundExpenseCard({required this.expense, this.onTap, super.key});

  final FundExpense expense;

  /// يفتح فترتَه — `null` لمصروفٍ بلا فترة.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);
    final note = _note;

    return Material(
      color: scheme.surfaceContainerLowest,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      expense.name,
                      style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      expense.kindLabel,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        '${expense.amount.grouped} د.ل',
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: expense.counted ? scheme.onSurface : scheme.onSurfaceVariant,
                          decoration: expense.counted ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  ),
                  if (expense.period case final period?)
                    PeriodStatusChip(status: period.status, label: period.code),
                ],
              ),
              if (_who case final who?) ...[
                SizedBox(height: 4.h),
                Text(
                  who,
                  style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                ),
              ],
              if (expense.notes case final notes? when notes.isNotEmpty) ...[
                SizedBox(height: 4.h),
                Text(notes, style: context.textTheme.bodyMedium),
              ],
              if (note != null) ...[
                SizedBox(height: 8.h),
                Text(
                  note,
                  style: context.textTheme.bodyMedium?.copyWith(
                    color: scheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// يومُه، والحسابُ الذي دفع، ومن سجّله — ما عُرف منها.
  String? get _who {
    final parts = <String>[
      if (expense.incurredOn case final on?) DateTime.tryParse(on)?.dayLabel ?? on,
      ?expense.treasuryAccount?.name,
      if (expense.recordedBy case final by?) 'سجّله ${by.name}',
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }

  /// لماذا لا يُعدّ، أو لماذا يُعدّ وقد عُكس — بلفظه لا بلونٍ يُخمَّن.
  String? get _note {
    if (expense.recordedAfterClose) {
      return 'سُجِّل بعد إقفال الفترة — حُمِّل على الفترة المفتوحة يومها';
    }

    if (!expense.isReversed) return null;

    final reason = switch (expense.reversal?.reason) {
      final text? when text.isNotEmpty => ': $text',
      _ => '',
    };

    return expense.counted ? 'عُكس بعد إقفال الفترة$reason — يبقى في أرقامها' : 'عُكس$reason';
  }
}
