import 'package:freezed_annotation/freezed_annotation.dart';

part 'city.freezed.dart';
part 'city.g.dart';

/// A neighbourhood inside a city.
///
/// Three fields, and that is the whole resource. Which carrier serves this place is an
/// arrangement between the shop and them — see `ClientRegionResource`.
@freezed
abstract class Region with _$Region {
  const factory Region({
    required int id,
    @JsonKey(name: 'city_id') required int cityId,
    required String name,
  }) = _Region;

  factory Region.fromJson(Map<String, dynamic> json) => _$RegionFromJson(json);
}

/// Somewhere an order can be sent.
///
/// **[deliveryPrice] is null when no rate has been agreed, which is not «free».** A city that
/// delivers for nothing sends `"0.00"`, and the two have to be drawn differently or somebody is
/// quoted a price the shop never promised.
@freezed
abstract class City with _$City {
  const factory City({
    required int id,
    required String name,

    /// The value for logic, and the Arabic beside it. The label travels with the value so this
    /// app keeps no translation table it would then have to keep in step with the business.
    @JsonKey(name: 'fulfilment_type') String? fulfilmentType,
    @JsonKey(name: 'fulfilment_type_label') String? fulfilmentTypeLabel,

    /// **The boolean the order screen branches on**, decided on the server — so the app never
    /// has to know which enum case means «they collect it».
    @JsonKey(name: 'is_office_pickup') @Default(false) bool isOfficePickup,

    /// Whether the picker may let the customer past without choosing a neighbourhood.
    @JsonKey(name: 'is_region_required') @Default(false) bool isRegionRequired,

    /// A decimal string, like every amount in this app. Null means no rate agreed.
    @JsonKey(name: 'delivery_price') String? deliveryPrice,

    @Default(<Region>[]) List<Region> regions,
  }) = _City;

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
}

extension CityX on City {
  /// Whether the customer must choose a region before the order can be placed.
  ///
  /// **A city that requires one but has none listed does not block the order**, because that is
  /// the shop's data being incomplete and not the customer's mistake — and a picker with an
  /// empty required list is a screen nobody can get past.
  bool get needsRegion => isRegionRequired && regions.isNotEmpty;

  /// Null means no rate has been agreed, not free — so this is deliberately not a `?? '0'`.
  bool get hasAgreedPrice => deliveryPrice != null;
}
