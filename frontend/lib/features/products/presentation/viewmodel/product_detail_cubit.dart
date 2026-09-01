import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/usecases/get_product.dart';
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
/// **Read-only, and it became so on purpose.** It used to carry one write — declaring what the
/// warehouse counted this product in — and that endpoint no longer exists: a pile is not one
/// product's, so «كيس شحن سادة 25*35» and «كيس شحن مطبوع 25*35» cannot be allowed to disagree
/// about how the heap they share is counted. The unit moved onto the «صنف مخزني», and so did its
/// control: `PATCH /stock-items/{id}/unit`, on the stock-item screen, where the thing being
/// counted is what is on the screen. Stopping a product and editing its prices are still
/// endpoints this screen does not call.
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

  /// Takes a reading the caller already has — the form's saved copy, straight from the server.
  ///
  /// The alternative was [load], which is a request for something this screen was just handed:
  /// the form posts the product and the server answers with the whole record, prices and all.
  /// A pull still re-reads, and so does the retry on the failure view.
  void show(Product product) {
    if (isClosed) return;

    emit(ProductDetailState.loaded(product));
  }
}
