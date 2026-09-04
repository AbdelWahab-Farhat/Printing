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

    /// Present on the detail screen only — a list of fifty investors does not walk fifty
    /// ledgers to draw a table.
    InvestorBalances? balances,
  }) = _Investor;

  factory Investor.fromJson(Map<String, dynamic> json) => _$InvestorFromJson(json);
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
