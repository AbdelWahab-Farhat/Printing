part of 'product_detail_cubit.dart';

/// Everything the product detail screen can be, and nothing it cannot.
///
/// Three cases, not four: there is no `changing`, and the one write this screen does needs none.
/// [ProductDetailCubit.setStockUnit] is answered with the whole product refreshed, so it lands as
/// an ordinary `loaded`; a refusal is handed back to the caller and never emitted, because
/// replacing a product somebody is reading with an error page is not what "that did not work"
/// should look like. When stopping a product lands, a `changing` case may arrive with it —
/// carrying the product, so nothing is blanked while a request is in flight.
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
