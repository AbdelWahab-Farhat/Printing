import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/register_card.dart';
import 'package:dayaa/features/vendors/models/vendor.dart';
import 'package:flutter/material.dart';

/// One supplier in the list.
///
/// The same [RegisterCard] the customers and the investors are drawn in, in the blue accent;
/// what belongs to a supplier is the second column — who we talk to there.
///
/// A retired supplier is shown rather than hidden, and marked «متوقف»: this list is the record
/// of who we have bought from, and a purchase order from last year still names one of them. What
/// being retired changes is that it is not offered on a new order, which is the picker's
/// business rather than this list's.
class VendorCard extends StatelessWidget {
  const VendorCard({required this.vendor, this.onTap, super.key});

  final Vendor vendor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return RegisterCard(
      title: vendor.name,
      // The server does not give a supplier a code of its own, so the row is quoted by its id —
      // which is what a purchase order names it by anyway.
      code: 'V${vendor.id}',
      icon: AppIcons.vendors,
      tone: vendor.isActive ? RegisterTone.vendors : RegisterTone.muted,
      badge: vendor.isActive ? null : 'متوقف',
      onTap: onTap,
      fields: [
        RegisterField(
          label: 'رقم الهاتف',
          value: vendor.phone,
          valueDirection: TextDirection.ltr,
        ),
        RegisterField(
          label: 'المسؤول',
          // A supplier with nobody named is a company we ring rather than a person we ask for,
          // and «–» says that in the width the column has.
          value: (vendor.contactPerson?.isEmpty ?? true) ? '–' : vendor.contactPerson!,
        ),
      ],
    );
  }
}
