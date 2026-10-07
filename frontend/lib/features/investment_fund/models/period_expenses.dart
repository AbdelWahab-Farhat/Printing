import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_expenses.freezed.dart';
part 'period_expenses.g.dart';

/// اسمٌ ورقمُه — الحسابُ الذي دفع، أو من سجّل.
@freezed
abstract class PeriodExpenseRef with _$PeriodExpenseRef {
  const factory PeriodExpenseRef({required int id, required String name}) = _PeriodExpenseRef;

  factory PeriodExpenseRef.fromJson(Map<String, dynamic> json) => _$PeriodExpenseRefFromJson(json);
}

/// عكسُ مصروف: متى، ولماذا، وفي أيّ فترةٍ وقع ردُّه.
@freezed
abstract class PeriodExpenseReversal with _$PeriodExpenseReversal {
  const factory PeriodExpenseReversal({
    required int id,
    @JsonKey(name: 'incurred_on') String? incurredOn,
    String? reason,

    /// الفترةُ التي رُدّ فيها ما حُمِّل للمستثمرين — غيرُ فترة المصروف إن عُكس بعد إقفالها.
    @JsonKey(name: 'period_code') String? periodCode,
  }) = _PeriodExpenseReversal;

  factory PeriodExpenseReversal.fromJson(Map<String, dynamic> json) =>
      _$PeriodExpenseReversalFromJson(json);
}

/// مصروفٌ على الصندوق، وما تحمّله المستثمرون منه في هذه الفترة.
///
/// **[counted] يقوله الخادم.** «أيُعدّ في مصاريف الفترة» قاعدةُ الإقفال نفسُها — معكوسٌ قبل
/// الإقفال لا يُعدّ، ومعكوسٌ بعده يبقى معدوداً في فترته — ونسخةٌ منها هنا تخالفه يوم تتغيّر.
@freezed
abstract class PeriodExpense with _$PeriodExpense {
  const factory PeriodExpense({
    required int id,
    required String kind,
    @JsonKey(name: 'kind_label') required String kindLabel,
    required String name,
    required String amount,
    @JsonKey(name: 'incurred_on') String? incurredOn,
    String? notes,
    @JsonKey(name: 'treasury_account') PeriodExpenseRef? treasuryAccount,
    @JsonKey(name: 'recorded_by') PeriodExpenseRef? recordedBy,
    @Default(true) bool counted,

    /// مؤرّخٌ في فترةٍ أُقفلت وسُجِّل بعد إقفالها — فحُمِّل على المفتوحة يومَ سُجِّل.
    @JsonKey(name: 'recorded_after_close') @Default(false) bool recordedAfterClose,
    @JsonKey(name: 'is_reversed') @Default(false) bool isReversed,

    /// **الخادمُ يقول أيُعكس**: لا ما عُكس، ولا مصروفُ فترةٍ أُقفلت — أرقامُها أُعلنت.
    @JsonKey(name: 'can_reverse') @Default(false) bool canReverse,
    PeriodExpenseReversal? reversal,

    /// ما تحمّله المستثمرون منه في هذه الفترة — **بإشارته**: السالبُ ردٌّ إليهم.
    @JsonKey(name: 'investors_amount') @Default('0.00') String investorsAmount,
    @Default(<PeriodInvestorShare>[]) List<PeriodInvestorShare> investors,
  }) = _PeriodExpense;

  factory PeriodExpense.fromJson(Map<String, dynamic> json) => _$PeriodExpenseFromJson(json);
}

/// مجاميعُ الفترة كما حسبها الخادم — لا تُعاد جمعاً هنا.
@freezed
abstract class PeriodExpensesTotals with _$PeriodExpensesTotals {
  const factory PeriodExpensesTotals({
    /// مجموعُ المعدود من مصاريف نافذتها.
    @JsonKey(name: 'expenses_total') @Default('0.00') String expensesTotal,

    /// ما تحمّله المستثمرون في هذه الفترة، التصحيحاتُ داخلة.
    @JsonKey(name: 'investors_total') @Default('0.00') String investorsTotal,

    /// المجمّدُ على الفترة يوم أُقفلت — `null` ما لم تُقفَل.
    @JsonKey(name: 'frozen_total') String? frozenTotal,
  }) = _PeriodExpensesTotals;

  factory PeriodExpensesTotals.fromJson(Map<String, dynamic> json) =>
      _$PeriodExpensesTotalsFromJson(json);
}

/// تبويبُ «المصاريف» بنداءٍ واحد: الفترةُ، ومصاريفُ نافذتها، وما وقع عليها من فتراتٍ سابقة.
@freezed
abstract class PeriodExpenses with _$PeriodExpenses {
  const factory PeriodExpenses({
    required FundPeriod period,
    @Default(<PeriodExpense>[]) List<PeriodExpense> expenses,

    /// مصاريفُ من فتراتٍ أُقفلت مسّت محافظَ المستثمرين في هذه الفترة: عكسٌ أو تحميلٌ متأخّر.
    @Default(<PeriodExpense>[]) List<PeriodExpense> corrections,
    @Default(PeriodExpensesTotals()) PeriodExpensesTotals totals,
  }) = _PeriodExpenses;

  factory PeriodExpenses.fromJson(Map<String, dynamic> json) => _$PeriodExpensesFromJson(json);
}
