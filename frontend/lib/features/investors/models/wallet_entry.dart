import 'package:freezed_annotation/freezed_annotation.dart';

part 'wallet_entry.freezed.dart';
part 'wallet_entry.g.dart';

/// سطرٌ في سجلّ حركات المستثمر — إيداعٌ، سحبٌ، اشتراكٌ في الصندوق، ربحٌ، خسارة، أو عكسُ واحدٍ منها.
///
/// **الاسمُ والإشارةُ من الخادم، لا من النوع هنا.** «تمويل صفقة» و«اشتراك في الصندوق» صفٌّ واحد
/// بنوعٍ واحد، والذي يفرّقهما أين يقع — والخادمُ يعرف ذلك. وإشارةُ المبلغ من الرصيد الذي حرّكه
/// الصفّ فعلاً، فلا يخمّن التطبيقُ اتجاهاً.
@freezed
abstract class WalletEntry with _$WalletEntry {
  const WalletEntry._();

  const factory WalletEntry({
    required int id,
    required String type,
    @JsonKey(name: 'type_label') required String typeLabel,

    /// `capital` · `investment` · `profit` · `loss` — وعكسُ الحركة يأخذ عائلةَ ما عكسه.
    String? category,

    required String amount,

    /// «-3000.00» لما أنقص رصيده — من الرصيد الذي حرّكه الصفّ فعلاً.
    @JsonKey(name: 'signed_amount') required String signedAmount,

    String? method,
    String? reference,
    WalletEntryDeal? deal,
    WalletEntryPeriod? period,

    /// ما اشتراه الاشتراكُ من وحدات، أو ما ألغاه الاسترداد — `null` لكلّ ما سواهما.
    @JsonKey(name: 'fund_units') WalletEntryUnits? fundUnits,

    @JsonKey(name: 'reverses_entry_id') int? reversesEntryId,
    @JsonKey(name: 'is_reversed') @Default(false) bool isReversed,

    /// يقوله الخادم: ما سُجّل بيدٍ ولم يُعكس بعد. الأرباحُ لا تُعكس من هنا أبداً.
    @JsonKey(name: 'can_be_reversed') @Default(false) bool canBeReversed,

    @JsonKey(name: 'occurred_at') DateTime? occurredAt,
    String? notes,
    @JsonKey(name: 'recorded_by') WalletEntryActor? recordedBy,
  }) = _WalletEntry;

  factory WalletEntry.fromJson(Map<String, dynamic> json) => _$WalletEntryFromJson(json);

  /// صفُّ العكس نفسُه — يُقرأ ملغًى كالصفّ الذي ألغاه، فلا يُجمع أحدُهما بالعين دون الآخر.
  bool get isReversal => type == 'reversal';

  bool get isVoid => isReversed || isReversal;

  bool get isNegative => signedAmount.startsWith('-');
}

@freezed
abstract class WalletEntryDeal with _$WalletEntryDeal {
  const factory WalletEntryDeal({
    required int id,
    required String code,
    @JsonKey(name: 'is_fund') @Default(false) bool isFund,
  }) = _WalletEntryDeal;

  factory WalletEntryDeal.fromJson(Map<String, dynamic> json) => _$WalletEntryDealFromJson(json);
}

@freezed
abstract class WalletEntryPeriod with _$WalletEntryPeriod {
  const factory WalletEntryPeriod({required int id, required String code}) = _WalletEntryPeriod;

  factory WalletEntryPeriod.fromJson(Map<String, dynamic> json) =>
      _$WalletEntryPeriodFromJson(json);
}

@freezed
abstract class WalletEntryUnits with _$WalletEntryUnits {
  const factory WalletEntryUnits({
    required String units,
    @JsonKey(name: 'unit_price') required String unitPrice,
    @JsonKey(name: 'locked_until') String? lockedUntil,
  }) = _WalletEntryUnits;

  factory WalletEntryUnits.fromJson(Map<String, dynamic> json) =>
      _$WalletEntryUnitsFromJson(json);
}

@freezed
abstract class WalletEntryActor with _$WalletEntryActor {
  const factory WalletEntryActor({required int id, required String name}) = _WalletEntryActor;

  factory WalletEntryActor.fromJson(Map<String, dynamic> json) =>
      _$WalletEntryActorFromJson(json);
}

/// عائلاتُ السجلّ كما يفلترها الخادم — `null` تعني الكلّ.
enum WalletEntryCategory {
  capital('capital', 'رأس المال'),
  investment('investment', 'الاستثمار'),
  profit('profit', 'الأرباح'),
  loss('loss', 'الخسائر');

  const WalletEntryCategory(this.value, this.label);

  final String value;
  final String label;
}
