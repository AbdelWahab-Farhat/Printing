part of 'take_order_cubit.dart';

/// Everything the new-order screen can be, and nothing it cannot.
///
/// A Freezed union rather than a class with `isLoading`, `error` and `order` nullable at once:
/// that shape permits `isLoading: true` alongside an error, which is exactly how a spinner ends
/// up stuck on top of a failure message.
@freezed
sealed class TakeOrderState with _$TakeOrderState {
  const factory TakeOrderState.initial() = TakeOrderInitial;

  /// In flight. The form is locked and the button shows a spinner — and the lock is doing real
  /// work here, because a second POST is a second order.
  const factory TakeOrderState.submitting() = TakeOrderSubmitting;

  /// Taken. Carries the order the *server* stored — including the number it allocated, which is
  /// what staff will call this job from now on, and the totals it worked out.
  const factory TakeOrderState.success(Order order) = TakeOrderSuccess;

  const factory TakeOrderState.failure(Failure failure) = TakeOrderFailure;
}

extension TakeOrderStateX on TakeOrderState {
  bool get isSubmitting => this is TakeOrderSubmitting;

  /// The server's complaint about the whole set of lines — `items` — rather than about one of
  /// them. «الطلبية يجب أن تحتوي على منتج واحد على الأقل» has no row to sit under.
  String? get itemsError => _fieldError('items');

  /// A complaint about one line, addressed the way Laravel addresses it.
  String? quantityError(int index) => _fieldError('items.$index.quantity');

  String? unitPriceError(int index) => _fieldError('items.$index.unit_price');

  String? get cityError => _fieldError('city_id');

  String? get regionError => _fieldError('region_id');

  String? get discountError => _fieldError('discount');

  String? get designFeeError => _fieldError('design_fee');

  String? get recipientPhoneError => _fieldError('recipient_phone');

  /// True when the server complained about something this form has nowhere to put.
  ///
  /// Those are the only cases that need a snackbar — anything rendered inline would otherwise
  /// be said twice. The ones that matter here are the domain refusals, which carry no `errors`
  /// map at all: a deactivated customer, a shop that belongs to somebody else, a discount from
  /// a clerk without the grant.
  bool get hasUnrenderedErrors => switch (this) {
    TakeOrderFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) when fieldErrors != null && fieldErrors.isNotEmpty =>
        fieldErrors.keys.any((key) => !_isRenderedKey(key)),
      // No field errors at all — a 422 from the domain, a 403, a dropped connection. Nothing is
      // inline, so it all has to be said out loud.
      _ => true,
    },
    _ => false,
  };

  String? _fieldError(String field) => switch (this) {
    TakeOrderFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}

/// The exact keys the form paints under an input. Everything else goes to a snackbar.
final RegExp _renderedKey = RegExp(
  r'^(items|city_id|region_id|discount|design_fee|recipient_phone'
  r'|items\.\d+\.quantity'
  r'|items\.\d+\.unit_price)$',
);

bool _isRenderedKey(String key) => _renderedKey.hasMatch(key);
