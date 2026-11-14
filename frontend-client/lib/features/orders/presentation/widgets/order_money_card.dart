import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:dayaa_client/core/utils/context_extensions.dart';
import 'package:dayaa_client/core/utils/fixed_point.dart';
import 'package:dayaa_client/core/widgets/app_card.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/presentation/widgets/order_money_cells.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// مال الطلبية: خاناتها الثلاث ([OrderMoneyCells]، هي نفسها في بطاقة «طلباتي») — سعر الطلبية،
/// والمدفوع، والمتبقي — وتحتها ما ليس منها.
///
/// **والتوصيل تحت الخانات لا بينها**، باسم «التوصيل للمندوب»: ليس من سعر الطلبية ولا من
/// المتبقي — يأخذه المندوب عند الباب على حسابه (قرار صاحب العمل، ٢٠٢٦-٠٩-٠٨). فوق «المتبقي»
/// يجمعه القارئ إليه.
class OrderMoneyCard extends StatelessWidget {
  const OrderMoneyCard({required this.order, super.key});

  final CustomerOrderDetail order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final extras = [
      // «تعويض»: المتجر يرسل هذه البضاعة بلا مقابل — يُقال صراحةً لماذا السعر صفر.
      if (order.isCompensation) _Extra.free('طلبية تعويض', icon: AppIcons.gift),
      if (order.designFee case final fee? when fee._isSomething) _Extra('التصميم', fee),
      if (order.discount case final discount? when discount._isSomething)
        _Extra('الخصم', discount),
      // المتجر يدفع للمندوب: لا شيء يُحضَّر عند الباب، فيُقال ذلك صراحةً لا بغياب السطر.
      if (order.deliveryPaidBy == 'us')
        _Extra.free('التوصيل', icon: AppIcons.outForDelivery)
      else if (order.deliveryPrice case final delivery? when delivery._isSomething)
        _Extra('التوصيل للمندوب', delivery, icon: AppIcons.outForDelivery),
    ];

    return AppCard.raised(
      padding: EdgeInsets.fromLTRB(8.w, 16.h, 8.w, 14.h),
      child: Column(
        children: [
          OrderMoneyCells(
            total: order.total,
            paidAmount: order.paidAmount,
            balance: order.balance,
            isAwaitingQuote: order.isAwaitingQuote,
          ),
          if (extras.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 14.h, 8.w, 0),
              child: Divider(height: 1, thickness: 1, color: scheme.surfaceContainerHigh),
            ),
            for (final extra in extras)
              Padding(padding: EdgeInsets.fromLTRB(8.w, 12.h, 8.w, 0), child: extra),
          ],
        ],
      ),
    );
  }
}

/// سطرٌ تحت الخانات: اسمه، ومبلغه في آخر السطر.
class _Extra extends StatelessWidget {
  const _Extra(this.label, String this.amount, {this.icon});

  /// سطرٌ بلا مبلغ: «التوصيل — مجاني».
  const _Extra.free(this.label, {this.icon}) : amount = null;

  final String label;

  /// null في سطر «مجاني».
  final String? amount;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final style = context.textTheme.bodyMedium?.copyWith(fontSize: 14.sp, height: 1.45);

    return Row(
      children: [
        if (icon case final icon?) ...[
          Icon(icon, size: 18.sp, color: scheme.onSurfaceVariant),
          SizedBox(width: 8.w),
        ],
        Expanded(
          child: Text(
            label,
            style: style?.copyWith(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
          ),
        ),
        Text(
          switch (amount) {
            final amount? => '${amount.asMoney} د.ل',
            null => 'مجاني',
          },
          style: style?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}

extension on String {
  /// هل المبلغ يستحق سطراً.
  ///
  /// **لا null عند الخادم لـ«لا خصم».** الخصم ورسم التصميم والتوصيل أعمدةٌ عشرية لا تكون null،
  /// فتصل «0.00» وكانت كل طلبيةٍ ترسم «الخصم 0.00 د.ل» — سطرٌ كل ما فيه أنه موجود. ويُقارَن
  /// بالأجزاء من الألف لا بالنص: الصفر نفسه يصل «0» و«0.00» و«0.000» حسب عموده.
  bool get _isSomething => thousandths(this) != BigInt.zero;
}
