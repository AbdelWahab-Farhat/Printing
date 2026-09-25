part of 'product_detail_cubit.dart';

/// Everything the product screen can be.
@freezed
sealed class ProductDetailState with _$ProductDetailState {
  const factory ProductDetailState.loading() = ProductDetailLoading;

  const factory ProductDetailState.loaded({
    required Product product,

    /// Which size is chosen. Null only for a product with no sizes at all — which the catalogue
    /// should not contain, but a screen that crashed on one would be worse than one that draws
    /// no price.
    int? selectedVariantId,

    /// A decimal string, as everything numeric in this app is. Starts at the product's minimum
    /// order quantity: the commonest correct answer, and it saves the customer discovering the
    /// floor by being refused.
    @Default('1') String quantity,

    /// **جواب الخادم، والمصدر الوحيد لأي سعرٍ على هذه الشاشة.** يبقى السابق ما دام الجديد في
    /// الطريق ([isQuoting])، والشاشة تخفّته بدل أن تمحوه، فلا يرمش السعر مع كل ضغطةٍ على + أو −.
    /// ويُمحى حين يرفض الخادم الكمية الجديدة: إجماليٌّ لكميةٍ أخرى بجانب الرفض رقمٌ كاذب.
    PriceQuote? quote,

    @Default(false) bool isQuoting,

    /// A quote that failed. Kept apart from the product's own failure: the product is on screen
    /// and readable, and only the price is missing.
    Failure? quoteFailure,
  }) = ProductDetailLoaded;

  const factory ProductDetailState.failure(Failure failure) = ProductDetailFailure;
}

extension ProductDetailStateX on ProductDetailState {
  /// The size currently chosen, resolved from the product rather than stored twice.
  ProductVariant? get selectedVariant => switch (this) {
    ProductDetailLoaded(:final product, :final selectedVariantId) => () {
      for (final variant in product.variants) {
        if (variant.id == selectedVariantId) return variant;
      }

      return null;
    }(),
    _ => null,
  };

  /// Whether what is in the quantity field is something the basket may hold.
  ///
  /// **The keyboard is not where this is guaranteed.** `QuantityInputFormatter` refuses a lone
  /// «.» as it is typed, and that is the right place for it — a rule that can be enforced at the
  /// keystroke should be. But a formatter only ever sees one keystroke: it cannot tell a number
  /// that is finished from one that is half-written, and it is not the only road into this state.
  /// So the question is asked again where the line is actually made.
  ///
  /// `double.tryParse` draws exactly the wanted line. «.» is null — it is not a number, and the
  /// server says so too (`is_numeric('.')` is false) after a round trip nobody needed. «100.» is
  /// 100, so a trailing point is left alone: it is the only road to «100.5», and the server reads
  /// it as 100 as well.
  ///
  /// The product's own minimum is **not** checked here. That is the catalogue's rule, the server
  /// owns it, and it answers with the figure and the unit — a copy of it in this app would be the
  /// one that disagrees with the shop.
  bool get hasOrderableQuantity => switch (this) {
    ProductDetailLoaded(:final quantity) => isOrderableQuantity(quantity),
    _ => false,
  };

  /// هل يُنقص − شيئاً. عند الحد الأدنى لا — الخادم يرفض ما دونه — فيُرسم الزر معطّلاً.
  bool get canDecrease => switch (this) {
    ProductDetailLoaded(:final product, :final quantity) => switch (double.tryParse(quantity)) {
      final value? => value > product.quantityFloor,
      // حقلٌ فارغ: − يضع الحد الأدنى فيه.
      _ => true,
    },
    _ => false,
  };

  /// أين يقف إبهام السلايدر: الكمية نفسها محبوسةً بين طرفيه. كميةٌ مكتوبةٌ فوق آخره تضعه على
  /// آخره ولا تكسره، وحقلٌ فارغ يضعه على أوله.
  double get quantityOnSlider => switch (this) {
    ProductDetailLoaded(:final product, :final quantity) =>
      (double.tryParse(quantity) ?? product.quantityFloor)
          .clamp(product.quantityFloor, product.quantityCeiling)
          .toDouble(),
    _ => 0,
  };

  /// Whether to draw a total at all, or «اطلب عرض سعر» in its place.
  bool get showsPrice => switch (this) {
    ProductDetailLoaded(:final product) => product.hasListedPrices,
    _ => false,
  };
}
