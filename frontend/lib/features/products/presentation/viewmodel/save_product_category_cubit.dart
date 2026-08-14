import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/usecases/save_product_category.dart';
import 'package:dayaa/features/products/usecases/set_product_category_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'save_product_category_cubit.freezed.dart';
part 'save_product_category_state.dart';

/// The ViewModel for the sheet that adds or renames a catalogue heading.
///
/// It talks to a use case, never to a repository or to Dio, and it holds no `BuildContext`.
class SaveProductCategoryCubit extends Cubit<SaveProductCategoryState> {
  SaveProductCategoryCubit({
    required SaveProductCategory saveCategory,
    required SetProductCategoryImage setImage,
  }) : _saveCategory = saveCategory,
       _setImage = setImage,
       super(const SaveProductCategoryState.initial());

  final SaveProductCategory _saveCategory;
  final SetProductCategoryImage _setImage;

  /// Adds when [categoryId] is null, renames when it is not.
  ///
  /// One method for both, because the form, the validation and the 422 mapping are identical —
  /// the only difference is which request goes out.
  ///
  /// **Retrying after a [Failure.network] is safe here**, which is not true of every create:
  /// the name is unique in the database, so a request that did land before the connection
  /// dropped turns the retry into a readable 422 rather than a second «أكياس».
  ///
  /// [image] is a newly picked file, [removeImage] the request to take the current one off.
  /// They are mutually exclusive by construction — the sheet offers one or the other — and both
  /// happen **after** the save, because a new category has no id to hang a picture on until the
  /// server has given it one.
  Future<void> submit({
    int? categoryId,
    required String name,
    String? description,
    int sortOrder = 0,
    bool isActive = true,
    PickedFile? image,
    bool removeImage = false,
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

    final saved = result.fold<ProductCategory?>((_) => null, (category) => category);

    if (saved == null) {
      emit(result.fold(SaveProductCategoryState.failure, SaveProductCategoryState.success));

      return;
    }

    final withPicture = await _applyImage(saved, image: image, removeImage: removeImage);
    if (isClosed) return;

    emit(
      withPicture.fold(
        // **The name is already saved when a picture fails**, and saying otherwise would be a
        // lie the next screen contradicts. So the failure carries the picture's complaint while
        // the category itself is what it is; the sheet shows the message and stays open on a
        // row that now exists.
        SaveProductCategoryState.failure,
        SaveProductCategoryState.success,
      ),
    );
  }

  /// Puts the picture on the row that now certainly exists, or takes it off.
  ///
  /// Answers the category unchanged when there is nothing to do, so the common case costs no
  /// second request.
  Future<Either<Failure, ProductCategory>> _applyImage(
    ProductCategory category, {
    required PickedFile? image,
    required bool removeImage,
  }) async {
    if (image != null) {
      return _setImage(category.id, path: image.path, filename: image.name);
    }

    if (removeImage && category.hasImage) {
      return _setImage.remove(category.id);
    }

    return Right(category);
  }

  /// Clears a previous failure so the error under the field disappears as soon as the user
  /// starts correcting it, rather than lingering until the next submit.
  void clearFailure() {
    if (state is SaveProductCategoryFailure) emit(const SaveProductCategoryState.initial());
  }
}
