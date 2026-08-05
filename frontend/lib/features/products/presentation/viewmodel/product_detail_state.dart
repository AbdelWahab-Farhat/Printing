part of 'product_detail_cubit.dart';

/// Everything the product detail screen can be, and nothing it cannot.
///
/// Three cases, not four: there is no `changing`, because this screen does not write. When
/// stopping a product lands, that case arrives with it — carrying the product, so the screen
/// keeps showing it while the request is in flight rather than blanking what somebody is reading.
@freezed
sealed class ProductDetailState with _$ProductDetailState {
  const factory ProductDetailState.loading() = ProductDetailLoading;

  const factory ProductDetailState.loaded(Product product) = ProductDetailLoaded;

  const factory ProductDetailState.failure(Failure failure) = ProductDetailFailure;
}

extension ProductDetailStateX on ProductDetailState {
  /// The product, whenever there is one to show.
  ///
  /// A failure keeps none: a refresh that fails has nothing older to fall back on here, because
  /// the only way to reach this screen loads it fresh. The screen shows the server's message
  /// and a retry.
  Product? get product => switch (this) {
    ProductDetailLoaded(:final product) => product,
    _ => null,
  };
}
