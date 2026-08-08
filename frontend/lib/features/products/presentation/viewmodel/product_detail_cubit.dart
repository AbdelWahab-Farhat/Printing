import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/usecases/get_product.dart';

part 'product_detail_state.dart';
part 'product_detail_cubit.freezed.dart';

/// One product, everything about it.
///
/// Parameterised by the product, like every other screen that is *about* one record: the id is a
/// construction argument rather than something the Cubit is told afterwards and might be asked
/// for twice with two different answers.
///
/// **Read-only, and that is the whole class.** Stopping a product and editing its prices are
/// endpoints this screen does not call yet, so there is no `isChanging`, no optimistic copy and
/// no second stream — the shapes those need can arrive with the actions that need them.
class ProductDetailCubit extends Cubit<ProductDetailState> {
  ProductDetailCubit({required int productId, required GetProduct getProduct})
    : _productId = productId,
      _getProduct = getProduct,
      super(const ProductDetailState.loading());

  final int _productId;
  final GetProduct _getProduct;

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
}
