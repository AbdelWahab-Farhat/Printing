import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/cities/presentation/widgets/place_card.dart';
import 'package:dayaa/features/shipping_companies/models/shipping_company.dart';
import 'package:flutter/material.dart';

/// One carrier, drawn like every other reference row in the app.
///
/// A retired company is shown rather than hidden, and marked «متوقفة» — the list is the record
/// of who we have dealt with, and an order from last year still names one of these. What being
/// retired changes is that it is not offered on a new dispatch, and that is a different screen.
///
/// The one a dispatch *opens* on is marked «الافتراضية», so which company that is can be read
/// off the list rather than found by opening each row in turn.
class ShippingCompanyCard extends StatelessWidget {
  const ShippingCompanyCard({required this.company, this.onTap, super.key});

  final ShippingCompany company;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PlaceCard(
      title: company.name,
      subtitle: company.subtitle,
      icon: AppIcons.warehouse,
      iconTone: company.isActive ? PlaceTone.delivery : PlaceTone.muted,
      // Retired first: it is the badge that says what the picker will do with this row. The
      // two cannot both be true of a live company — a carrier we stopped dealing with is not
      // the one a dispatch opens on, and the server does not let the flag survive being
      // switched off.
      badge: !company.isActive
          ? 'متوقفة'
          : company.isDefault
          ? 'الافتراضية'
          : null,
      badgeTone: company.isActive ? PlaceTone.delivery : PlaceTone.muted,
      onTap: onTap,
    );
  }
}
