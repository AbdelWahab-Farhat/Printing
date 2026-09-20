import 'package:freezed_annotation/freezed_annotation.dart';

part 'pool_expense.freezed.dart';
part 'pool_expense.g.dart';

/// One cost charged to a صندوق.
///
/// **[isDeducted] is what a screen leads with, not [amount].** Shipping and customs typed on a
/// purchase order are already inside the cost of the layers that arrived — recorded here and
/// **not** subtracted, because taking them off again would charge the partners for one customs
/// invoice twice. A list that prints every amount the same way invites somebody to add them up and
/// get a number the close does not use.
///
/// [investmentPeriodId] is which period actually bore it, and it is not always the one the date
/// falls in: a closed period is immutable, so an invoice bearing last month's date is charged to
/// the period that is open now and keeps its true [incurredOn].
@freezed
abstract class PoolExpense with _$PoolExpense {
  const factory PoolExpense({
    required int id,
    @JsonKey(name: 'investor_deal_id') required int investorDealId,
    @JsonKey(name: 'investment_period_id') int? investmentPeriodId,

    required String kind,
    @JsonKey(name: 'kind_label') required String kindLabel,

    required String name,
    required String amount,

    /// Recorded and **not** subtracted — «محسوبة مسبقاً».
    @JsonKey(name: 'is_landed') @Default(false) bool isLanded,

    /// Whether the close actually takes this off the period's profit.
    @JsonKey(name: 'is_deducted') @Default(true) bool isDeducted,

    @JsonKey(name: 'incurred_on') String? incurredOn,

    /// A correction undoes by a further row; neither side is deducted afterwards.
    @JsonKey(name: 'reverses_expense_id') int? reversesExpenseId,
    @JsonKey(name: 'is_reversed') @Default(false) bool isReversed,

    String? notes,
    @JsonKey(name: 'recorded_at') String? recordedAt,
  }) = _PoolExpense;

  factory PoolExpense.fromJson(Map<String, dynamic> json) =>
      _$PoolExpenseFromJson(json);
}
