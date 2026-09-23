import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_orders.freezed.dart';
part 'period_orders.g.dart';

/// نصيبُ مستثمرٍ واحد من شيءٍ واحد — طلبيةٍ، أو فترةٍ بأكملها.
///
/// **بإشارته.** السالبُ عكسٌ وقع على هذه الفترة: تصحيحُ طلبيةٍ من فترةٍ أُقفلت لا يستطيع أن
/// يعود إلى جيبٍ خرج منه المال، فيقع على المفتوحة اليوم — وإخفاءُ إشارته يجعله يُقرأ ربحاً.
@freezed
abstract class PeriodInvestorShare with _$PeriodInvestorShare {
  const factory PeriodInvestorShare({
    @JsonKey(name: 'investor_id') required int investorId,
    required String name,
    required String amount,
  }) = _PeriodInvestorShare;

  factory PeriodInvestorShare.fromJson(Map<String, dynamic> json) =>
      _$PeriodInvestorShareFromJson(json);
}

/// طلبيةٌ أعطت مستثمري الفترة ربحاً، ومن أخذ منها كم.
///
/// **الرقمُ من الدفتر لا من حسابٍ يجري الآن.** هو ما قُيِّد في محافظ الناس فعلاً بختم هذه
/// الفترة؛ وإعادةُ اشتقاقه من الـFIFO بعد سنةٍ كانت تُظهر رقماً غير الذي دخل الجيوب.
@freezed
abstract class PeriodOrder with _$PeriodOrder {
  const factory PeriodOrder({
    @JsonKey(name: 'order_id') required int orderId,
    required String code,

    required String status,
    @JsonKey(name: 'status_label') required String statusLabel,

    @JsonKey(name: 'customer_name') String? customerName,

    /// يومُ وصولها العميل، أو يومُ كتابتها لطلبيةٍ لم تصل بعد.
    @JsonKey(name: 'occurred_at') DateTime? occurredAt,

    /// مالُ الطلبية كلُّه — ليُقرأ نصيبُ المستثمرين في مقابل شيء.
    @JsonKey(name: 'grand_total') required String grandTotal,

    /// مجموعُ ما أخذه المستثمرون منها، وهو جمعُ [investors] لا رقمٌ ثانٍ.
    @JsonKey(name: 'investors_total') required String investorsTotal,

    @Default(<PeriodInvestorShare>[]) List<PeriodInvestorShare> investors,
  }) = _PeriodOrder;

  factory PeriodOrder.fromJson(Map<String, dynamic> json) => _$PeriodOrderFromJson(json);
}

/// مجموعُ الفترة: كم طلبيةً أعطت، وكم أعطت.
@freezed
abstract class PeriodOrdersTotals with _$PeriodOrdersTotals {
  const factory PeriodOrdersTotals({
    @Default(0) int orders,
    @JsonKey(name: 'investors_total') @Default('0.00') String investorsTotal,
  }) = _PeriodOrdersTotals;

  factory PeriodOrdersTotals.fromJson(Map<String, dynamic> json) =>
      _$PeriodOrdersTotalsFromJson(json);
}

/// شاشةُ الفترة الواحدة بنداءٍ واحد: ترويستُها، وطلبياتُها، ومن أخذ منها.
///
/// **الفترةُ تسافر مع قائمتها** فلا تُرسم الترويسةُ من صفٍّ في قائمةٍ أخرى قد تكون قديمة —
/// ولا يُنتظر نداءان لرسم شاشة.
@freezed
abstract class PeriodOrders with _$PeriodOrders {
  const factory PeriodOrders({
    required FundPeriod period,
    @Default(<PeriodOrder>[]) List<PeriodOrder> orders,

    /// مجموعُ كلِّ مستثمرٍ في الفترة كلِّها — «سجل ربح المستثمرين» مختصراً فوق تفصيله.
    @Default(<PeriodInvestorShare>[]) List<PeriodInvestorShare> investors,

    @Default(PeriodOrdersTotals()) PeriodOrdersTotals totals,
  }) = _PeriodOrders;

  factory PeriodOrders.fromJson(Map<String, dynamic> json) => _$PeriodOrdersFromJson(json);
}
