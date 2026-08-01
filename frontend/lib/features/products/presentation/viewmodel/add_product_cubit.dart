import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/products/models/product.dart';
import 'package:printing/features/products/usecases/create_product.dart';

part 'add_product_state.dart';
part 'add_product_cubit.freezed.dart';

/// The ViewModel for the "add a product" screen.
///
/// It talks to a use case, never to a repository or to Dio, and it holds no `BuildContext`.
/// It also holds **no draft**: the form owns its controllers, because those are widget-lifecycle
/// resources that must be disposed, and a Cubit is not a disposal mechanism.
class AddProductCubit extends Cubit<AddProductState> {
  AddProductCubit({required CreateProduct createProduct})
    : _createProduct = createProduct,
      super(const AddProductState.initial());

  final CreateProduct _createProduct;

  /// Sends the form.
  ///
  /// **On a [Failure.network] here, retrying is safe** — the same reason the add-customer screen
  /// gives. `slug` is unique in the database, not merely in validation, so a request that did
  /// reach the server before the connection dropped makes the retry a 422 rather than a second
  /// product. That is what makes «أعد المحاولة» an honest offer on this screen.
  Future<void> submit({
    required String slug,
    required String name,
    String? description,
    List<String> features = const [],
    required String category,
    required String pricingUnit,
    required String pricingMode,
    required String minOrderQuantity,
    List<DraftVariant> variants = const [],
  }) async {
    // Ignored rather than queued: a second tap while the first is in flight would be a second
    // POST, and the slug's uniqueness would turn it into a confusing 422.
    if (state.isSubmitting) return;

    emit(const AddProductState.submitting());

    final result = await _createProduct(
      slug: slug,
      name: name,
      description: description,
      features: features,
      category: category,
      pricingUnit: pricingUnit,
      pricingMode: pricingMode,
      minOrderQuantity: minOrderQuantity,
      variants: variants,
    );

    // The screen may have been popped while the request was in flight, and emitting into a
    // closed Cubit throws.
    if (isClosed) return;

    emit(result.fold(AddProductState.failure, AddProductState.success));
  }

  /// Clears a previous failure so an error under a field disappears as the user corrects it,
  /// rather than lingering until the next submit.
  void clearFailure() {
    if (state is AddProductFailure) emit(const AddProductState.initial());
  }
}
