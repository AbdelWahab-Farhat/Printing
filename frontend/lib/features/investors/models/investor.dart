import 'package:dayaa/features/investors/models/fund_share.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'investor.freezed.dart';
part 'investor.g.dart';

/// A person whose money finances stock.
///
/// Every amount here is a `String` exactly as the server sent it — the rule the whole app
/// follows for money, because a decimal round-tripped through a float is how `2500.10` becomes
/// `2500.099999` on somebody's screen.
@freezed
abstract class Investor with _$Investor {
  const factory Investor({
    required int id,

    /// «I7» — what staff say out loud and what he quotes on the phone.
    required String code,
    required String name,
    String? phone,
    String? notes,

    @JsonKey(name: 'is_active') @Default(true) bool isActive,

    /// Whether he has an account he can sign in with.
    @JsonKey(name: 'has_login') @Default(false) bool hasLogin,

    /// What he has with us and what he has earned — sent with the list, so the register can draw
    /// two numbers without opening anybody's screen.
    InvestorTotals? totals,

    /// Present on the detail screen only — a list of fifty investors does not walk fifty
    /// ledgers to draw a table.
    InvestorBalances? balances,

    /// **الأرقامُ الثلاثة** — على صفحته وحدها، كما `balances`.
    @JsonKey(name: 'profit_figures') ProfitFigures? profitFigures,

    /// **مالُه في الصندوق** — على صفحته وحدها كذلك. الصندوقُ ليس من [InvestorBalances.deals]
    /// عمداً، وهذا ما يقوله بدلاً منه.
    FundShare? fund,

    /// **فتراتُه، الأحدثُ أوّلاً** — على صفحته وحدها، في مكان الصفقات: «عرض الفترات بدلا من
    /// الصفقات» (2026-09-25).
    @Default(<InvestorPeriod>[]) List<InvestorPeriod> periods,
  }) = _Investor;

  factory Investor.fromJson(Map<String, dynamic> json) => _$InvestorFromJson(json);
}

/// فترةٌ كان شريكاً فيها، وربحُه فيها كما تقوله شاشتُها — الخادمُ يأخذه منها لا من حسابٍ ثانٍ.
@freezed
abstract class InvestorPeriod with _$InvestorPeriod {
  const factory InvestorPeriod({
    required int id,
    required String code,

    /// سالبٌ في فترةٍ خسر فيها.
    required String profit,
  }) = _InvestorPeriod;

  factory InvestorPeriod.fromJson(Map<String, dynamic> json) => _$InvestorPeriodFromJson(json);
}

/// What his money is doing: two pots in the wallet, and two per deal.
@freezed
abstract class InvestorBalances with _$InvestorBalances {
  const factory InvestorBalances({
    required WalletPots wallet,

    /// **A list whose rows name their own deal**, not a map keyed by id: an integer-keyed map
    /// does not survive the trip through JSON as an object, and a silently re-indexed map puts
    /// the right figures against the wrong deal.
    @Default(<DealPots>[]) List<DealPots> deals,
  }) = _InvestorBalances;

  factory InvestorBalances.fromJson(Map<String, dynamic> json) => _$InvestorBalancesFromJson(json);
}

@freezed
abstract class WalletPots with _$WalletPots {
  const factory WalletPots({
    /// Money with the company, committed to nothing.
    required String capital,

    /// Profit released by a closed deal — the only profit a withdrawal can draw on.
    required String profit,
  }) = _WalletPots;

  factory WalletPots.fromJson(Map<String, dynamic> json) => _$WalletPotsFromJson(json);
}

@freezed
abstract class DealPots with _$DealPots {
  const factory DealPots({
    @JsonKey(name: 'investor_deal_id') required int investorDealId,

    /// What he has financing goods in this deal.
    required String capital,

    /// What it has earned him so far. Not withdrawable until the deal closes.
    required String profit,
  }) = _DealPots;

  factory DealPots.fromJson(Map<String, dynamic> json) => _$DealPotsFromJson(json);
}

/// One investor's money in two numbers, as the register draws them.
///
/// **[capital] is both places his capital can be** — his wallet and the deals it is committed to
/// — because from where he stands they are one sum he handed over. [walletCapital] is the part
/// of it still uncommitted, and the deal-by-deal split is on his own screen, where the
/// distinction is the point.
@freezed
abstract class InvestorTotals with _$InvestorTotals {
  const factory InvestorTotals({
    required String capital,
    required String profit,
    @JsonKey(name: 'wallet_capital') required String walletCapital,
    @JsonKey(name: 'wallet_profit') required String walletProfit,
  }) = _InvestorTotals;

  const InvestorTotals._();

  factory InvestorTotals.fromJson(Map<String, dynamic> json) =>
      _$InvestorTotalsFromJson(json);
}

/// ربحُه في ثلاث بوّاباتٍ متتابعة — لا رقماً واحداً.
///
/// **قيد التسليم** طلبياتٌ بلغت «جاهزة» ولم تُسلَّم: محسوبٌ بالقسمة التي سيقيّده بها التسليم،
/// ولا صفَّ له في الدفتر. **معلّقة** سُلِّمت فقُيِّدت، ولا تُسحب حتى تنقضي فترتُها وتُحصَّل
/// طلبيتُها. **متاحة للسحب** اجتمع شرطاها. الشاشةُ تعرض مجموعَها، وزرٌّ لكل بوّابة
/// يفصلها — المجموعُ وحده يَعِد بمالٍ لا يُسحب.
@freezed
abstract class ProfitFigures with _$ProfitFigures {
  const factory ProfitFigures({
    @JsonKey(name: 'awaiting_delivery') required String awaitingDelivery,

    /// كم طلبيةً وراء «قيد التسليم».
    @JsonKey(name: 'orders_awaiting_delivery') @Default(0) int ordersAwaitingDelivery,
    required String pending,
    required String available,
  }) = _ProfitFigures;

  factory ProfitFigures.fromJson(Map<String, dynamic> json) => _$ProfitFiguresFromJson(json);
}
