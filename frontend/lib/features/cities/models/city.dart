import 'package:freezed_annotation/freezed_annotation.dart';

part 'city.freezed.dart';
part 'city.g.dart';

/// A place an order can be delivered to.
///
/// **One class, not an entity plus a model.** The pair used to exist so a rename on the backend
/// could not reach the widgets — but `@JsonKey` already is that seam. When `delivery_price`
/// becomes something else, exactly one annotation below changes and no widget is touched,
/// which is the whole benefit the second class was carrying.
@freezed
abstract class City with _$City {
  const factory City({
    required int id,
    required String name,

    /// Whether the customer *must* pick a region — not whether the city has any.
    @JsonKey(name: 'is_region_required') required bool isRegionRequired,

    /// Money as a string, exactly as the API sends it ("15.00"). Never a `double`: a price is
    /// added to an order total, and binary floating point does not add money correctly.
    /// `null` means no rate has been agreed yet — which is not the same as free.
    @JsonKey(name: 'delivery_price') String? deliveryPrice,

    /// The شركة درب branch that serves this city.
    @JsonKey(name: 'darb_branch') String? darbBranch,

    double? latitude,
    double? longitude,

    /// Present on the list endpoint.
    @JsonKey(name: 'regions_count') int? regionsCount,

    /// Present when a single city was fetched.
    List<Region>? regions,
  }) = _City;

  const City._();

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);

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
    @JsonKey(name: 'city_id') required int cityId,
    required String name,

    /// شركة درب's zone code, e.g. `s18`. Theirs, so it is displayed and never generated.
    String? code,
    @JsonKey(name: 'darb_branch') String? darbBranch,
    double? latitude,
    double? longitude,
  }) = _Region;

  const Region._();

  factory Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);

  bool get hasPin => latitude != null && longitude != null;
}
