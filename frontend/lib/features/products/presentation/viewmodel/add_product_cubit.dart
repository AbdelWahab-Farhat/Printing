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
  /// **A [Failure.network] here is not safe to retry blindly, and that changed on purpose.**
  ///
  /// This screen used to collect the slug, which is unique in the database, so a request that
  /// reached the server before the connection dropped came back as a 422 on the retry rather
  /// than a second product. Now the server generates the slug — nobody should have to invent a
  /// unique Latin string for أكياس الشحن — and with it went the accidental duplicate guard: a
  /// product has no other natural key, so two POSTs are two products.
  ///
  /// The screen still offers «أعد المحاولة», because the alternative — refusing to retry a
  /// request that probably never arrived — is worse far more often. What it costs when it does
  /// duplicate is one product to deactivate, which is visible in the catalogue immediately.
  Future<void> submit({
    required String name,
    String? description,
    List<String> features = const [],
    required String category,
    required String pricingUnit,
    required String pricingMode,
    required String minOrderQuantity,
    List<DraftVariant> variants = const [],
  }) async {
    // Ignored rather than queued: a second tap while the first is in flight is a second POST,
    // and with the slug generated server-side that is now a second *product* rather than a 422.
    if (state.isSubmitting) return;

    emit(const AddProductState.submitting());

    final result = await _createProduct(
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
