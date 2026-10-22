import 'package:dayaa/core/utils/fixed_point.dart';
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

    /// في سجلّ الفترة وحده: كم من [amount] أُفرج عنه إلى محفظته، وكم ينتظر — §١١.
    @Default('0.00') String released,
    @Default('0.00') String pending,

    /// ربحُ طلبياتٍ في الطريق، لم يدخل [amount] بعد لأن لا صفَّ له في الدفتر.
    @Default('0.00') String expected,
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

    /// أين ربحُها من الجيوب — `null` حيث لا يُسأل، كـ«الأرباح المستحقّة» التي تشارك البطاقة.
    @JsonKey(name: 'profit_state', unknownEnumValue: JsonKey.nullForUndefinedEnumValue)
    PeriodProfitState? profitState,
    @JsonKey(name: 'profit_state_label') String? profitStateLabel,

    /// كلُّ حالةٍ لها فيها شيء — ما تُصفّى به، فتقع تحت مرشّحين حين انقسم ربحُها.
    @Default(<PeriodProfitState>[]) List<PeriodProfitState> states,

    @JsonKey(name: 'by_state') PeriodOrderByState? byState,

    /// سيحجز الإقفالُ ربحَها ما لم يدفع العميل — «غير محصّلة» تحت حالتها.
    @Default(false) bool uncollected,

    /// ما سيصل كلَّ شريكٍ منها عند التسليم، لما بلغ «جاهزة».
    @JsonKey(name: 'expected_investors')
    @Default(<PeriodInvestorShare>[])
    List<PeriodInvestorShare> expectedInvestors,
  }) = _PeriodOrder;

  factory PeriodOrder.fromJson(Map<String, dynamic> json) => _$PeriodOrderFromJson(json);
}

/// أين ربحُ طلبيةٍ من جيوب المستثمرين — §١١ من CONTINUOUS-FUND-DESIGN.
///
/// **بترتيب البوّابات**: الأولى أبعدُها عن الجيب، وهو ترتيبُ المرشّحات على الشاشة.
enum PeriodProfitState {
  @JsonValue('awaiting_delivery')
  awaitingDelivery('قيد التسليم'),
  @JsonValue('awaiting_payment')
  awaitingPayment('بانتظار التحصيل'),
  @JsonValue('awaiting_period_end')
  awaitingPeriodEnd('بانتظار انتهاء الفترة'),
  @JsonValue('released')
  released('استُلم الربح');

  const PeriodProfitState(this.label);

  final String label;
}

/// ما تصفّي به القائمة — بلفظ سؤال المالك (2026-10-21): «شن هما الطلبيات اللي تم استلام ربحهم
/// والقيمة مع بعضهم … والي ربحهم في الانتظار».
///
/// **«في الانتظار» حالتان لا تجتمعان في فترة**: المفتوحةُ تنتظر موعدَها وحده، و«قيد الإغلاق»
/// تنتظر التحصيلَ وحده — فسببُها يُكتب تحتها ولا يحتاج مرشّحاً ثانياً. و«قيد التسليم» وحدها لأنها
/// توقّعٌ محسوبٌ لا صفَّ له في الدفتر، فلا تُجمع مع ما فيه.
enum PeriodOrdersFilter {
  received('استُلم ربحها', {PeriodProfitState.released}),
  waiting('ربحها في الانتظار', {
    PeriodProfitState.awaitingPayment,
    PeriodProfitState.awaitingPeriodEnd,
  }),
  onTheRoad('قيد التسليم', {PeriodProfitState.awaitingDelivery});

  const PeriodOrdersFilter(this.label, this.states);

  final String label;
  final Set<PeriodProfitState> states;

  /// بـ`states` لا `profitState`: طلبيةٌ انقسم ربحُها تقع تحت مرشّحين، فتجمع الصفوفُ تحت كلٍّ
  /// منهما إلى رقمه.
  bool matches(PeriodOrder order) => order.states.any(states.contains);
}

