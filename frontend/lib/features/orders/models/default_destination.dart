import 'package:dayaa/features/cities/models/city.dart';
import 'package:dayaa/features/customers/models/customer.dart';

/// Where «طلبية جديدة» starts, before anybody touches the city and region tiles.
///
/// **A starting place, never a decision.** Both tiles stay pickers; this only spares the clerk
/// choosing, on every order, the place the customer's record already names. In order:
///
/// 1. A chosen shop → that shop's city and region.
/// 2. No shop → the customer's own default address.
/// 3. Neither → nothing, as it was before the customer had an address.
///
/// A city that has since been deleted arrives as null, and a region is never kept without the
/// city it is in — so a dead address reads as no address rather than as half of one.
typedef DefaultDestination = ({City? city, Region? region});

DefaultDestination defaultDestinationFor(Customer customer, CustomerShop? shop) {
  final city = shop != null ? shop.city : customer.city;
  final region = shop != null ? shop.region : customer.region;

  return (city: city, region: city == null ? null : region);
}

/// Which shop chip is on when the form opens.
///
/// **None while the customer has an address of their own** — that address is the default the
/// record names, and preselecting a branch would quietly overrule it. Without one, a customer
/// with exactly one shop has that shop: it is the only place the record names. With several,
/// picking one would be a guess, so the form waits to be told.
CustomerShop? initialShopFor(Customer customer) {
  final shops = customer.shops ?? const <CustomerShop>[];

  if (customer.city != null || shops.length != 1) return null;

  return shops.single;
}
