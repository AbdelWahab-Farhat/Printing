import 'package:freezed_annotation/freezed_annotation.dart';

part 'fund_share.freezed.dart';
part 'fund_share.g.dart';

/// نصيبُه من الصندوق: ما وضعه فيه، ووحداتُه، ونسبتُه في الفترة الجارية، وما تساويه حصتُه اليوم.
///
/// **شاشتان تقرآنه، وتعريفٌ واحد.** بوابتُه يقرؤها هو، وصفحتُه يقرؤها المدير؛ والخادمُ يبنيه لهما
/// بحسابٍ واحد (`FundStanding`)، فمكانُه هنا مع المستثمر لا في البوابة.
///
/// **«قيمة حصتي» يقولها الخادم ولا تُحسب هنا.** هي وحداتُه × سعرَ الوحدة، والسعرُ قسمةُ قيمة
/// الصندوق — نقدِه وبضاعتِه ومستحقّاتِه ناقصَ ما يدين به — على وحداته. حسابٌ ثانٍ على الهاتف هو
/// الذي يخالف الخادمَ يوم تتغيّر قاعدة.
@freezed
abstract class FundShare with _$FundShare {
  const factory FundShare({
    /// ما وضعه في الصندوق ولم يستردّه — سطرُه في لوحة الصندوق، وسقفُ ما يستردّه.
    @Default('0.00') String capital,

    required String units,
    @JsonKey(name: 'unit_price') required String unitPrice,

    /// وحداتُه × السعر — ما يساويه نصيبُه لو قُوِّم اليوم.
    required String value,

    /// نسبتُه من ربح هذه الفترة. مربوطةٌ بالفترة لا بالحاضر: نافذةُ الاكتتاب في أوّلها بابُ
    /// الفترة **التالية**، فمن اكتتب فيها لا يقاسم شهراً بدأ قبل أن يصل مالُه.
    @JsonKey(name: 'share_percent') required String sharePercent,

    /// **صفرٌ بجانب مالٍ في الصندوق سؤالٌ لا خبر.** هذه هي إجابتُه: نصيبُه يبدأ من الفترة
    /// القادمة، فلا يحسب أن مالَه ضاع.
    @JsonKey(name: 'share_starts_next_period')
    @Default(false)
    bool shareStartsNextPeriod,

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
