import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/online_payments/models/online_payment_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// محاولة شحنٍ في «المدفوعات الإلكترونية» — على شكل سطر المحفظة: أيقونةُ الحالة، ثم **لمن وبأيّ
/// طريقة**، ثم **ما وصل المحفظة**، وتحته الحالة ومتى.
class PaymentIntentRow extends StatelessWidget {
  const PaymentIntentRow({required this.intent, this.onTap, super.key});

  final PaymentIntent intent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final tone = statusTone(context, intent.status);
    final quiet = context.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Icon(statusIcon(intent.status), size: 20.sp, color: tone),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    intent.customerName ?? 'زبون',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    [
                      intent.methodLabel,
                      if (intent.orderId case final order?) 'الطلبية #$order',
                      intent.reference,
                    ].join(' · '),
                    style: quiet,
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    [
                      intent.statusLabel,
                      if (intent.createdAt case final at?) at.timeLabel,
                    ].join(' · '),
                    style: context.textTheme.bodySmall?.copyWith(color: tone, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              '${intent.netAmount.grouped} د.ل',
              textDirection: TextDirection.ltr,
              style: context.textTheme.titleLarge?.copyWith(
                color: intent.status == IntentStatus.succeeded ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// لون الحالة: الأخضر لما شُحن، والأحمر لما يحتاج شخصاً، والباهت لما انتهى بلا مال.
Color statusTone(BuildContext context, IntentStatus status) {
  final scheme = context.colorScheme;

  return switch (status) {
    IntentStatus.succeeded => scheme.primary,
    IntentStatus.needsReview => scheme.error,
    IntentStatus.created || IntentStatus.pending => scheme.tertiary,
    _ => scheme.onSurfaceVariant,
  };
}

IconData statusIcon(IntentStatus status) => switch (status) {
  IntentStatus.succeeded => AppIcons.walletTopUp,
  IntentStatus.needsReview => AppIcons.error,
  IntentStatus.created || IntentStatus.pending => AppIcons.elapsed,
  _ => AppIcons.close,
};
