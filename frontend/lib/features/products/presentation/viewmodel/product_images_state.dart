part of 'product_images_cubit.dart';

/// Everything the product images screen can be, and nothing it cannot.
///
/// **The two in-flight flags are separate fields on `loaded` rather than cases of their own.**
/// An upload and a promotion both happen *over* a grid the user is still looking at, and a
/// `changing` case would mean blanking the photographs to say something about one of them.
///
/// [ProductImagesLoaded.busy] holds ids rather than a single flag because each photograph has
/// its own two buttons: promoting one must spin on that tile alone, not on all five.
@freezed
sealed class ProductImagesState with _$ProductImagesState {
  const factory ProductImagesState.loading() = ProductImagesLoading;

  const factory ProductImagesState.loaded({
    required List<ProductImage> images,

    /// One at a time — the screen refuses to open a second picker while one is going up, so
    /// this is a flag rather than a queue. The cap is five; a queue would be machinery for a
    /// case the limit already prevents.
    @Default(false) bool isUploading,

    /// Bytes sent and bytes to send, so the bar shows a fraction rather than a spinner. Both
    /// zero whenever nothing is uploading.
    @Default(0) int sent,
    @Default(0) int total,

    /// The photographs with a write in flight against them — a promotion or a delete.
    @Default(<int>{}) Set<int> busy,
  }) = ProductImagesLoaded;

  const factory ProductImagesState.failure(Failure failure) = ProductImagesFailure;
}

extension ProductImagesStateX on ProductImagesState {
  /// The photographs, whenever there are any to show.
  List<ProductImage> get images => switch (this) {
    ProductImagesLoaded(:final images) => images,
    _ => const <ProductImage>[],
  };

  /// Whether another photograph may be added: the server's cap, asked before a picker opens
  /// rather than after an upload. See [ProductImageRules.maxPerProduct].
  bool get hasRoomForMore => images.length < ProductImageRules.maxPerProduct;

  /// How far the upload in flight has got, from 0 to 1 — or null when nothing is uploading or
  /// the size is not yet known.
  double? get uploadProgress => switch (this) {
    ProductImagesLoaded(:final isUploading, :final sent, :final total)
        when isUploading && total > 0 =>
      (sent / total).clamp(0.0, 1.0),
    _ => null,
  };
}
