import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/dates.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «غير مراجَعة» or «تمت المراجعة — فلان · التاريخ», and the one button that changes it.
///
/// **Every decision here is the server's.** Whether there is a badge at all
/// ([OrderPayment.showsReview]), whether this person may review ([OrderPayment.canReview]) or take
/// a review back ([OrderPayment.canUnreview]), and why not ([OrderPayment.reviewBlockedReason]) —
/// so the app keeps no copy of the rule.
///
/// Draws nothing on a row nobody is asked to check.
class PaymentReviewLine extends StatelessWidget {
  const PaymentReviewLine({
    required this.payment,
    required this.isBusy,
    required this.onReview,
    super.key,
  });

  final OrderPayment payment;
  final bool isBusy;

  /// Called with `true` to review, `false` to take a review back.
  final void Function(bool reviewed) onReview;

  @override
  Widget build(BuildContext context) {
    if (!payment.showsReview) return const SizedBox.shrink();

    final scheme = context.colorScheme;
    final reviewed = payment.isReviewed;
    final tone = reviewed ? scheme.primary : scheme.tertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              reviewed ? AppIcons.paymentReviewed : AppIcons.awaitingReview,
              size: 15.sp,
              color: tone,
            ),
            SizedBox(width: 6.w),
            Expanded(
              child: Text(
                reviewed ? _reviewedBy(payment) : 'غير مراجَعة',
                style: context.textTheme.bodySmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (payment.canReview)
              TextButton(
                key: ValueKey('review-${payment.id}'),
                onPressed: isBusy ? null : () => onReview(true),
                child: const Text('مراجعة'),
              )
            else if (payment.canUnreview)
              TextButton(
                key: ValueKey('unreview-${payment.id}'),
                onPressed: isBusy ? null : () => onReview(false),
                style: TextButton.styleFrom(foregroundColor: scheme.onSurfaceVariant),
                child: const Text('إلغاء المراجعة'),
              ),
          ],
        ),
        // Said only to the person it is about: somebody without the grant gets no reason,
        // because there was never a button for them.
        if (payment.reviewBlockedReason case final reason? when !reviewed)
          Padding(
            padding: EdgeInsetsDirectional.only(start: 21.w),
            child: Text(
              reason,
              style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  /// The day as [AppDates.stamp] rather than «منذ ساعتين»: this is read weeks later, by somebody
  /// asking who vouched for the money — the reasoning the deposit card gives.
  static String _reviewedBy(OrderPayment payment) {
    final who = payment.reviewedBy?.name;
    final when = payment.reviewedAt?.stampLabel;

    return switch ((who, when)) {
      (final name?, final stamp?) => 'تمت المراجعة — $name · $stamp',
      (final name?, null) => 'تمت المراجعة — $name',
      (null, final stamp?) => 'تمت المراجعة · $stamp',
      _ => 'تمت المراجعة',
    };
  }
}
