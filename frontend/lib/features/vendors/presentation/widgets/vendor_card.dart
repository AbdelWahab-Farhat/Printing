import 'package:flutter/material.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/features/cities/presentation/widgets/place_card.dart';
import 'package:printing/features/vendors/models/vendor.dart';

/// One supplier, drawn like every other reference row in the app.
///
/// A retired supplier is shown rather than hidden, and marked «متوقف» — this list is the record
/// of who we have bought from, and a purchase order from last year still names one of them.
/// What being retired changes is that it is not offered on a new order, which is the picker's
/// business rather than this list's.
class VendorCard extends StatelessWidget {
  const VendorCard({required this.vendor, this.onTap, super.key});

  final Vendor vendor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return PlaceCard(
      title: vendor.name,
      // The person and the number on one line — what somebody reaching for this row is
      // reaching for.
      subtitle: vendor.contactLine,
      icon: AppIcons.vendors,
      iconTone: vendor.isActive ? PlaceTone.delivery : PlaceTone.muted,
      badge: vendor.isActive ? null : 'متوقف',
      badgeTone: PlaceTone.muted,
      onTap: onTap,
    );
  }
}
