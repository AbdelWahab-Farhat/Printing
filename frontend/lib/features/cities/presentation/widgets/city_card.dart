import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/cities/presentation/widgets/place_card.dart';
import 'package:flutter/material.dart';

/// One place on the delivery map, as design 2b draws it.
///
/// Everything on it is read off the model — [City.priceLabel], [City.subtitle],
/// [City.isOfficePickup] — so the rule that a branch is free, or that no agreed rate is words
/// rather than a zero, lives in one testable place instead of in a widget.
///
/// A row is tappable only when it leads somewhere: a city with regions opens them. A branch has
/// none, and a city nobody has mapped yet has none either, so those rows draw without a chevron
/// and do not respond — a row that opens an empty screen is worse than a row that does nothing.
class CityCard extends StatelessWidget {
  const CityCard({required this.city, this.onTap, super.key});

  final City city;

  /// Called only when [City.hasRegions]; ignored otherwise.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isPickup = city.isOfficePickup;

    return PlaceCard(
      title: city.name,
      subtitle: city.subtitle,
      icon: isPickup ? AppIcons.officePickup : AppIcons.mapPin,
      iconTone: isPickup ? PlaceTone.pickup : PlaceTone.delivery,
      badge: city.priceLabel,
      badgeTone: switch (city) {
        City(isOfficePickup: true) => PlaceTone.free,
        City(hasDeliveryPrice: true) => PlaceTone.delivery,
        // Nobody has agreed a rate. Muted, so it does not read as an offer.
        _ => PlaceTone.muted,
      },
      onTap: city.hasRegions ? onTap : null,
    );
  }
}
