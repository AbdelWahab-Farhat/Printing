import 'package:dayaa/core/theme/app_tones.dart';
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

/// لونا الحالة — للشريحة. ونقطتُها على البلاطة والصفّ من [periodProfitStateDot]، بالدرجة القويّة
/// من اللون نفسِه، فلا يتعلّم القارئُ مفتاحين.
///
/// **«بانتظار انتهاء الفترة» كهرمانيّة** (2026-10-25، تصميم ب): الرماديُّ المخضرّ كان لا يُفرَّق
/// عن تركوازِ «استُلم» على شاشةٍ داكنة، والكهرمانُ في هذا التطبيق معناه «لم يحن بعد».
(Color, Color) periodProfitStateColors(BuildContext context, PeriodProfitState state) {
  final scheme = context.colorScheme;

  return switch (state) {
    PeriodProfitState.released => (scheme.primaryContainer, scheme.onPrimaryContainer),
    PeriodProfitState.awaitingPayment => (scheme.errorContainer, scheme.onErrorContainer),
    PeriodProfitState.awaitingPeriodEnd => (scheme.warnContainer, scheme.onWarnContainer),
    PeriodProfitState.awaitingDelivery => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
  };
}

/// نقطةُ الحالة — على بلاطة المجموع وأمام صفِّ الطلبية.
Color periodProfitStateDot(BuildContext context, PeriodProfitState state) {
  final scheme = context.colorScheme;

  return switch (state) {
    PeriodProfitState.released => scheme.primary,
    PeriodProfitState.awaitingPayment => scheme.error,
    PeriodProfitState.awaitingPeriodEnd => scheme.warn,
    PeriodProfitState.awaitingDelivery => scheme.tertiary,
  };
}

/// نقطةُ الحالة مرسومة: ممتلئةٌ لما في الدفتر، و**حلقةٌ لـ«قيد التسليم»** — توقّعٌ لا صفَّ له، فلا
/// يُرسم كما يُرسم المقيَّد.
class PeriodProfitStateDot extends StatelessWidget {
  const PeriodProfitStateDot({required this.state, this.size, super.key});

  final PeriodProfitState state;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final color = periodProfitStateDot(context, state);
    final side = size ?? 10.r;
    final ring = state == PeriodProfitState.awaitingDelivery;

    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ring ? null : color,
        border: ring ? Border.all(color: color, width: 2) : null,
      ),
    );
  }
}
