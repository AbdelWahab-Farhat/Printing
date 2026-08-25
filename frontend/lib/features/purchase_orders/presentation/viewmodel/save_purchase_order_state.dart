part of 'save_purchase_order_cubit.dart';

/// Everything the purchase-order form can be, and nothing it cannot.
@freezed
sealed class SavePurchaseOrderState with _$SavePurchaseOrderState {
  const factory SavePurchaseOrderState.initial() = SavePurchaseOrderInitial;

  const factory SavePurchaseOrderState.submitting() =
      SavePurchaseOrderSubmitting;

  /// Written. Carries what the server stored — including the lines' ids, which an edit needs.
  const factory SavePurchaseOrderState.success(PurchaseOrder order) =
      SavePurchaseOrderSuccess;

  const factory SavePurchaseOrderState.failure(Failure failure) =
      SavePurchaseOrderFailure;
}

extension SavePurchaseOrderStateX on SavePurchaseOrderState {
  bool get isSubmitting => this is SavePurchaseOrderSubmitting;

  String? get vendorError => _fieldError('vendor_id');

  String? get warehouseError => _fieldError('warehouse_id');

  String? get orderDateError => _fieldError('order_date');

  /// The one that catches people: «التاريخ المتوقع يجب أن يكون بعد أو يساوي تاريخ الطلب».
  String? get expectedDateError => _fieldError('expected_date');

  /// A complaint about the list as a whole — no lines, or the same shelf twice.
  ///
  /// **The duplicate is the one that matters now.** An order carries one line per stock item, and
  /// two products at one size share a shelf — so a buyer who used to raise «كيس شحن سادة 25*35»
  /// and «كيس شحن مطبوع 25*35» as two lines is now naming one thing twice, and the server refuses
  /// it with «لا يمكن تكرار نفس الصنف أكثر من مرة في أمر الشراء». The form blocks it before the
  /// save, but a stale screen can still reach it, so it must land somewhere readable rather than
  /// disappear.
  ///
  /// It has no single box to sit under, so the form puts it above the lines.
  String? get itemsError =>
      _fieldError('items') ??
      // Laravel addresses a duplicate at the offending index, so the whole-list message a
      // person needs has to be found among keys like `items.1.stock_item_id`.
      _firstMatching(RegExp(r'^items\.\d+\.'));

  /// The same, for the order-level costs. Sits above that list for the same reason: an
  /// `additional_costs.1.amount` complaint has no box on screen that key can be matched to.
  String? get additionalCostsError =>
      _fieldError('additional_costs') ??
      _firstMatching(RegExp(r'^additional_costs\.\d+\.'));

  bool get hasUnrenderedErrors => switch (this) {
    SavePurchaseOrderFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors)
          when fieldErrors != null && fieldErrors.isNotEmpty =>
        fieldErrors.keys.any(
          (key) =>
              !_rendered.contains(key) &&
              !key.startsWith('items') &&
              !key.startsWith('additional_costs'),
        ),
      _ => true,
    },
    _ => false,
  };

  String? _fieldError(String field) => switch (this) {
    SavePurchaseOrderFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) => fieldErrors?[field]?.firstOrNull,
      _ => null,
    },
    _ => null,
  };

  String? _firstMatching(RegExp pattern) => switch (this) {
    SavePurchaseOrderFailure(:final failure) => switch (failure) {
      ServerFailure(:final fieldErrors) when fieldErrors != null =>
        fieldErrors.entries
            .where((entry) => pattern.hasMatch(entry.key))
            .map((entry) => entry.value.firstOrNull)
            .whereType<String>()
            .firstOrNull,
      _ => null,
    },
    _ => null,
  };
}

const Set<String> _rendered = {
  'vendor_id',
  'warehouse_id',
  'order_date',
  'expected_date',
};
