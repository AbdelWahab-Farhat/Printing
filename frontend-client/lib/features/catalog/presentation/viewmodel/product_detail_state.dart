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

    /// **The server's answer, and the only source of a total on this screen.** Null while a
    /// fresh one is being fetched — the screen shows the previous figure dimmed rather than
    /// blanking, so the price does not flicker on every tap of the stepper.
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

  /// Whether to draw a total at all, or «اطلب عرض سعر» in its place.
  bool get showsPrice => switch (this) {
    ProductDetailLoaded(:final product) => product.hasListedPrices,
    _ => false,
  };
}
