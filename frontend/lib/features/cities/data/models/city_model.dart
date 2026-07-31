import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/features/cities/domain/entities/city.dart';

part 'city_model.freezed.dart';
part 'city_model.g.dart';

/// The wire shape of a city, and the only thing that knows the API's key names.
///
/// **Why this exists when it looks identical to [City].** It is the seam. When the backend
/// renames `delivery_price`, exactly one line changes — the `@JsonKey` below — and nothing in
/// `domain/` or `presentation/` is touched. Without the seam, a rename in Laravel becomes a
/// find-and-replace through every widget that ever read the field, and the compiler cannot
/// tell you which ones you missed.
@freezed
abstract class CityModel with _$CityModel {
  const factory CityModel({
    required int id,
    required String name,
    @JsonKey(name: 'is_region_required') required bool isRegionRequired,
    @JsonKey(name: 'delivery_price') String? deliveryPrice,
    @JsonKey(name: 'darb_branch') String? darbBranch,
    double? latitude,
    double? longitude,
    @JsonKey(name: 'regions_count') int? regionsCount,
    List<RegionModel>? regions,
  }) = _CityModel;

  const CityModel._();

  factory CityModel.fromJson(Map<String, dynamic> json) => _$CityModelFromJson(json);

  City toEntity() => City(
    id: id,
    name: name,
    isRegionRequired: isRegionRequired,
    deliveryPrice: deliveryPrice,
    darbBranch: darbBranch,
    latitude: latitude,
    longitude: longitude,
    regionsCount: regionsCount,
    regions: regions?.map((region) => region.toEntity()).toList(growable: false),
  );
}

@freezed
abstract class RegionModel with _$RegionModel {
  const factory RegionModel({
    required int id,
    @JsonKey(name: 'city_id') required int cityId,
    required String name,
    String? code,
    @JsonKey(name: 'darb_branch') String? darbBranch,
    double? latitude,
    double? longitude,
  }) = _RegionModel;

  const RegionModel._();

  factory RegionModel.fromJson(Map<String, dynamic> json) => _$RegionModelFromJson(json);

  Region toEntity() => Region(
    id: id,
    cityId: cityId,
    name: name,
    code: code,
    darbBranch: darbBranch,
    latitude: latitude,
    longitude: longitude,
  );
}
