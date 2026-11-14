import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// «التوصيل علينا» on the new-order form — off by default, which leaves it on the recipient.
///
/// **Says what it does the moment it is on**, because the clerk at the counter is promising the
/// customer free delivery and may not know that the fee becomes the order's own cost, shared by
/// the investors. Docs/orders/DELIVERY-PAYER.md.
class DeliveryPayerSwitch extends StatelessWidget {
  const DeliveryPayerSwitch({
    required this.value,
    required this.onChanged,
    required this.deliveryPrice,
    this.isCompensation = false,
    super.key,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  /// The chosen city's rate, or null when none has been agreed.
  final String? deliveryPrice;

  /// On a «طلبية تعويض» the fee is the company's alone — the investors share none of it.
  final bool isCompensation;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          type: MaterialType.transparency,
          child: SwitchListTile.adaptive(
            value: value,
            onChanged: onChanged,
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Icon(AppIcons.outForDelivery, size: 18.sp, color: value ? scheme.primary : scheme.outline),
                SizedBox(width: 8.w),
                Text(
                  'التوصيل علينا — مجاني للزبون',
                  style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        if (value)
          DeliveryPayerWarnings(
            warnings: [
              if (isCompensation)
                'أجرة التوصيل تصير تكلفةً على الشركة وحدها — طلبية التعويض لا يتحمّل المستثمرون منها شيئاً.'
              else
                'أجرة التوصيل تصير تكلفةً على الطلبية: تُخصم من ربحها، ويتحمّل المستثمرون حصتهم منها.',
              if (deliveryPrice case final price? when (num.tryParse(price) ?? 0) > 0)
                'المحسوب الآن ${price.grouped} حسب سعر المدينة، وإن احتفظ الناقل بغيره عند التسوية صار هو التكلفة.'
              else
                'لا سعر توصيل لهذه المدينة — التكلفة تُعرف عند التسوية مما يحتفظ به الناقل.',
            ],
          ),
      ],
    );
  }
}

/// The server's sentences about what a switch would do — amber, one per line, above the button.
class DeliveryPayerWarnings extends StatelessWidget {
  const DeliveryPayerWarnings({required this.warnings, super.key});

  final List<String> warnings;

  @override
  Widget build(BuildContext context) {
    if (warnings.isEmpty) return const SizedBox.shrink();

    final scheme = context.colorScheme;

    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final warning in warnings)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 3.h),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(AppIcons.error, size: 16.sp, color: scheme.tertiary),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      warning,
                      style: context.textTheme.bodySmall?.copyWith(color: scheme.onTertiaryContainer),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// «من يدفع التوصيل؟» for an order already taken — answers with the payer chosen
/// (`recipient` or `us`), or null when the sheet was closed.
///
/// **Only the other side is offered**, with what switching to it does — the order's own
/// `delivery_payer_warnings`, written by the server. Nothing is sent until the button is pressed.
Future<String?> showDeliveryPayerSheet({required BuildContext context, required Order order}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _DeliveryPayerSheet(order: order),
  );
}

class _DeliveryPayerSheet extends StatelessWidget {
  const _DeliveryPayerSheet({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final toUs = !order.wePayDelivery;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'من يدفع التوصيل؟',
              style: context.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6.h),
            Text(
              '${toUs ? 'الآن: التوصيل على المستلم' : 'الآن: التوصيل علينا'}'
              ' — سعر التوصيل ${order.deliveryPrice.grouped}',
              style: context.textTheme.bodyMedium?.copyWith(color: context.colorScheme.onSurfaceVariant),
            ),
            SizedBox(height: 12.h),
            DeliveryPayerWarnings(warnings: order.deliveryPayerWarnings),
            SizedBox(height: 16.h),
            AppButton(
              label: toUs ? 'اجعل التوصيل علينا' : 'أرجِع التوصيل على المستلم',
              onPressed: () => Navigator.of(context).pop(toUs ? 'us' : 'recipient'),
            ),
            SizedBox(height: 8.h),
            AppButton(
              label: 'إلغاء',
              variant: AppButtonVariant.outlined,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
