part of 'save_product_cubit.dart';

/// Everything the add-product screen can be, and nothing it cannot.
///
/// A Freezed union rather than a class with `isLoading`, `error` and `product` nullable at once:
/// that shape permits `isLoading: true` alongside an error, which is exactly how a spinner ends
/// up stuck on top of a failure message.
@freezed
sealed class SaveProductState with _$SaveProductState {
  const factory SaveProductState.initial() = SaveProductInitial;

  /// In flight. The form is locked and the button shows a spinner.
  const factory SaveProductState.submitting() = SaveProductSubmitting;

  /// Created. Carries the product the *server* stored — including the `code` it allocated,
  /// which is what staff will call this bag from now on.
  const factory SaveProductState.success(Product product) = SaveProductSuccess;

  const factory SaveProductState.failure(Failure failure) = SaveProductFailure;
}

extension SaveProductStateX on SaveProductState {
  bool get isSubmitting => this is SaveProductSubmitting;

  String? get nameError => _fieldError('name');

  String? get minimumError => _fieldError('min_order_quantity');

  /// The server's complaint about one size's name — `variants.2.label`.
  String? variantLabelError(int index) => _fieldError('variants.$index.label');

  /// A price cell's complaint, addressed the way Laravel addresses it.
  String? priceError(int variant, int tier) =>
      _fieldError('variants.$variant.price_tiers.$tier.unit_price');

  /// True when the server complained about something this form has nowhere to put.
  ///
  /// Those are the only cases that need a snackbar — anything the form renders inline would
  /// otherwise be said twice. The one that matters is `variants.N.price_tiers`, the whole-list
  /// refusal a quote-only product gets for carrying prices: it has no cell of its own, so
  /// without this the screen would appear to do nothing at all.
  bool get hasUnrenderedErrors => switch (this) {
    SaveProductFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) when fieldErrors != null && fieldErrors.isNotEmpty =>
        fieldErrors.keys.any((key) => !_isRenderedKey(key)),
      // No field errors at all — a 403, a 500, a dropped connection. Nothing is inline, so it
      // all has to be said out loud.
      _ => true,
    },
    _ => false,
  };

  String? _fieldError(String field) => switch (this) {
    SaveProductFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}

/// The exact keys the form paints under an input. Everything else goes to a snackbar.
final RegExp _renderedKey = RegExp(
  // `slug` is deliberately absent: the server generates it and the form has no box for it, so
  // a complaint about one has nowhere to be painted and belongs in the snackbar instead.
  r'^(name|min_order_quantity'
  r'|variants\.\d+\.label'
  r'|variants\.\d+\.price_tiers\.\d+\.unit_price)$',
);

bool _isRenderedKey(String key) => _renderedKey.hasMatch(key);
