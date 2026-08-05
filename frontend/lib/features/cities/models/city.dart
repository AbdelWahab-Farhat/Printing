import 'package:freezed_annotation/freezed_annotation.dart';

part 'city.freezed.dart';
part 'city.g.dart';

/// How an order reaches the customer from a place on the delivery map.
///
/// The server's enum, mirrored — not a boolean. A third arrangement is entirely plausible
/// (shipping abroad, a courier collecting from the workshop), and each is a different word for
/// the customer; a boolean would have to be replaced, a case can be added.
enum FulfilmentType {
  /// We take the order to the customer. Nearly every place on the map.
  @JsonValue('delivery')
  delivery,

  /// The customer collects it from one of our branches.
  @JsonValue('office_pickup')
  officePickup,
}

/// A place an order can be delivered to, or collected from.
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

    /// Delivered, or collected in person.
    ///
    /// `unknownEnumValue` rather than a throw: the server may grow a case before this build
    /// reaches the phone, and a row we cannot classify is still a place on the map. It defaults
    /// on the way in too, so a fixture written before this field existed still constructs.
    @JsonKey(name: 'fulfilment_type', unknownEnumValue: FulfilmentType.delivery)
    @Default(FulfilmentType.delivery)
    FulfilmentType fulfilmentType,

    /// The server's own Arabic for [fulfilmentType], so the app keeps no translation table.
    @JsonKey(name: 'fulfilment_type_label') String? fulfilmentTypeLabel,

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

  /// A city nobody has agreed a rate for yet — the UI shows "لم يُحدد", not "0.00".
  bool get hasDeliveryPrice => deliveryPrice != null;

  /// Collecting in person, because the server says so.
  ///
  /// It used to be `deliveryPrice == '0.00' && !isRegionRequired`, which is a guess that a free
  /// city with no regions satisfies just as well as a branch does. The server now stores the
  /// answer, so the app stops inferring it.
  bool get isOfficePickup => fulfilmentType == FulfilmentType.officePickup;

  bool get hasPin => latitude != null && longitude != null;

  /// Whether tapping this row has anywhere to go.
  bool get hasRegions => (regionsCount ?? 0) > 0;

  /// The pill at the end of the card.
  ///
  /// Three outcomes that must stay three: collecting is free, a delivery has an agreed rate, and
  /// a rate nobody has agreed yet is *not* a zero — printing "0.00 د.ل" there would read as
  /// free delivery to the one person who most needs to know it is not.
  String get priceLabel {
    if (isOfficePickup) return 'مجاني';

    return hasDeliveryPrice ? '$deliveryPrice د.ل' : 'لم يُحدد';
  }

  /// The line under the name, or `null` when there is nothing to put there.
  ///
  /// `null` rather than `''`, so the card draws one line instead of a second, empty one.
  String? get subtitle {
    if (isOfficePickup) return 'استلام ذاتي — بدون توصيل';

    final parts = [
      if (hasRegions) '$regionsCount منطقة',
      if (darbBranch != null && darbBranch!.isNotEmpty) darbBranch!,
    ];

    return parts.isEmpty ? null : parts.join(' · ');
  }
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

  /// The line under the name — which شركة درب branch routes a parcel here.
  ///
  /// A region carries no price of its own: delivery is priced per city, so the pill that holds
  /// money on a city card holds the zone code here instead. `null` when the map has neither.
  String? get subtitle =>
      darbBranch != null && darbBranch!.isNotEmpty ? 'فرع $darbBranch' : null;

  bool get hasCode => code != null && code!.isNotEmpty;
}
