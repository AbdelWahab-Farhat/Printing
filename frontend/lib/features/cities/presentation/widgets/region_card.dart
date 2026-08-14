import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/cities/presentation/widgets/place_card.dart';
import 'package:flutter/material.dart';

/// One neighbourhood inside a city — the same card as a city's, one level down.
///
/// The pill holds the شركة درب zone code rather than a price, because **a region has no price**:
/// delivery is priced per city, and the region only says where inside it. Keeping the pill in
/// place with a different fact in it is what makes the two screens read as one map instead of
/// two lists — and the code is muted, because it is a routing detail, not an offer.
///
/// It does not lead anywhere: a region is the end of the map. So there is no chevron, and no
/// tap that would do nothing.
class RegionCard extends StatelessWidget {
  const RegionCard({required this.region, super.key});

  final Region region;

  @override
  Widget build(BuildContext context) {
    return PlaceCard(
      title: region.name,
      subtitle: region.subtitle,
      icon: AppIcons.mapPin,
      iconTone: PlaceTone.delivery,
      // شركة درب's own code, displayed and never generated — so a row with none shows none.
      badge: region.hasCode ? region.code : null,
    );
  }
}
