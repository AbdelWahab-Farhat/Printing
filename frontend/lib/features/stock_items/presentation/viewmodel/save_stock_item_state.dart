part of 'save_stock_item_cubit.dart';

/// Everything the stock item form can be, and nothing it cannot.
@freezed
sealed class SaveStockItemState with _$SaveStockItemState {
  const factory SaveStockItemState.initial() = SaveStockItemInitial;

  /// A save is in flight. The button spins; the unit tile does not.
  const factory SaveStockItemState.submitting() = SaveStockItemSubmitting;

  /// Saved. Carries the shelf the **server** stored — its allocated `code`, and the
  /// `display_name` it composed — so the list behind refreshes from the answer rather than from
  /// what was typed.
  const factory SaveStockItemState.success(StockItem item) = SaveStockItemSuccess;

  /// The unit is being changed, which means the balances are being emptied. Its own case rather
  /// than a second use of [SaveStockItemState.submitting], so the save button stays still while
  /// the unit tile is the thing that is working.
  const factory SaveStockItemState.changingUnit() = SaveStockItemChangingUnit;

  /// The unit changed. **The form stays open**: what has just happened is that every warehouse
  /// holding this shelf was taken to zero, and closing the screen on that would be the app's last
  /// word on it. Carries the item so the tile can redraw from the server's own `unit_label`.
  const factory SaveStockItemState.unitChanged(StockItem item) = SaveStockItemUnitChanged;

  const factory SaveStockItemState.failure(Failure failure) = SaveStockItemFailure;
}

extension SaveStockItemStateX on SaveStockItemState {
  /// The save button's spinner.
  bool get isSubmitting => this is SaveStockItemSubmitting;

  /// The unit tile's spinner.
  bool get isChangingUnit => this is SaveStockItemChangingUnit;

  /// Whether any write is in flight. What guards the second tap — either write while the other
  /// is running would be a request nobody asked for.
  bool get isBusy => isSubmitting || isChangingUnit;

  /// «يوجد صنف مخزني بنفس الاسم والمقاس» — the one refusal this form exists to explain.
  ///
  /// It is keyed on `name` even when the *size* is the half that made it a duplicate, because
  /// identity is `(name, width, height)` and the name is the field the rule is declared on. The
  /// caption under the name box says the size out loud for that reason.
  String? get nameError => _fieldError('name');

  /// Both halves of the size under one control. «العرض والطول يجب أن يُدخلا معاً» arrives on
  /// whichever of them was left out, and the form draws them as one row, so either is shown
  /// there — a caption hanging under only one of two boxes reads as a complaint about that box.
  String? get sizeError => _fieldError('width_cm') ?? _fieldError('height_cm');

  /// Only ever raised while creating: the update carries no `unit` rule at all.
  String? get unitError => _fieldError('unit');

  /// «الصنف المخزني المحدد غير موجود» for a material deleted between opening the form and
  /// saving. Shown under the material tile, which is the only place it could be acted on.
  String? get groupError => _fieldError('stock_item_group_id');

  String? get descriptionError => _fieldError('description');

  /// True when the server complained about something this form has nowhere to put, so it has to
  /// be said out loud instead of painted under a box.
  ///
  /// **Asked as «هل بقي شيء؟» rather than «هل هناك أخطاء حقول؟»**: a form that suppressed the
  /// toast whenever *any* field error arrived would swallow the one key it does not draw — and
  /// `sort_order` has no control on this screen precisely because it is round-tripped rather
  /// than edited, so a complaint about it is a bug worth seeing.
  bool get hasUnrenderedErrors => switch (this) {
    SaveStockItemFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) when fieldErrors != null && fieldErrors.isNotEmpty =>
        fieldErrors.keys.any((key) => !_rendered.contains(key)),
      // No field errors at all — a 403, a 500, a dropped connection.
      _ => true,
    },
    _ => false,
  };

  String? _fieldError(String field) => switch (this) {
    SaveStockItemFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };
}

/// The keys that have somewhere to be drawn.
///
/// `is_active` and `sort_order` are deliberately absent: neither has a complaint a switch or a
/// round-tripped integer could produce, so one arriving means something is wrong with the payload
/// rather than with what somebody typed — and that deserves a toast, not silence.
const Set<String> _rendered = {
  'name',
  'width_cm',
  'height_cm',
  'unit',
  'stock_item_group_id',
  'description',
};
