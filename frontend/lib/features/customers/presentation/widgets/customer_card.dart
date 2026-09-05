import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/core/widgets/register_card.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:flutter/material.dart';

/// One customer in the list.
///
/// Name, code and phone — the three things a customer is looked up by, so all three are on the
/// card rather than one screen deeper. The shape is [RegisterCard], shared with the suppliers
/// and the investors beside it under «الجهات»; what belongs to a customer is the teal and the
/// second column.
class CustomerCard extends StatelessWidget {
  const CustomerCard({required this.customer, this.onTap, super.key});

  final Customer customer;
  final VoidCallback? onTap;

  /// How much business this customer does.
  ///
  /// **The heading changes with the answer.** On «الأقدم طلباً» the list is sorted by the silence
  /// and the row is read for it, so the column says «آخر طلبية» and shows «منذ شهرين»; putting
  /// that under «الطلبيات» would read as a quantity of orders. Everywhere else it is the count.
  ///
  /// **Zero says so in words rather than going quiet.** A row that shows nothing at zero teaches
  /// the eye that the slot is noise, and then «١٧ طلبية» on the row below it does not get read
  /// either. «لا طلبيات» is also the one thing on this card that answers «هل هذا عميل جديد؟»
  /// without opening him.
  ///
  /// **A count nobody sent is a dash, not a nought.** A reader without `orders.view` is not sent
  /// the key at all, and neither is the response to saving the form — so the column keeps its
  /// place, and says it was not told.
  RegisterField get _orders {
    if (customer.lastOrderAgo case final silence?) {
      return RegisterField(label: 'آخر طلبية', value: silence);
    }

    return RegisterField(
      label: 'الطلبيات',
      value: switch (customer.ordersCount) {
        null => '–',
        // Not «٠ طلبية»: a numeral standing for nothing is read as a number before it is read as
        // an absence, and Arabic has a shorter way to say it.
        0 => 'لا طلبيات',
        final count => '${count.grouped} طلبية',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return RegisterCard(
      title: customer.name,
      code: customer.code,
      icon: AppIcons.person,
      tone: customer.isActive ? RegisterTone.customers : RegisterTone.muted,
      badge: customer.isActive ? null : 'موقوف',
      onTap: onTap,
      fields: [
        RegisterField(
          label: 'رقم الهاتف',
          value: customer.phone,
          // A Libyan number reads left-to-right even inside this RTL card.
          valueDirection: TextDirection.ltr,
        ),
        _orders,
      ],
    );
  }
}
