import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// What was added to the order that no line on it describes — «تغليف خاص — علبة كرتون مزدوجة».
///
/// **«تعديل الطلبية»'s, and no longer the order screen's.** The account there prints the charge
/// and names it on the same line — one charge answered in one place — so this is what stands
/// above the button that argues with it: what is being changed, before it is changed.
///
/// **The words are [Order.additionalCostCaption]'s and not this widget's.** The same sentence
/// goes on the PDF and into the WhatsApp message; three surfaces each joining a label to a note
/// their own way is how one order ends up described two different ways to the same customer.
class OrderAdditionalCost extends StatelessWidget {
  const OrderAdditionalCost({required this.order, super.key});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            // The caption is null only on a charge the server sent with no category at all,
            // which its own validation refuses — but a blank line under a number is worse than
            // naming the thing generically, so there is a fallback.
            order.additionalCostCaption ?? 'مبلغ إضافي',
            // Two lines, because «أخرى» puts the clerk's own sentence here and a sentence is
            // longer than a category.
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: context.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          // Signed, like the discount facing it, so the direction is read before the number is.
          // **Not in the error colour**: this is a charge the customer owes, and red beside it
          // would warn about the wrong thing.
          '+ ${order.additionalCost.grouped}',
          textDirection: TextDirection.ltr,
          style: context.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.primary,
          ),
        ),
      ],
    );
  }
}
