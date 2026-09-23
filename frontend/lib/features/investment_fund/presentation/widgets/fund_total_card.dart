import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// رقمٌ من أرقام الصندوق في رأس شاشته — «قيمة الصندوق» على اللوحة، ورقمُ البند فوق قائمته.
///
/// **البطاقةُ نفسُها في الموضعين عن قصد**: من فتح «بضاعة على الرفّ» من اللوحة يرى فوق القائمة
/// الرقمَ الذي ضغطه في الإطار نفسِه، فيعرف أن ما تحته هو ما يتكوّن منه ذلك الرقم.
class FundTotalCard extends StatelessWidget {
  const FundTotalCard({required this.label, required this.amount, this.action, super.key});

  final String label;
  final String amount;

  /// زرٌّ في زاوية البطاقة — سجلُّ الخزينة بجانب قيمة الصندوق.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    final card = Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: context.textTheme.bodyMedium?.copyWith(color: scheme.onPrimaryContainer),
          ),
          SizedBox(height: 6.h),
          Text(
            '${amount.grouped} د.ل',
            textDirection: TextDirection.ltr,
            style: context.textTheme.headlineSmall?.copyWith(
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );

    final corner = action;

    if (corner == null) return card;

    return Stack(
      children: [
        card,
        PositionedDirectional(top: 4.h, end: 4.w, child: corner),
      ],
    );
  }
}
