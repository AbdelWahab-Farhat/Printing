import 'package:dayaa/features/investors/models/fund_share.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'investor_portfolio.freezed.dart';
part 'investor_portfolio.g.dart';

/// What an investor's money is doing — the whole of what he is shown.
///
/// **Every amount is a `String`, never a `double`.** Money round-tripped through a float is how
/// `2500.10` becomes `2500.099999`; the same rule the rest of this app follows for every figure
/// it displays.
///
/// The three profit fields are separate on purpose and must stay that way on screen — three
/// gates in a row, §٠.٨ of the fund spec. [profitAwaitingDelivery] is computed, not booked: orders
/// past «جاهزة» that have not reached the customer. [profitInDeals] is booked and his, but not
/// money he can ask for yet. [profitAvailable] has passed both gates and is the only figure a
/// withdrawal can draw on. One number for all three would either promise him money he cannot
/// have or hide money he has already made.
@freezed
abstract class InvestorPortfolio with _$InvestorPortfolio {
  const factory InvestorPortfolio({
    required InvestorIdentity investor,

    /// His money with the company, committed to nothing.
    @JsonKey(name: 'capital_in_wallet') required String capitalInWallet,

    /// His money currently financing goods on a shelf.
    @JsonKey(name: 'capital_in_deals') required String capitalInDeals,

    @JsonKey(name: 'capital_total') required String capitalTotal,

    /// **ربح قيد التسليم** — طلبياتٌ بلغت «جاهزة» ولم تُسلَّم. محسوبٌ لا مقيَّد: هو ما سيقيّده
    /// التسليمُ بعينه، ولا صفَّ له في الدفتر بعد.
    @JsonKey(name: 'profit_awaiting_delivery') @Default('0.00') String profitAwaitingDelivery,

    /// كم طلبيةً وراء [profitAwaitingDelivery].
    @JsonKey(name: 'orders_awaiting_delivery') @Default(0) int ordersAwaitingDelivery,

    /// **أرباح معلّقة** — سُلِّمت فقُيِّدت، والصندوقُ منها. له، ولا يُسحب حتى تنقضي فترتُها
    /// وتُحصَّل طلبيتُها.
    @JsonKey(name: 'profit_in_deals') required String profitInDeals,

    /// **أرباح متاحة للسحب** — اجتمع شرطاها، والسحبُ يقرأ منها وحدها.
    @JsonKey(name: 'profit_available') required String profitAvailable,

    @JsonKey(name: 'profit_withdrawn') required String profitWithdrawn,

    @Default(<InvestorDealLine>[]) List<InvestorDealLine> deals,

    /// **موقفُه من الصندوق المستمرّ** — وهو اليوم الطريقُ الذي يدخل منه شريكٌ جديد.
    ///
    /// `null` لمن لا وحداتِ له: شريكٌ قديم في صفقاتٍ وحدها. ولا يُعرض صفراً عندها، لأن «لا
    /// شيء بعد» و«صفر» جوابان مختلفان.
    FundShare? fund,
  }) = _InvestorPortfolio;

  factory InvestorPortfolio.fromJson(Map<String, dynamic> json) =>
      _$InvestorPortfolioFromJson(json);
}

/// Who he is, as the portal names him.
@freezed
abstract class InvestorIdentity with _$InvestorIdentity {
  const factory InvestorIdentity({
    required int id,

    /// «I7» — what staff say out loud, and what he quotes when he calls.
    required String code,
    required String name,
  }) = _InvestorIdentity;

  factory InvestorIdentity.fromJson(Map<String, dynamic> json) =>
      _$InvestorIdentityFromJson(json);
}

/// One deal he is in, and his own standing in it.
///
/// Deliberately carries no quantity, no unit cost and nobody else's share: what he financed and
/// what it earned him is the whole of his business with us.
@freezed
abstract class InvestorDealLine with _$InvestorDealLine {
  const factory InvestorDealLine({
    required int id,
    String? code,
    String? status,

    /// The Arabic to print. Sent by the server so the app keeps no translation table in step.
    @JsonKey(name: 'status_label') String? statusLabel,

    /// His slice **of the investors' share** of this deal — not of its whole profit.
    @JsonKey(name: 'share_percent') required String sharePercent,

    required String capital,
    required String profit,
  }) = _InvestorDealLine;

  factory InvestorDealLine.fromJson(Map<String, dynamic> json) =>
      _$InvestorDealLineFromJson(json);
}
