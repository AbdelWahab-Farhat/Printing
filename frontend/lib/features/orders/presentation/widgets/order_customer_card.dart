import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Who the order is for, on the order's own screen — and the way into their file.
///
/// The three things a customer is looked up by are the three things this shows: the code said
/// on the phone, the name, and the number rung. Anything less sends somebody to the customers
/// tab to search for a person the order already knows.
///
/// **The code leads, in the card's own square.** Same reasoning as `CustomerCard`: it is the one
/// value on the row that is unique and short, and it is what one colleague says to another.
///
/// **The chevron appears only when there is somewhere to go.** [onTap] is null for anybody
/// without `customers.view`, and an arrow promising a screen that would answer 403 is worse than
/// no arrow — so the affordance and the action arrive together or not at all.
class OrderCustomerCard extends StatelessWidget {
  const OrderCustomerCard({required this.order, this.onTap, super.key});

  /// Lets a test assert on the affordance rather than on an icon that may be replaced.
  static const Key chevronKey = Key('order-customer-card-chevron');

  final Order order;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final customer = order.customer;

    return Material(
      color: scheme.surfaceContainerLow,
      // `shape` rather than `borderRadius`: the card needs the same hairline the sections
      // beside it carry, and `Material` only draws a side through a shape.
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: Padding(
          padding: EdgeInsets.all(14.w),
          child: Row(
            children: [
              _CodeBadge(code: customer?.code),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // The list endpoint does not always carry the customer, and a blank card
                      // would be worse than the id nobody says out loud.
                      customer?.name ?? 'عميل #${order.customerId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (customer?.phone case final phone?) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          Icon(AppIcons.phone, size: 15.sp, color: scheme.onSurfaceVariant),
                          SizedBox(width: 5.w),
                          Text(
                            phone,
                            // A Libyan number reads left-to-right even inside this RTL card.
                            textDirection: TextDirection.ltr,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  AppIcons.forward,
                  key: chevronKey,
                  size: 20.sp,
                  color: scheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CodeBadge extends StatelessWidget {
  const _CodeBadge({required this.code});

  /// Null when the customer was not sent with the order.
  final String? code;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Container(
      height: 48.w,
      width: 48.w,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(14.r),
      ),
      // Scaled rather than clipped: codes grow with the table, and «C12…» and «C128…» read as
      // the same customer.
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          code ?? '؟',
          textDirection: TextDirection.ltr,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onPrimaryContainer,
          ),
        ),
      ),
    );
  }
}
