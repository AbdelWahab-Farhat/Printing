import 'package:freezed_annotation/freezed_annotation.dart';

part 'city.freezed.dart';

/// A place an order can be delivered to.
///
/// A **domain entity**: no JSON, no `dio`, no `BuildContext`. It knows nothing about the API
/// that produced it, which is what lets the backend rename a key without the change reaching
/// a single widget — [CityModel] absorbs that, and this stays put.
@freezed
abstract class City with _$City {
  const factory City({
    required int id,
    required String name,

    /// Whether the customer *must* pick a region — not whether the city has any.
    required bool isRegionRequired,

    /// Money as a string, exactly as the API sends it ("15.00"). Never a `double`: a price is
    /// added to an order total, and binary floating point does not add money correctly.
    /// `null` means no rate has been agreed yet — which is not the same as free.
    String? deliveryPrice,

    /// The شركة درب branch that serves this city.
    String? darbBranch,

    double? latitude,
    double? longitude,

    /// Present on the list endpoint.
    int? regionsCount,

    /// Present when a single city was fetched.
    List<Region>? regions,
  }) = _City;

  const City._();

  /// A city nobody has agreed a rate for yet — the UI shows "يُحدد لاحقاً", not "0.00".
  bool get hasDeliveryPrice => deliveryPrice != null;

  /// Collecting in person: free, and the branch is the choice itself.
  bool get isOfficePickup => deliveryPrice == '0.00' && !isRegionRequired;

  bool get hasPin => latitude != null && longitude != null;
}

/// A neighbourhood inside a city.
@freezed
abstract class Region with _$Region {
  const factory Region({
    required int id,
    required int cityId,
    required String name,

    /// شركة درب's zone code, e.g. `s18`. Theirs, so it is displayed and never generated.
    String? code,
    String? darbBranch,
    double? latitude,
    double? longitude,
  }) = _Region;

  const Region._();

  bool get hasPin => latitude != null && longitude != null;
}
