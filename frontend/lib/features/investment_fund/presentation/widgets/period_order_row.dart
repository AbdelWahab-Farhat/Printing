import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/utils/text_direction.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/period_profit_state_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// طلبيةٌ أعطت مستثمري الفترة ربحاً — صفٌّ في بطاقة طلبيات الفترة (تصميم ب، 2026-10-25).
///
/// **نقطةُ حالتها، فرمزُها، فالعميلُ وحالتُها سطراً، ونصيبُ المستثمرين أكبرُ رقمٍ على الصفّ.**
/// كانت بطاقةً بشريحتين وجملةٍ تحت الرقم وسطرٍ لكلّ شريك، فكانت طلبيتان تملآن الشاشة.
///
/// **والشركاءُ سطرٌ واحدٌ تحتها متى تعدّدوا.** شريكٌ واحدٌ يأخذ رقمَها كلَّه، فسطرُه تكرار.
class PeriodOrderRow extends StatelessWidget {
  const PeriodOrderRow({required this.order, this.onTap, super.key});

  final PeriodOrder order;
  final VoidCallback? onTap;

  /// في الطريق ولم يُقيَّد لها شيء: رقمُها ما سيصل عند التسليم، لا صفرُ الدفتر.
  bool get _onTheRoadOnly =>
      order.profitState == PeriodProfitState.awaitingDelivery && order.investors.isEmpty;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final muted = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);
    final state = order.profitState;
    final shares = _onTheRoadOnly ? order.expectedInvestors : order.investors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            if (state != null) ...[
              PeriodProfitStateDot(state: state),
              SizedBox(width: 12.w),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.code,
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(text: _who),
                        // قرارُ المالك ٣: يُرى قبل الإقفال أن ربحها سيُحجز.
                        if (order.uncollected && state == PeriodProfitState.awaitingPeriodEnd)
                          TextSpan(
                            text: ' · غير محصّلة',
                            style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: muted,
                  ),
                  for (final part in _parts) Text(part, style: muted),
                  if (shares.length > 1)
                    Text(
                      shares.map((share) => '${share.name} ${share.amount.grouped}'.isolated).join(' · '),
                      style: muted,
                    ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            _figure(context),
          ],
        ),
      ),
    );
  }

  /// الرقمُ الكبير: ما في الدفتر، أو ما سيصل عند التسليم — وما لم يُسعَّر يُقال ولا يُكتب صفراً.
  Widget _figure(BuildContext context) {
    final scheme = context.colorScheme;

    if (_onTheRoadOnly && order.byState?.awaitingDelivery == null) {
      // §١٢أ: «قبل ذلك تكون مجهولة».
      return Text(
        'لم يُسعَّر بعد',
        style: context.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w700,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    final amount = _onTheRoadOnly ? order.byState!.awaitingDelivery! : order.investorsTotal;

    // السالبُ تصحيحٌ هبط على هذه الفترة، فيُقال بإشارته ولونه لا بجملةٍ تحته.
    return Text(
      '${amount.grouped} د.ل',
      textDirection: TextDirection.ltr,
      style: context.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
        color: amount.startsWith('-') ? scheme.error : null,
      ),
    );
  }

  /// من اشتراها، وأين هي — كلُّ جزءٍ معزول، فلا يجرّ اسمٌ لاتينيّ ما بعده إليه.
  String get _who => [
    if (order.customerName case final name? when name.isNotEmpty) name.isolated,
    order.statusLabel.isolated,
  ].join(' · ');

  /// أجزاءُ ربحٍ انقسم بين حالتين — هامشُ سادةٍ أُفرج عنه وربحُ تسليمٍ ينتظر — كلٌّ بمبلغه.
  ///
  /// والطلبيةُ في جزءٍ واحد لا سطرَ لها هنا: نقطتُها ورقمُها يقولان ذلك أصلاً.
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
}
