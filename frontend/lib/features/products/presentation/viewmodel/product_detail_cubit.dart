import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/models/pricing_unit.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/usecases/get_product.dart';
import 'package:dayaa/features/products/usecases/set_product_stock_unit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_detail_cubit.freezed.dart';
part 'product_detail_state.dart';

/// One product, everything about it.
///
/// Parameterised by the product, like every other screen that is *about* one record: the id is a
/// construction argument rather than something the Cubit is told afterwards and might be asked
/// for twice with two different answers.
///
/// **One write, and it needed no new state.** Declaring what the warehouse counts this product
/// in answers with the whole product refreshed, so the change lands as a `loaded` like any other
/// — there is no `isChanging`, no optimistic copy and no second stream. Stopping a product and
/// editing its prices are still endpoints this screen does not call.
class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit({
    required int productId,
    required GetProduct getProduct,
    required SetProductStockUnit setStockUnit,
  }) : _productId = productId,
       _getProduct = getProduct,
       _setStockUnit = setStockUnit,
       super(const ProductDetailState.loading());

  final int _productId;
  final GetProduct _getProduct;
  final SetProductStockUnit _setStockUnit;

  Future<void> load() async {
    // Only from nothing: pulling to refresh a product somebody is reading must not blank it to
    // a spinner and lose their place in a long price list.
    if (state.product == null) emit(const ProductDetailState.loading());

    final result = await _getProduct(_productId);

    // The screen may have been popped while the request was in flight, and emitting into a
    // closed Cubit throws.
    if (isClosed) return;

    emit(result.fold((f) => ProductDetailState.failure(f), (p) => ProductDetailState.loaded(p)));
  }

  /// Declares what the warehouse counts this product in.
  ///
  /// **No reload afterwards.** The endpoint answers with the whole product resource, already
  /// cascaded to every warehouse balance and cost batch for its variants, so a follow-up `load()`
  /// would be a second request for something this app has already been handed.
  ///
  /// Answers with the failure so the screen can say why nothing changed; `null` means it did. A
  /// refusal leaves the state alone rather than replacing a product somebody is reading with an
  /// error page — the message belongs in a snackbar over the product it is about.
  Future<Failure?> setStockUnit(PricingUnit unit) async {
    final result = await _setStockUnit(_productId, unit);

    // The screen may have been popped while the request was in flight, and emitting into a
    // closed Cubit throws.
    if (isClosed) return null;

    return result.fold<Failure?>((failure) => failure, (product) {
      emit(ProductDetailState.loaded(product));

      return null;
    });
  }
}
