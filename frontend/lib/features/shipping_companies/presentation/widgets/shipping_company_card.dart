import 'package:flutter/material.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/features/cities/presentation/widgets/place_card.dart';
import 'package:printing/features/shipping_companies/models/shipping_company.dart';

/// One carrier, drawn like every other reference row in the app.
///
/// A retired company is shown rather than hidden, and marked «متوقفة» — the list is the record
/// of who we have dealt with, and an order from last year still names one of these. What being
/// retired changes is that it is not offered on a new dispatch, and that is a different screen.
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
      badge: company.isActive ? null : 'متوقفة',
      badgeTone: PlaceTone.muted,
      onTap: onTap,
    );
  }
}
