import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/period_expenses.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مصروفٌ على الصندوق — كم خرج، ولماذا، ومن تحمّله.
///
/// **على شكل [PeriodOrderCard]**: نصيبُ كلِّ مستثمرٍ تحت الصفّ مباشرةً لا خلف نقرة، لأن «كم
/// تحمّلتُ أنا» هو نصفُ ما يفتح المستثمرُ هذه الشاشة ليقرأه.
///
/// **وما لا يُعدّ يُرسم مشطوباً ولا يُخفى.** المعكوسُ والمسجَّلُ بعد الإقفال يبقيان سطرين
/// يُقرآن بسببهما — إخفاؤهما يترك المستثمرَ أمام ردٍّ في محفظته لا يجد له أصلاً.
class PeriodExpenseCard extends StatelessWidget {
  const PeriodExpenseCard({required this.expense, this.onReverse, super.key});

  final PeriodExpense expense;

  /// يظهر الزرُّ حين يُمرَّر — لمن يملك صلاحية العكس، على مصروفٍ لم يُعكس.
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);
    final share = expense.investorsAmount;
    final refunded = share.startsWith('-');
    final note = _note;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 12.h),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
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
            Text(
              '${expense.amount.grouped} د.ل',
              textDirection: TextDirection.ltr,
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: expense.counted ? scheme.onSurface : scheme.onSurfaceVariant,
                decoration: expense.counted ? null : TextDecoration.lineThrough,
              ),
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
            if (expense.investors.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Divider(height: 1.h, color: scheme.outlineVariant.withValues(alpha: 0.6)),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      refunded ? 'رُدَّ إلى المستثمرين' : 'على المستثمرين',
                      style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  Text(
                    '${(refunded ? share.substring(1) : share).grouped} د.ل',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: refunded ? scheme.primary : scheme.error,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4.h),
              for (final investor in expense.investors)
                _Share(share: investor, refunded: refunded),
            ],
            if (onReverse != null) ...[
              SizedBox(height: 4.h),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton.icon(
                  onPressed: onReverse,
                  icon: Icon(AppIcons.undo, size: 18.r),
                  label: const Text('عكس المصروف'),
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                ),
              ),
            ],
          ],
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
    final reversal = expense.reversal;

    if (expense.recordedAfterClose) {
      return 'سُجِّل بعد إقفال الفترة — حُمِّل على الفترة المفتوحة يومها';
    }

    if (reversal == null) return null;

    final reason = switch (reversal.reason) {
      final text? when text.isNotEmpty => ': $text',
      _ => '',
    };
    final where = switch (reversal.periodCode) {
      final code? when code.isNotEmpty => ' في الفترة $code',
      _ => '',
    };

    return expense.counted
        ? 'عُكس بعد إقفال الفترة$where$reason — يبقى في أرقامها، والردُّ هناك'
        : 'عُكس$where$reason';
  }
}

/// سطرُ شريكٍ تحت المصروف: اسمُه، وما تحمّله منه أو رُدّ إليه.
class _Share extends StatelessWidget {
  const _Share({required this.share, required this.refunded});

  final PeriodInvestorShare share;
  final bool refunded;

  @override
  Widget build(BuildContext context) {
    final amount = share.amount.startsWith('-') ? share.amount.substring(1) : share.amount;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(child: Text(share.name, style: context.textTheme.bodyMedium)),
          SizedBox(width: 8.w),
          Text(
            '${amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
