import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_share.freezed.dart';
part 'period_share.g.dart';

/// What one participant's capital was worth in one **closed** period, and what he was paid.
///
/// **Frozen the day the period closed, and never recomputed.** This answers «لماذا أخذت هذا المبلغ
/// في سبتمبر؟» asked in December — after three more months of capital moving, when the live weights
/// on the pool's screen bear no relation to the ones that were applied. Deriving it again from
/// today's ledger would answer a different question.
@freezed
abstract class PeriodShare with _$PeriodShare {
  const factory PeriodShare({
    required int id,
    @JsonKey(name: 'investment_period_id') required int investmentPeriodId,

    @JsonKey(name: 'investor_id') required int investorId,
    @JsonKey(name: 'investor_name') String? investorName,

    /// The company's row. `sharePercent` on it is 100 of its own side, which is what it is — the
    /// figure that means something for the company is [netShare], because its take is the residual
    /// of the division rather than a slice of the investors' half.
    @JsonKey(name: 'is_company') @Default(false) bool isCompany,

    /// What he had in the pool when the period closed.
    @Default('0.00') String capital,

    /// His weight of the investors' half, as applied.
    @JsonKey(name: 'share_percent') @Default('0.0000') String sharePercent,

    /// What the division actually gave him — **negative in a losing period**.
    @JsonKey(name: 'net_share') @Default('0.00') String netShare,
  }) = _PeriodShare;

  factory PeriodShare.fromJson(Map<String, dynamic> json) =>
      _$PeriodShareFromJson(json);
}
