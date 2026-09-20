import 'package:freezed_annotation/freezed_annotation.dart';

part 'company_settings.freezed.dart';
part 'company_settings.g.dart';

/// إعدادات الشركة — the four numbers every pool runs on.
///
/// **Global, and therefore shared by every صندوق.** One calendar for all of them, so a close is
/// one action over every pool rather than a date remembered per pool (§4.2). The alternative was
/// a pool whose month ended on the 3rd sitting next to one that ended on the 28th, and a person
/// having to know which.
///
/// **A change here can only ever affect future periods.** «Next close» and «next settlement» are
/// derived — the open period's end date, and the last settlement plus the interval — never
/// stored. So a closed period is unreachable from this screen by construction rather than by a
/// guard somebody has to remember.
@freezed
abstract class CompanySettings with _$CompanySettings {
  const factory CompanySettings({
    /// The investors' half of each pool's net profit; the company keeps the rest as the
    /// operator's cut. Seeded into a pool when it is opened and **frozen there** — changing it
    /// here never rewrites a pool that already exists, because that was the term its partners
    /// were shown.
    @JsonKey(name: 'investor_profit_share_percent')
    @Default('50.00')
    String investorProfitSharePercent,

    /// How long a profit period runs. A close divides that period and opens the next.
    @JsonKey(name: 'profit_period_months') @Default(1) int profitPeriodMonths,

    /// The longer review cycle — how often the books are asserted against the goods.
    @JsonKey(name: 'settlement_period_months')
    @Default(6)
    int settlementPeriodMonths,

    /// How many days into a period capital may still arrive and work the whole of it.
    ///
    /// **Zero means a strict boundary**: money offered on day one of a period joins the next.
    /// The window exists because ownership is a plain capital ratio, and a ratio is only exact
    /// if capital does not move inside the period it is measured over.
    @JsonKey(name: 'entry_grace_days') @Default(3) int entryGraceDays,

    /// How many months an investor's capital must stay in a pool before he may ask for it back.
    ///
    /// Measured from his **first** money into that pool, not the latest — otherwise topping up
    /// would restart his clock, which is the opposite of what a minimum term means. **Zero is no
    /// minimum**, and is how the system behaved before this existed.
    ///
    /// The company's own capital is exempt: it is the operator, not a partner who might take a
    /// month's profit and leave.
    @JsonKey(name: 'minimum_term_months') @Default(0) int minimumTermMonths,

    @JsonKey(name: 'updated_at') String? updatedAt,
  }) = _CompanySettings;

  factory CompanySettings.fromJson(Map<String, dynamic> json) =>
      _$CompanySettingsFromJson(json);
}
