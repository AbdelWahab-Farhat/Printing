import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// أين ربحُ طلبيةٍ من جيوب المستثمرين — شريحةٌ بلون حالتها.
///
/// **الألوانُ من المخطط لا من قيمٍ مكتوبة**، كبقيّة الشرائح: الثيمُ يُولَّد ويُستبدل كلُّه.
/// والمحجوزُ بلون الخطأ لأنه الوحيدُ الذي ينتظر فعلاً من أحد — دفعةَ العميل.
class PeriodProfitStateChip extends StatelessWidget {
  const PeriodProfitStateChip({required this.state, this.label, super.key});

  final PeriodProfitState state;

  /// لفظُ الخادم إن وصل، وإلا لفظُ الحالة نفسُها.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = periodProfitStateColors(context, state);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.r),
      ),
      child: Text(
        label ?? state.label,
        style: context.textTheme.bodyMedium?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// لونا الحالة — للشريحة، ولنقطة المرشّح وحافة بطاقة المجموع، فلا يتعلّم القارئُ مفتاحين.
(Color, Color) periodProfitStateColors(BuildContext context, PeriodProfitState state) {
  final scheme = context.colorScheme;

  return switch (state) {
    PeriodProfitState.released => (scheme.primaryContainer, scheme.onPrimaryContainer),
    PeriodProfitState.awaitingPayment => (scheme.errorContainer, scheme.onErrorContainer),
    PeriodProfitState.awaitingPeriodEnd => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    PeriodProfitState.awaitingDelivery => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
  };
}
