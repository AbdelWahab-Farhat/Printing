import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/products/models/product_category.dart';
import 'package:printing/features/products/usecases/save_product_category.dart';

part 'save_product_category_state.dart';
part 'save_product_category_cubit.freezed.dart';

/// The ViewModel for the sheet that adds or renames a catalogue heading.
///
/// It talks to a use case, never to a repository or to Dio, and it holds no `BuildContext`.
class SaveProductCategoryCubit extends Cubit<SaveProductCategoryState> {
  SaveProductCategoryCubit({required SaveProductCategory saveCategory})
    : _saveCategory = saveCategory,
      super(const SaveProductCategoryState.initial());

  final SaveProductCategory _saveCategory;

  /// Adds when [categoryId] is null, renames when it is not.
  ///
  /// One method for both, because the form, the validation and the 422 mapping are identical —
  /// the only difference is which request goes out.
  ///
  /// **Retrying after a [Failure.network] is safe here**, which is not true of every create:
  /// the name is unique in the database, so a request that did land before the connection
  /// dropped turns the retry into a readable 422 rather than a second «أكياس».
  Future<void> submit({
    int? categoryId,
    required String name,
    String? description,
    int sortOrder = 0,
    bool isActive = true,
  }) async {
    // Ignored rather than queued: a second tap while the first request is in flight would be a
    // second POST, and the sheet has already moved on by the time it answers.
    if (state.isSubmitting) return;

    emit(const SaveProductCategoryState.submitting());

    final result = await _saveCategory(
      categoryId: categoryId,
      name: name,
      description: description,
      sortOrder: sortOrder,
      isActive: isActive,
    );

    // The sheet may have been closed while the request was in flight, and emitting into a
    // closed Cubit throws.
    if (isClosed) return;

    emit(
      result.fold(
        SaveProductCategoryState.failure,
        SaveProductCategoryState.success,
      ),
    );
  }

  /// Clears a previous failure so the error under the field disappears as soon as the user
  /// starts correcting it, rather than lingering until the next submit.
  void clearFailure() {
    if (state is SaveProductCategoryFailure) emit(const SaveProductCategoryState.initial());
  }
}
