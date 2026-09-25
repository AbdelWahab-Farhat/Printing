import 'package:freezed_annotation/freezed_annotation.dart';

part 'shop.freezed.dart';
part 'shop.g.dart';

/// متجرٌ من متاجر العميل — ما يرسمه «متاجري» وصفحة المتجر، وما تختاره السلة وجهةً للطلبية.
///
/// **حقول نموذج الموظفين الأربعة:** الاسم، ومجال العمل، والمدينة والمنطقة، ورابط الصفحة. المُعرِّفات
/// لما يُختار في النموذج، والأسماء لما يُرسم — فلا طلبَ ثانياً لخريطة التوصيل ولا لقائمة المجالات.
///
/// **ليس `CustomerShop` الذي في `auth/models/`.** ذاك سطرٌ في بطاقة «حسابي» بلا مُعرِّف، وهذا ما يُعدَّل
/// ويُحذف ويُختار.
@freezed
abstract class Shop with _$Shop {
  const factory Shop({
    required int id,
    required String name,
    @JsonKey(name: 'city_id') required int cityId,

    /// `null` حين تُخرَج المدينة من الخريطة بعد تسجيل المتجر — المُعرِّف يبقى، والاسم لا يُخترع.
    @JsonKey(name: 'city_name') String? cityName,
    @JsonKey(name: 'region_id') int? regionId,
    @JsonKey(name: 'region_name') String? regionName,

    /// مجال العمل، أو `null` لمتجرٍ سُجّل بلا مجال — وذلك جوابٌ حقيقي لا نقص.
    @JsonKey(name: 'business_field_id') int? businessFieldId,
    @JsonKey(name: 'business_field_name') String? businessFieldName,
    @JsonKey(name: 'page_url') String? pageUrl,
  }) = _Shop;

  const Shop._();

  factory Shop.fromJson(Map<String, dynamic> json) => _$ShopFromJson(json);

  /// «بنغازي · الكيش»، أو ما عند المتجر من نصفيها.
  String get place => [?cityName, ?regionName].join(' · ');

  /// مجاله كما يعرضه منتقي النموذج، ليبقى مختاراً ولو أُوقف بعد تسجيل المتجر.
  BusinessField? get businessField => switch ((businessFieldId, businessFieldName)) {
    (final int id, final String name) => BusinessField(id: id, name: name),
    _ => null,
  };
}

/// مجال عمل — «ملابس وأحذية»، «عطور». يختار منه العميل لمتجره كما يختار الموظف.
@freezed
abstract class BusinessField with _$BusinessField {
  const factory BusinessField({required int id, required String name}) = _BusinessField;

  factory BusinessField.fromJson(Map<String, dynamic> json) => _$BusinessFieldFromJson(json);
}
