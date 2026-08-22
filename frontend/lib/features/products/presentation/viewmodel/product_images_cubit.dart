import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/models/product_image_rules.dart';
import 'package:dayaa/features/products/usecases/delete_product_image.dart';
import 'package:dayaa/features/products/usecases/get_product.dart';
import 'package:dayaa/features/products/usecases/set_primary_product_image.dart';
import 'package:dayaa/features/products/usecases/upload_product_image.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'product_images_cubit.freezed.dart';
part 'product_images_state.dart';

/// One product's photographs, and the three things staff do to them.
///
/// **Every write is followed by a reload, and that is the API's shape rather than laziness.**
/// The server registers no listing endpoint for images — they travel inside `GET /products/{id}`
/// — and two of the three writes change rows they do not answer with: promoting one photograph
/// demotes another, and deleting the primary promotes whichever is next. A cubit that patched
/// its own list from the single record it was handed would draw two primaries, or none.
///
/// Failures are returned to the caller as a `Failure?` rather than emitted, for the reason
/// [ProductDetailCubit] gives: replacing a grid somebody is looking at with an error page is not
/// what "that did not work" should look like. The message belongs in a snackbar over the photos
/// it is about. The one exception is [load] itself, which has nothing older to fall back on.
class ProductImagesCubit extends Cubit<ProductImagesState> {
  ProductImagesCubit({
    required int productId,
    required GetProduct getProduct,
    required UploadProductImage uploadImage,
    required SetPrimaryProductImage setPrimary,
    required DeleteProductImage deleteImage,
  }) : _productId = productId,
       _getProduct = getProduct,
       _uploadImage = uploadImage,
       _setPrimary = setPrimary,
       _deleteImage = deleteImage,
       super(const ProductImagesState.loading());

  final int _productId;
  final GetProduct _getProduct;
  final UploadProductImage _uploadImage;
  final SetPrimaryProductImage _setPrimary;
  final DeleteProductImage _deleteImage;

  Future<void> load() async {
    // Only from nothing: a reload after a write must not blank a grid the user is looking at.
    if (state is! ProductImagesLoaded) emit(const ProductImagesState.loading());

    final result = await _getProduct(_productId);
    if (isClosed) return;

    emit(
      result.fold((failure) => ProductImagesState.failure(failure), (product) {
        final current = state;

        return current is ProductImagesLoaded
            ? current.copyWith(images: product.images)
            : ProductImagesState.loaded(images: product.images);
      }),
    );
  }

  /// Adds one photograph. Returns null when it worked, and the failure when it did not.
  ///
  /// The cap is checked by the screen before the picker opens — a refusal that costs nothing —
  /// and by [UploadProductImage] before the bytes leave, and by the server after they arrive.
  /// Three places, one number, and a contract test that keeps them the same.
  Future<Failure?> add(PickedFile file) async {
    final current = state;
    if (current is! ProductImagesLoaded || current.isUploading) return null;

    emit(current.copyWith(isUploading: true, sent: 0, total: file.sizeBytes));

    final result = await _uploadImage(
      _productId,
      image: file,
      onProgress: _onProgress,
    );
    if (isClosed) return null;

    final failure = result.fold<Failure?>((it) => it, (_) => null);

    if (failure != null) {
      _stopUploading();

      return failure;
    }

    // The uploaded record is discarded on purpose: `load` is what learns the order the server
    // put it in, which is not something this app decides.
    await load();
    _stopUploading();

    return null;
  }

  /// Promotes one photograph to be the product's primary.
  Future<Failure?> makePrimary(int imageId) => _write(imageId, () => _setPrimary(_productId, imageId));

  /// Removes one photograph. The server refuses the last one, in its own Arabic.
  Future<Failure?> remove(int imageId) => _write(imageId, () => _deleteImage(_productId, imageId));

  // ───────────────────────────────────────────────────────────────────────────

  /// The shape both single-image writes share: mark the row busy, call, reload on success and
  /// hand a refusal back untouched.
  Future<Failure?> _write(
    int imageId,
    Future<Either<Failure, Object>> Function() call,
  ) async {
    final current = state;
    if (current is! ProductImagesLoaded || current.busy.contains(imageId)) return null;

    emit(current.copyWith(busy: {...current.busy, imageId}));

    final result = await call();
    if (isClosed) return null;

    // Neither answer is used beyond "did it work" — the reload is what produces the list, for
    // the reason on the class.
    final failure = result.fold<Failure?>((it) => it, (_) => null);

    if (failure != null) {
      _clearBusy(imageId);

      return failure;
    }

    await load();
    _clearBusy(imageId);

    return null;
  }

  void _onProgress(int sent, int total) {
    final current = state;
    if (current is! ProductImagesLoaded || !current.isUploading || total <= 0) return;

    // Dio reports per chunk, which on a fast connection is far more often than a bar can show.
    // Emitting only on a whole percent turns hundreds of rebuilds of the grid into a hundred.
    if ((current.sent * 100) ~/ total == (sent * 100) ~/ total) return;

    emit(current.copyWith(sent: sent, total: total));
  }

  void _stopUploading() {
    final current = state;
    if (current is! ProductImagesLoaded) return;

    emit(current.copyWith(isUploading: false, sent: 0, total: 0));
  }

  void _clearBusy(int imageId) {
    final current = state;
    if (current is! ProductImagesLoaded) return;

    emit(current.copyWith(busy: {...current.busy}..remove(imageId)));
  }
}
