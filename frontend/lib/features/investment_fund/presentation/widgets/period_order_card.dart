import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/text_direction.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_profit_state_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// طلبيةٌ أعطت مستثمري الفترة ربحاً — وكم أخذ كلُّ واحدٍ منها.
///
/// **نصيبُ المستثمرين أكبرُ رقمٍ على الصفّ** لأنه سؤالُ من فتح هذه الشاشة؛ ورمزُ الطلبية
/// واسمُ العميل فوقه وتحته لأنهما ما يُعرَف به أيُّ طلبيةٍ هي، لا ما جاء يقرأه.
///
/// **والصفُّ يُقسَّم على أصحابه تحته مباشرةً** لا خلف نقرةٍ ثانية: «ربح كل مستثمر» هو نصفُ
/// السؤال، وإخفاؤه خلف توسيعٍ يجعل قارئَ الشاشة يفتح عشرةَ صفوفٍ ليجمع رقماً واحداً.
class PeriodOrderCard extends StatelessWidget {
  const PeriodOrderCard({required this.order, this.onTap, super.key});

  final PeriodOrder order;
  final VoidCallback? onTap;

  /// في الطريق ولم يُقيَّد لها شيء: رقمُها ما سيصل عند التسليم، لا صفرُ الدفتر.
  bool get _onTheRoadOnly =>
      order.profitState == PeriodProfitState.awaitingDelivery && order.investors.isEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);
    final isNegative = order.investorsTotal.startsWith('-');
    final expected = order.byState?.awaitingDelivery;
    final shares = _onTheRoadOnly ? order.expectedInvestors : order.investors;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
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
                        'طلبية ${order.code}',
                        style: context.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: scheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999.r),
                      ),
                      child: Text(
                        order.statusLabel,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                if (order.profitState case final state?) ...[
                  SizedBox(height: 8.h),
                  Wrap(
                    spacing: 8.w,
                    runSpacing: 4.h,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      PeriodProfitStateChip(state: state, label: order.profitStateLabel),
                      // قرارُ المالك ٣: يُرى قبل الإقفال أن ربحها سيُحجز.
                      if (order.uncollected && state == PeriodProfitState.awaitingPeriodEnd)
                        Text(
                          'غير محصّلة',
                          style: context.textTheme.bodyMedium?.copyWith(
                            color: scheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ],
                SizedBox(height: 8.h),
                if (_onTheRoadOnly && expected == null) ...[
                  // §١٢أ: «قبل ذلك تكون مجهولة» — يُعدّ ولا يُسعَّر، ولا يُكتب له صفر.
                  Text(
                    'لم يُسعَّر بعد',
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    'يُحسب ربحها حين تصير جاهزة',
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ] else if (_onTheRoadOnly) ...[
                  Text(
                    '${expected!.grouped} د.ل',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: scheme.primary,
                    ),
                  ),
                  Text(
                    'ربح متوقّع عند التسليم',
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ] else ...[
                  Text(
                    // السالبُ تصحيحٌ هبط على هذه الفترة، فيُقال بإشارته لا بكلمةٍ تُخمَّن.
                    '${order.investorsTotal.grouped} د.ل',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isNegative ? scheme.error : scheme.primary,
                    ),
                  ),
                  Text(
                    isNegative ? 'رُدَّ من نصيب المستثمرين' : 'نصيب المستثمرين',
                    style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
                for (final part in _parts)
                  Padding(
                    padding: EdgeInsets.only(top: 4.h),
                    child: Text(
                      part,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (_who != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    _who!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (shares.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Divider(height: 1.h, color: scheme.outlineVariant.withValues(alpha: 0.6)),
                  SizedBox(height: 8.h),
                  for (final share in shares) _Share(share: share),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// أجزاءُ ربحٍ انقسم بين حالتين — هامشُ سادةٍ أُفرج عنه وربحُ تسليمٍ ينتظر — كلٌّ بمبلغه.
  ///
  /// والطلبيةُ في جزءٍ واحد لا سطرَ لها هنا: شريحتُها ورقمُها يقولان ذلك أصلاً.
  List<String> get _parts {
    final byState = order.byState;

    if (byState == null) return const [];

    final ledger = order.states.where((s) => s != PeriodProfitState.awaitingDelivery).toList();
    final lines = <String>[
      if (ledger.length > 1)
        for (final state in ledger) '${state.label}: ${byState.of(state)!.grouped} د.ل',
    ];

    // في الطريق ولها في الدفتر شيءٌ أصلاً: الرقمُ الكبير للدفتر، وما سيأتي سطرٌ تحته.
    if (!_onTheRoadOnly && order.profitState == PeriodProfitState.awaitingDelivery) {
      final expected = byState.awaitingDelivery;
      lines.add(
        expected == null
            ? 'ربح التسليم: لم يُسعَّر بعد'
            : 'متوقّع عند التسليم: ${expected.grouped} د.ل',
      );
    }

    return lines;
  }

  /// من اشتراها ومتى، متى عُرف أيُّهما.
  String? get _who {
    final parts = <String>[
      if (order.customerName != null && order.customerName!.isNotEmpty) order.customerName!,
      if (order.occurredAt != null) order.occurredAt!.dayLabel,
    ];

    // كلُّ جزءٍ معزول: اسمٌ لاتينيّ كان يجرّ رقمَ اليوم إليه («taha shebani · 18» ثم «أكتوبر»).
    return parts.isEmpty ? null : parts.map((part) => part.isolated).join(' · ');
  }
}

/// سطرُ شريكٍ داخل الطلبية: اسمُه، وما أخذه منها.
class _Share extends StatelessWidget {
  const _Share({required this.share});

  final PeriodInvestorShare share;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final isNegative = share.amount.startsWith('-');

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(child: Text(share.name, style: context.textTheme.bodyMedium)),
          SizedBox(width: 8.w),
          Text(
            '${share.amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: isNegative ? scheme.error : null,
            ),
          ),
        ],
      ),
    );
  }
}
