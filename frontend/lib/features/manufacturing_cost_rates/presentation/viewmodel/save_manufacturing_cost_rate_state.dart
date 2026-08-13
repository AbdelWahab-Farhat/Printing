part of 'save_manufacturing_cost_rate_cubit.dart';

/// Everything the rate form can be, and nothing it cannot.
@freezed
sealed class SaveManufacturingCostRateState with _$SaveManufacturingCostRateState {
  const factory SaveManufacturingCostRateState.initial() = SaveManufacturingCostRateInitial;

  /// In flight. The form is locked and the button shows a spinner.
  const factory SaveManufacturingCostRateState.submitting() =
      SaveManufacturingCostRateSubmitting;

  /// Saved. Carries what the server stored — including the three decimals it normalises the rate
  /// to, so a form reopened on it shows the stored number rather than the typed one.
  const factory SaveManufacturingCostRateState.success(ManufacturingCostRate rate) =
      SaveManufacturingCostRateSuccess;

  const factory SaveManufacturingCostRateState.failure(Failure failure) =
      SaveManufacturingCostRateFailure;
}

extension SaveManufacturingCostRateStateX on SaveManufacturingCostRateState {
  bool get isSubmitting => this is SaveManufacturingCostRateSubmitting;

  /// The server's complaint about the kind of cost — **and this is where the duplicate lands**.
  ///
  /// «يوجد بالفعل معدل لهذا المنتج ولهذا النوع من التكاليف» is keyed on `cost_type` rather than on
  /// the rung that made it a duplicate, which reads oddly until you know it: the uniqueness rule
  /// is «one rate per kind per rung», and the kind is the half the form can change most cheaply.
  String? get costTypeError => _fieldError('cost_type');

  /// Everything the server can say about the rung, under the one control that chooses it.
  ///
  /// The refusal for setting both a product and a size is keyed on `product_variant_id`; «المنتج
  /// المحدد غير موجود» arrives on `product_id`. Neither has a box of its own on this form — the
  /// rung is one picker — so both are shown there.
  String? get scopeError => _fieldError('product_variant_id') ?? _fieldError('product_id');

  String? get rateError => _fieldError('rate_per_unit');

  String? get notesError => _fieldError('notes');

  /// True when the server complained about something this form has nowhere to put, so it has to
  /// be said out loud instead of painted under a box.
  bool get hasUnrenderedErrors => switch (this) {
    SaveManufacturingCostRateFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) when fieldErrors != null && fieldErrors.isNotEmpty =>
        fieldErrors.keys.any((key) => !_rendered.contains(key)),
      // No field errors at all — a 403, a 500, a dropped connection.
      _ => true,
    },
    _ => false,
  };

  String? _fieldError(String field) => switch (this) {
    SaveManufacturingCostRateFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}

/// The keys that have somewhere to be drawn. `is_active` is deliberately absent: its only
/// complaint is «الحالة يجب أن تكون صحيحة أو خاطئة», which a switch cannot produce — so if it
/// ever arrives, it is a bug worth a toast rather than a caption under a control.
const Set<String> _rendered = {
  'product_id',
  'product_variant_id',
  'cost_type',
  'rate_per_unit',
  'notes',
};