/// مبلغُ كلِّ حالةٍ في طلبيةٍ واحدة. الثلاثةُ الأولى من الدفتر وتجمع إلى `investors_total`،
/// و[awaitingDelivery] محسوبٌ — و`null` ما لم يُسعَّر.
@freezed
abstract class PeriodOrderByState with _$PeriodOrderByState {
  const PeriodOrderByState._();

  const factory PeriodOrderByState({
    @Default('0.00') String released,
    @JsonKey(name: 'awaiting_payment') @Default('0.00') String awaitingPayment,
    @JsonKey(name: 'awaiting_period_end') @Default('0.00') String awaitingPeriodEnd,
    @JsonKey(name: 'awaiting_delivery') String? awaitingDelivery,
  }) = _PeriodOrderByState;

  factory PeriodOrderByState.fromJson(Map<String, dynamic> json) =>
      _$PeriodOrderByStateFromJson(json);

  String? of(PeriodProfitState state) => switch (state) {
    PeriodProfitState.awaitingDelivery => awaitingDelivery,
    PeriodProfitState.awaitingPayment => awaitingPayment,
    PeriodProfitState.awaitingPeriodEnd => awaitingPeriodEnd,
    PeriodProfitState.released => released,
  };
}

/// عددُ الطلبيات ومبلغُها تحت حالةٍ واحدة — و[unpriced] لـ«قيد التسليم» وحدها.
@freezed
abstract class PeriodStateTotal with _$PeriodStateTotal {
  const factory PeriodStateTotal({
    @Default(0) int orders,
    @Default('0.00') String amount,
    @Default(0) int unpriced,
  }) = _PeriodStateTotal;

  factory PeriodStateTotal.fromJson(Map<String, dynamic> json) => _$PeriodStateTotalFromJson(json);
}

@freezed
abstract class PeriodStatesTotals with _$PeriodStatesTotals {
  const PeriodStatesTotals._();

  const factory PeriodStatesTotals({
    @Default(PeriodStateTotal()) PeriodStateTotal released,
    @JsonKey(name: 'awaiting_payment') @Default(PeriodStateTotal()) PeriodStateTotal awaitingPayment,
    @JsonKey(name: 'awaiting_period_end')
    @Default(PeriodStateTotal())
    PeriodStateTotal awaitingPeriodEnd,
    @JsonKey(name: 'awaiting_delivery')
    @Default(PeriodStateTotal())
    PeriodStateTotal awaitingDelivery,
  }) = _PeriodStatesTotals;

  factory PeriodStatesTotals.fromJson(Map<String, dynamic> json) =>
      _$PeriodStatesTotalsFromJson(json);

  PeriodStateTotal of(PeriodProfitState state) => switch (state) {
    PeriodProfitState.awaitingDelivery => awaitingDelivery,
    PeriodProfitState.awaitingPayment => awaitingPayment,
    PeriodProfitState.awaitingPeriodEnd => awaitingPeriodEnd,
    PeriodProfitState.released => released,
  };

  /// مجموعُ مرشّحٍ من مجاميع الخادم. «في الانتظار» جمعُ حالتيه — ولا تتداخل طلبياتُهما، لأن
  /// الفترةَ الواحدة لا تقع فيها إلا إحداهما.
  PeriodStateTotal ofFilter(PeriodOrdersFilter filter) => switch (filter) {
    PeriodOrdersFilter.received => released,
    PeriodOrdersFilter.onTheRoad => awaitingDelivery,
    PeriodOrdersFilter.waiting => PeriodStateTotal(
      orders: awaitingPayment.orders + awaitingPeriodEnd.orders,
      amount: addDecimals(awaitingPayment.amount, awaitingPeriodEnd.amount),
    ),
  };
}

/// مجموعُ الفترة: كم طلبيةً أعطت، وكم أعطت — وأين هو من الجيوب.
@freezed
abstract class PeriodOrdersTotals with _$PeriodOrdersTotals {
  const factory PeriodOrdersTotals({
    @Default(0) int orders,
    @JsonKey(name: 'investors_total') @Default('0.00') String investorsTotal,
    @JsonKey(name: 'by_state') @Default(PeriodStatesTotals()) PeriodStatesTotals byState,
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
