import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// طلبيةٌ تحمل بضاعةَ الصندوق خارج الرفّ — وما أخذته منها.
///
/// على شكل بطاقة طلبية الفترة (`PeriodOrderCard`): رمزُ الطلبية وحالتُها فوق، ثم **تكلفةُ بضاعة
/// الصندوق فيها** أكبرَ رقمٍ في البطاقة — هو ما يجمعه بندُ اللوحة — ثم المادّةُ والكمّية تحته
/// مباشرةً لا خلف نقرة: «ما هذه البضاعة» نصفُ السؤال.
class FundGoodsOrderCard extends StatelessWidget {
  const FundGoodsOrderCard({
    required this.order,
    required this.stage,
    this.onTap,
    super.key,
  });

  final FundGoodsOrder order;
  final FundGoodsStage stage;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

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
                        order.statusLabel,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  '${order.cost.grouped} د.ل',
                  textDirection: TextDirection.ltr,
                  style: context.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: scheme.primary,
                  ),
                ),
                Text('تكلفة بضاعة الصندوق', style: quiet),
                if (_who case final who?) ...[
                  SizedBox(height: 6.h),
                  Text(who, style: quiet),
                ],
                // **ما على العميل**، للمسلَّمة وحدها: هو ما يبقي تكلفتَها في هذا البند، وما
                // يُسأل عنه حين تُتابَع. والتي في الطريق لم يُطالَب أحدٌ بها بعد.
                if (stage == FundGoodsStage.uncollected) ...[
                  SizedBox(height: 8.h),
                  Row(
                    children: [
                      Expanded(
                        child: Text('المتبقي على العميل', style: context.textTheme.bodyMedium),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        '${order.remaining.grouped} د.ل',
                        textDirection: TextDirection.ltr,
                        style: context.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: scheme.error,
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.goods.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Divider(height: 1.h, color: scheme.outlineVariant.withValues(alpha: 0.6)),
                  SizedBox(height: 8.h),
                  for (final line in order.goods) _GoodsLine(line: line),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// من اشتراها ومتى — بيومِ كتابتها في الطريق، وبيومِ تسليمها عند من لم يدفع.
  String? get _who {
    final at = stage == FundGoodsStage.uncollected ? order.deliveredAt : order.placedAt;
    final parts = <String>[
      if (order.customerName case final name? when name.isNotEmpty) name,
      if (at != null) at.dayLabel,
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// مادّةٌ واحدة داخل الطلبية: اسمُها، وكم أخذت منها، وبكم.
class _GoodsLine extends StatelessWidget {
  const _GoodsLine({required this.line});

  final FundGoodsLine line;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 3.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              line.name ?? line.code ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            [line.quantity.grouped, ?line.unitLabel].join(' '),
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          SizedBox(width: 12.w),
          Text(
            '${line.cost.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
