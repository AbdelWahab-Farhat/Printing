part of 'order_status_cubit.dart';

/// The move-an-order screen, as a closed set of shapes.
///
/// [OrderStatusReady] carries the selection and what has been filled in for it, so a refused
/// move can hand them straight back — [OrderStatusFailure] keeps both for exactly that reason.
/// A failure that emptied the form would make a dropped connection cost the user their typing.
@freezed
sealed class OrderStatusState with _$OrderStatusState {
  const factory OrderStatusState.loading() = OrderStatusLoading;

  const factory OrderStatusState.ready({
    required Order order,

    /// Null until a destination is picked — or again after a successful move, when the order
    /// on screen is a different one with different moves.
    OrderTransition? selected,

    /// Keyed by [TransitionField.key], holding whatever that kind of field holds: a `String`
    /// for text, a `List<CustomerDesign>` for artwork.
    @Default(<String, Object?>{}) Map<String, Object?> values,

    @Default(false) bool isSubmitting,
  }) = OrderStatusReady;

  const factory OrderStatusState.failure({
    required Failure failure,
    Order? order,
    OrderTransition? selected,
    @Default(<String, Object?>{}) Map<String, Object?> values,
  }) = OrderStatusFailure;

  const OrderStatusState._();

  Order? get order => switch (this) {
    OrderStatusReady(:final order) => order,
    OrderStatusFailure(:final order) => order,
    OrderStatusLoading() => null,
  };

  OrderTransition? get selected => switch (this) {
    OrderStatusReady(:final selected) => selected,
    OrderStatusFailure(:final selected) => selected,
    OrderStatusLoading() => null,
  };

  Map<String, Object?> get values => switch (this) {
    OrderStatusReady(:final values) => values,
    OrderStatusFailure(:final values) => values,
    OrderStatusLoading() => const {},
  };

  bool get isSubmitting => switch (this) {
    OrderStatusReady(:final isSubmitting) => isSubmitting,
    _ => false,
  };

  /// Whether the move can be sent.
  ///
  /// **A courtesy, not the rule.** The server validates the same list and answers 422; this
  /// only spares somebody a round trip to be told they left the artwork out. A field of a kind
  /// this build cannot draw is not counted — there would be nothing on screen to fill in, and a
  /// button disabled forever with no visible cause is worse than a refusal that explains itself.
  bool get canSubmit {
    final transition = selected;
    if (transition == null || isSubmitting) return false;

    // Asked of the whole form rather than of each field alone: «طريقة الدفع» is optional until
    // an amount is typed beside it and obligatory from then on — see [TransitionField.requiredWith].
    return transition.fields
        .where((field) => field.isRenderable && field.isDemandedBy(values))
        .every((field) => switch (values[field.key]) {
          null => false,
          final String text => text.trim().isNotEmpty,
          final Iterable<Object?> many => many.isNotEmpty,
          _ => true,
        });
  }
}
