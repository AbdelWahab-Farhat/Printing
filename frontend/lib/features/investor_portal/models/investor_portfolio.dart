import 'package:freezed_annotation/freezed_annotation.dart';

part 'investor_portfolio.freezed.dart';
part 'investor_portfolio.g.dart';

/// What an investor's money is doing — the whole of what he is shown.
///
/// **Every amount is a `String`, never a `double`.** Money round-tripped through a float is how
/// `2500.10` becomes `2500.099999`; the same rule the rest of this app follows for every figure
/// it displays.
///
/// The two profit fields are separate on purpose and must stay that way on screen.
/// [profitInDeals] is what his running deals have earned him so far — real, his, and moving with
/// every delivery, but not money he can ask for yet. [profitAvailable] is what a closed deal has
/// released into his wallet, and is the only figure a withdrawal can draw on. Showing one number
/// for both would either promise him money he cannot have or hide money he has already made.
@freezed
abstract class InvestorPortfolio with _$InvestorPortfolio {
  const factory InvestorPortfolio({
    required InvestorIdentity investor,

    /// His money with the company, committed to nothing.
    @JsonKey(name: 'capital_in_wallet') required String capitalInWallet,

    /// His money currently financing goods on a shelf.
    @JsonKey(name: 'capital_in_deals') required String capitalInDeals,

    @JsonKey(name: 'capital_total') required String capitalTotal,

    /// Earned by deals still running. His, but not yet his to take.
    @JsonKey(name: 'profit_in_deals') required String profitInDeals,

    /// Released by a closed deal, and withdrawable.
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

/// نصيبُه من الصندوق: وحداتُه، ونسبتُه في الفترة الجارية، وما تساويه حصتُه اليوم.
///
/// **«قيمة حصتي» يقولها الخادم ولا تُحسب هنا.** هي وحداتُه × سعرَ الوحدة، والسعرُ قسمةُ قيمة
/// الصندوق — نقدِه وبضاعتِه ومستحقّاتِه ناقصَ ما يدين به — على وحداته. حسابٌ ثانٍ على الهاتف هو
/// الذي يخالف الخادمَ يوم تتغيّر قاعدة.
@freezed
abstract class FundShare with _$FundShare {
  const factory FundShare({
    required String units,
    @JsonKey(name: 'unit_price') required String unitPrice,

    /// وحداتُه × السعر — ما يساويه نصيبُه لو قُوِّم اليوم.
    required String value,

    /// نسبتُه من ربح هذه الفترة. مربوطةٌ بالفترة لا بالحاضر: من دخل بعد إغلاق النافذة نسبتُه
    /// في التالية.
    @JsonKey(name: 'share_percent') required String sharePercent,

    /// ما انقضت مدةُ حبسه من وحداته — وحده ما يمكن أن يخرج.
    @JsonKey(name: 'unlocked_units') @Default('0.000000') String unlockedUnits,

    FundPeriodBrief? period,

    /// **دفعةً دفعة**، لأن الحبس كذلك: لكل إيداعٍ مدّتُه. رقمٌ واحد كان سيقول «محبوسٌ إلى
    /// ٢٠٢٨» لمن نصفُ ماله يخرج في ٢٠٢٧.
    @Default(<FundDeposit>[]) List<FundDeposit> deposits,
  }) = _FundShare;

  factory FundShare.fromJson(Map<String, dynamic> json) => _$FundShareFromJson(json);
}

/// الفترةُ الجارية كما يراها المستثمر — بلا أرقام الشركة.
@freezed
abstract class FundPeriodBrief with _$FundPeriodBrief {
  const factory FundPeriodBrief({
    required String code,
    @JsonKey(name: 'starts_on') required String startsOn,
    @JsonKey(name: 'ends_on') required String endsOn,
    @JsonKey(name: 'accepts_capital') @Default(false) bool acceptsCapital,
  }) = _FundPeriodBrief;

  factory FundPeriodBrief.fromJson(Map<String, dynamic> json) =>
      _$FundPeriodBriefFromJson(json);
}

/// دفعةُ رأس مالٍ واحدة ومدّةُ حبسها.
@freezed
abstract class FundDeposit with _$FundDeposit {
  const factory FundDeposit({
    required String units,
    required String amount,
    @JsonKey(name: 'locked_until') String? lockedUntil,
    @JsonKey(name: 'is_locked') @Default(true) bool isLocked,
  }) = _FundDeposit;

  factory FundDeposit.fromJson(Map<String, dynamic> json) => _$FundDepositFromJson(json);
}
