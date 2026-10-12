import 'package:dayaa/features/investment_fund/models/period_expenses.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_expense.freezed.dart';
part 'fund_expense.g.dart';

/// الفترةُ التي يقع يومُ المصروف فيها — رمزُها، وحالتُها لشريحتها.
@freezed
abstract class FundExpensePeriod with _$FundExpensePeriod {
  const factory FundExpensePeriod({
    required int id,
    required String code,
    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,
  }) = _FundExpensePeriod;

  factory FundExpensePeriod.fromJson(Map<String, dynamic> json) =>
      _$FundExpensePeriodFromJson(json);
}

/// أمرُ الشراء الذي تحمله بضاعتُه مصروفاً — Docs/investor-deals/FUND-EXPENSE-ON-GOODS.md.
@freezed
abstract class FundExpensePurchaseOrder with _$FundExpensePurchaseOrder {
  const factory FundExpensePurchaseOrder({required int id}) = _FundExpensePurchaseOrder;

  factory FundExpensePurchaseOrder.fromJson(Map<String, dynamic> json) =>
      _$FundExpensePurchaseOrderFromJson(json);
}

/// كيف انقسم مصروفٌ على البضاعة يومَ سُجِّل: ما رفع تكلفةَ الرفّ، وما كُتب على المبيعات.
@freezed
abstract class FundExpenseSplit with _$FundExpenseSplit {
  const factory FundExpenseSplit({
    @JsonKey(name: 'on_goods') required String onGoods,
    @JsonKey(name: 'on_sales') required String onSales,
  }) = _FundExpenseSplit;

  factory FundExpenseSplit.fromJson(Map<String, dynamic> json) =>
      _$FundExpenseSplitFromJson(json);
}

/// مصروفٌ في «مصاريف الصندوق» — ما خرج، ولماذا، وفي أيّ فترة.
///
/// **أخفُّ من [PeriodExpense] عن قصد**: لا نصيبَ لكلِّ مستثمر ولا زرَّ عكس. ذلك ما حُمِّل في
/// فترةٍ بعينها، وشاشةُ الفترة تقوله — والبطاقةُ هنا تُفتح عليها.
///
/// **و[counted] يقوله الخادم** بقاعدة شاشة الفترة نفسِها، فمجموعُ القائمة مفلترةً بفترةٍ هو
/// مجموعُ تلك الشاشة.
@freezed
abstract class FundExpense with _$FundExpense {
  const factory FundExpense({
    required int id,
    required String kind,
    @JsonKey(name: 'kind_label') required String kindLabel,
    required String name,
    required String amount,
    @JsonKey(name: 'incurred_on') String? incurredOn,
    String? notes,
    @JsonKey(name: 'treasury_account') PeriodExpenseRef? treasuryAccount,
    @JsonKey(name: 'recorded_by') PeriodExpenseRef? recordedBy,

    /// `null` لمصروفٍ بتاريخٍ قبل أوّل فترة.
    FundExpensePeriod? period,
    @Default(true) bool counted,

    /// مؤرّخٌ في فترةٍ أُقفلت وسُجِّل بعد إقفالها — فحُمِّل على المفتوحة يومَ سُجِّل.
    @JsonKey(name: 'recorded_after_close') @Default(false) bool recordedAfterClose,
    @JsonKey(name: 'is_reversed') @Default(false) bool isReversed,
    PeriodExpenseReversal? reversal,

    /// مصروفٌ على البضاعة: `amount` ما وقع منه في الفترة المختارة، وكاملُه في [expenseAmount].
    @JsonKey(name: 'expense_amount') String? expenseAmount,
    @JsonKey(name: 'purchase_order') FundExpensePurchaseOrder? purchaseOrder,
    FundExpenseSplit? split,
  }) = _FundExpense;

  factory FundExpense.fromJson(Map<String, dynamic> json) => _$FundExpenseFromJson(json);
}
