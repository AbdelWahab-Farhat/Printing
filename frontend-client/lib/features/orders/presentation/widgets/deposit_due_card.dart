import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «بانتظار العربون» على الطلبية: كم، وأين يُدفع (صاحب العمل، 2026-10-19).
///
/// **لا يُرسم إلا والطلبية تنتظر عربونها** ([CustomerOrderDetail.depositExpected]). المكتبُ يُقال
/// صراحةً حين اختاره الزبون في السلة — أو سمّاه الموظف نقداً — وما سواه يُدفع من «ادفع من المحفظة»
/// تحته، فالجملة تشير إليه.
class DepositDueCard extends StatelessWidget {
  const DepositDueCard({required this.order, super.key});

  final CustomerOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final amount = order.depositExpected;

    if (amount == null) return const SizedBox.shrink();

    final scheme = context.colorScheme;

    return Padding(
      padding: EdgeInsets.only(top: 12.h),
      child: AppCard.accent(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Icon(AppIcons.awaitingDeposit, size: 26.sp, color: scheme.primary),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'العربون ${amount.asMoney} د.ل',
                    style: context.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    order.depositAtOffice
                        ? 'ادفعه في المكتب، ونبدأ العمل على طلبيتك حين يصلنا.'
                        : 'ادفعه من محفظتك أدناه، ونبدأ العمل على طلبيتك حين يصلنا.',
                    style: context.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
