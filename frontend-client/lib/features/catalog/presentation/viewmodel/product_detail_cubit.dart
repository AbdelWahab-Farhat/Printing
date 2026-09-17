import 'dart:async';

import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/usecases/get_product.dart';
import 'package:dayaa_client/features/catalog/usecases/quote_price.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_detail_cubit.freezed.dart';
part 'product_detail_state.dart';

/// The ViewModel for one product, and for the order being composed against it.
///
/// **Every price on this screen comes from the server.** Picking a size or changing the quantity
/// re-quotes; nothing here multiplies a unit price by a number. That is not caution about
/// arithmetic — it is that the tier rules live in one place, and a copy of them in this app
/// would be the one that disagrees with the invoice.
class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit({required GetProduct getProduct, required QuotePrice quote})
    : _getProduct = getProduct,
      _quote = quote,
      super(const ProductDetailState.loading());

  final GetProduct _getProduct;
  final QuotePrice _quote;

  /// Bumped on every quote so a slow answer to an old quantity cannot overwrite a newer one —
  /// the classic race on a screen where a stepper fires a request per tap.
  int _quoteToken = 0;

  Future<void> load(int productId) async {
    emit(const ProductDetailState.loading());

    final result = await _getProduct(productId);

    if (isClosed) return;

    emit(
      result.fold(ProductDetailState.failure, (product) {
        final variant = product.variants.isEmpty ? null : product.variants.first;

        return ProductDetailState.loaded(
          product: product,
          selectedVariantId: variant?.id,
          quantity: product.minOrderQuantity ?? '1',
        );
      }),
    );

    // The opening quote, so the total is on screen before the customer touches anything.
    await refreshQuote();
  }

  void selectVariant(int variantId) {
    final loaded = _loaded;
    if (loaded == null || loaded.selectedVariantId == variantId) return;

    emit(loaded.copyWith(selectedVariantId: variantId, quote: null));

    unawaited(refreshQuote());
  }

  void setQuantity(String quantity) {
    final loaded = _loaded;
    if (loaded == null || loaded.quantity == quantity) return;

    emit(loaded.copyWith(quantity: quantity, quote: null));

    unawaited(refreshQuote());
  }

  /// Re-asks the server for the price of what is currently selected.
  Future<void> refreshQuote() async {
    final loaded = _loaded;
    final variantId = loaded?.selectedVariantId;

    if (loaded == null || variantId == null) return;
    // A product sold on request has no tiers to quote against — the screen draws «اطلب عرض سعر»
    // instead of a total.
    if (!loaded.product.hasListedPrices) return;

    final token = ++_quoteToken;

    emit(loaded.copyWith(isQuoting: true));

    final result = await _quote(
      productId: loaded.product.id,
      variantId: variantId,
      quantity: loaded.quantity,
    );

    if (isClosed) return;

    // A stale answer — the customer changed the size or the quantity while this was in flight.
    // Dropping it is what stops the total flickering back to a number nobody asked for.
    if (token != _quoteToken) return;

    final current = _loaded;
    if (current == null) return;

    emit(
      result.fold(
        (failure) => current.copyWith(isQuoting: false, quoteFailure: failure),
        (quote) => current.copyWith(isQuoting: false, quote: quote, quoteFailure: null),
      ),
    );
  }

  ProductDetailLoaded? get _loaded => switch (state) {
    final ProductDetailLoaded loaded => loaded,
    _ => null,
  };
}
