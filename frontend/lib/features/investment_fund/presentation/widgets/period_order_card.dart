import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
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

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final radius = BorderRadius.circular(20.r);
    final isNegative = order.investorsTotal.startsWith('-');

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
                SizedBox(height: 8.h),
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
                if (_who != null) ...[
                  SizedBox(height: 6.h),
                  Text(
                    _who!,
                    style: context.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (order.investors.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  Divider(height: 1.h, color: scheme.outlineVariant.withValues(alpha: 0.6)),
                  SizedBox(height: 8.h),
                  for (final share in order.investors) _Share(share: share),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// من اشتراها ومتى، متى عُرف أيُّهما.
  String? get _who {
    final parts = <String>[
      if (order.customerName != null && order.customerName!.isNotEmpty) order.customerName!,
      if (order.occurredAt != null) order.occurredAt!.dayLabel,
    ];

    return parts.isEmpty ? null : parts.join(' · ');
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
