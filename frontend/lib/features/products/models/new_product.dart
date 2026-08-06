import 'package:freezed_annotation/freezed_annotation.dart';

part 'new_product.freezed.dart';
part 'new_product.g.dart';

/// A product about to be saved — what the form collected, in the shape the API accepts.
///
/// Separate from [Product] because the two are genuinely different things: a `Product` has an
/// id, a code, timestamps and server-computed labels, none of which exist yet. Making the form
/// fill a half-empty `Product` would mean every reader downstream having to wonder which of its
/// fields are real.
///
/// The body is generated rather than assembled in the repository for one reason:
/// `variants[].price_tiers[]` as a hand-written `Map` literal is forty lines reachable only
/// through Dio, where here it is a pure function `flutter test` asserts on directly.
///
/// **`fromJson` is generated too, and never called — do not "tidy it away".** With
/// `@Freezed(toJson: true, fromJson: false)` the generator stops recognising the nested types
/// as serializable and emits `'variants': instance.variants`: Dart objects where the wire needs
/// maps. The request goes out malformed and nothing in the app notices. A few lines of unused
/// generated code is the price of the nesting working at all.
///
/// Money stays a `String` all the way through. Nothing here parses a price.
@freezed
abstract class NewProduct with _$NewProduct {
  const factory NewProduct({
    /// Omitted by this app: the server generates it from the name and the product's code, so
    /// nobody has to invent `shipping-bag` for a product called أكياس الشحن. Kept on the model
    /// because the API still accepts a deliberate one from an import.
    @JsonKey(includeIfNull: false) String? slug,
    required String name,

    /// Omitted from the body when absent — the API's rule is `nullable`, and sending `null`
    /// says something slightly different from not mentioning it.
    @JsonKey(includeIfNull: false) String? description,

    @JsonKey(includeIfNull: false) List<String>? features,

    required String category,
    @JsonKey(name: 'pricing_unit') required String pricingUnit,
    @JsonKey(name: 'pricing_mode') required String pricingMode,

    /// A decimal string like `'100'`, already normalised out of whatever the keyboard produced.
    @JsonKey(name: 'min_order_quantity') required String minOrderQuantity,

    /// Sizes. Empty is allowed: a quote-only product can exist before its sizes are known.
    @Default(<NewProductVariant>[]) List<NewProductVariant> variants,
  }) = _NewProduct;

  factory NewProduct.fromJson(Map<String, dynamic> json) => _$NewProductFromJson(json);
}

/// One size, and the price list under it.
@freezed
abstract class NewProductVariant with _$NewProductVariant {
  const factory NewProductVariant({
    /// **The id of a size that already exists, and the reason editing works at all.**
    ///
    /// `PUT /products/{id}` makes the list match exactly: a size carrying an id is updated in
    /// place, one without is created, and one left out is *removed*. Sending an existing size
    /// without its id would therefore delete it and create a lookalike — and the order lines
    /// pointing at the old row would be pointing at a deleted size.
    ///
    /// Null when creating, and omitted from the body then.
    @JsonKey(includeIfNull: false) int? id,

    required String label,

    /// Strings, not `int`s, and deliberately.
    ///
    /// `٢٥` is what a Libyan keyboard produces and `int.tryParse('٢٥')` is null. Parsing in the
    /// page would drop the dimension silently — the server accepts a null width, so nothing
    /// would complain and nobody would find out. Held as text here, normalised in
    /// [CreateProduct], which is the one file that converts anything.
    @JsonKey(name: 'width_cm', includeIfNull: false) int? widthCm,

    @JsonKey(name: 'height_cm', includeIfNull: false) int? heightCm,

    @JsonKey(name: 'price_tiers') @Default(<NewPriceTier>[]) List<NewPriceTier> priceTiers,
  }) = _NewProductVariant;

  factory NewProductVariant.fromJson(Map<String, dynamic> json) =>
      _$NewProductVariantFromJson(json);
}

/// "This many or more, at this price."
@freezed
abstract class NewPriceTier with _$NewPriceTier {
  const factory NewPriceTier({
    @JsonKey(name: 'min_quantity') required String minQuantity,
    @JsonKey(name: 'unit_price') required String unitPrice,
  }) = _NewPriceTier;

  factory NewPriceTier.fromJson(Map<String, dynamic> json) => _$NewPriceTierFromJson(json);
}
