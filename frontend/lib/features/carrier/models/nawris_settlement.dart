import 'package:dayaa/core/utils/validators.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'nawris_settlement.freezed.dart';
part 'nawris_settlement.g.dart';

/// ما يحدث لطلبية واحدة من ملف تسوية النورس.
enum NawrisSettlementOutcome {
  /// تُسوّى، أو سُوّيت في دفعة نُفّذت.
  @JsonValue('settled')
  settled,

  /// كانت مسوّاة، أو تكررت في الملف — ليست خطأً، فرفع الملف مرتين آمن.
  @JsonValue('already_settled')
  alreadySettled,

  /// لن تتحرك، وسببها في [NawrisSettlementLine.reason].
  @JsonValue('rejected')
  rejected,

  /// صالحة، وتركها الموظف لأن مالها لم يصل. تبقى «تم الاستلام» ومالها في عهدة النورس.
  @JsonValue('left_out')
  leftOut,

  /// نتيجة أضافها الخادم بعد هذا الإصدار — تُعرض بما قاله عنها ولا تُسقط الشاشة.
  unknown,
}

/// ما يستحق نظرة ولا يمنع التسوية.
@freezed
abstract class NawrisSettlementWarning with _$NawrisSettlementWarning {
  const factory NawrisSettlementWarning({required String code, required String message}) =
      _NawrisSettlementWarning;

  factory NawrisSettlementWarning.fromJson(Map<String, dynamic> json) =>
      _$NawrisSettlementWarningFromJson(json);
}

/// قرار طلبية واحدة. سطر المعاينة وسطر الدفعة المنفَّذة بشكل واحد، فيُرسمان بعنصر واحد.
@freezed
abstract class NawrisSettlementLine with _$NawrisSettlementLine {
  const factory NawrisSettlementLine({
    /// رقم الصف بعد الترويسة. الصف المركّب يعطي أسطراً بالرقم نفسه.
    @JsonKey(name: 'row_number') required int rowNumber,
    @JsonKey(unknownEnumValue: NawrisSettlementOutcome.unknown)
    required NawrisSettlementOutcome outcome,
    @JsonKey(name: 'outcome_label') required String outcomeLabel,
    @JsonKey(name: 'raw_code') String? rawCode,
    @JsonKey(name: 'raw_receiver') String? rawReceiver,
    @JsonKey(name: 'order_id') int? orderId,
    @JsonKey(name: 'order_code') String? orderCode,
    @JsonKey(name: 'previous_status_label') String? previousStatusLabel,

    /// لماذا لن تتحرك، أو لماذا تُخطّيت — بالعربية كما يُعرض.
    String? reason,
    @Default(<NawrisSettlementWarning>[]) List<NawrisSettlementWarning> warnings,

    /// ما عند النورس لهذه الطلبية. نصّ لا `double`.
    @JsonKey(name: 'held_amount') @Default('0.00') String heldAmount,

    /// أجرة النورس عليها: المعروفة في المعاينة، والمقيَّدة في الدفعة المنفَّذة.
    @JsonKey(name: 'fee_amount') @Default('0.00') String feeAmount,
  }) = _NawrisSettlementLine;

  const NawrisSettlementLine._();

  factory NawrisSettlementLine.fromJson(Map<String, dynamic> json) =>
      _$NawrisSettlementLineFromJson(json);

  bool get hasWarnings => warnings.isNotEmpty;

  bool get isSettling => outcome == NawrisSettlementOutcome.settled;

  /// ما يُعرف به السطر: كود الطلبية، وإلا ما كُتب في الملف.
  String get title => switch ((orderCode, rawReceiver)) {
    (final String code, _) => 'طلبية $code',
    (_, final String receiver) when receiver.isNotEmpty => receiver,
    _ => 'صف $rowNumber',
  };
}

@freezed
abstract class NawrisSettlementSummary with _$NawrisSettlementSummary {
  const factory NawrisSettlementSummary({
    @JsonKey(name: 'rows_count') required int rowsCount,
    @JsonKey(name: 'orders_count') required int ordersCount,
    @JsonKey(name: 'settled_count') required int settledCount,
    @JsonKey(name: 'skipped_count') required int skippedCount,
    @JsonKey(name: 'rejected_count') required int rejectedCount,
    @JsonKey(name: 'warnings_count') required int warningsCount,

    /// في الدفعات المنفَّذة وحدها: المعاينة لا تعرف ما سيتركه الموظف.
    @JsonKey(name: 'left_out_count') @Default(0) int leftOutCount,
  }) = _NawrisSettlementSummary;

  factory NawrisSettlementSummary.fromJson(Map<String, dynamic> json) =>
      _$NawrisSettlementSummaryFromJson(json);
}

/// ما ستفعله الدفعة قبل أن تُفعل. **لا شيء تغيّر حين تُعرض هذه.**
@freezed
abstract class NawrisSettlementPreview with _$NawrisSettlementPreview {
  const factory NawrisSettlementPreview({
    required NawrisSettlementSummary summary,

    /// ما عند النورس للطلبيات التي ستُسوّى وحدها — لا لكل الملف، وهذا ما يُكتب مقابله المبلغ.
    @JsonKey(name: 'total_held') required String totalHeld,
    @JsonKey(name: 'known_fees') required String knownFees,

    /// ما تفتح به خانة «المبلغ المستلم»: ما عنده بعد أجرته المعروفة.
    @JsonKey(name: 'expected_received') required String expectedReceived,

    /// يُعاد مع «تنفيذ»: إن تغيّر شيء منذ هذه المعاينة رفض الخادم ولم يُنفّذ شيء.
    required String fingerprint,

    /// الحسابات التي تسألها شاشة «تم التسوية» عن هذه الطلبيات — بشكل حقول الحركة نفسه.
    @Default(<TransitionField>[]) List<TransitionField> fields,
    @Default(<NawrisSettlementLine>[]) List<NawrisSettlementLine> lines,
  }) = _NawrisSettlementPreview;

  const NawrisSettlementPreview._();

  factory NawrisSettlementPreview.fromJson(Map<String, dynamic> json) =>
      _$NawrisSettlementPreviewFromJson(json);

  bool get canSettle => summary.settledCount > 0;

  /// كم طلبية ستُسوّى بعد أن ترك الموظف [leftOut].
  int settlingCount([Set<int> leftOut = const {}]) => summary.settledCount - leftOut.length;

  /// ما عند النورس لما سيُسوّى. **مجموع الخادم ناقصاً ما تُرك** — لا جمعٌ ثانٍ للأسطر هنا.
  int _heldCents(Set<int> leftOut) => _cents(totalHeld)! - _leftCents(leftOut, (l) => l.heldAmount);

  int _feeCents(Set<int> leftOut) => _cents(knownFees)! - _leftCents(leftOut, (l) => l.feeAmount);

  int _leftCents(Set<int> leftOut, String Function(NawrisSettlementLine) amount) => lines
      .where((line) => line.isSettling && leftOut.contains(line.orderId))
      .fold(0, (sum, line) => sum + _cents(amount(line))!);

  String heldFor([Set<int> leftOut = const {}]) => _amount(_heldCents(leftOut));

  String feesFor([Set<int> leftOut = const {}]) => _amount(_feeCents(leftOut));

  /// ما تفتح به خانة «المبلغ المستلم»: ما عنده لما سيُسوّى بعد أجوره المعروفة.
  String expectedFor([Set<int> leftOut = const {}]) =>
      _amount(_heldCents(leftOut) - _feeCents(leftOut));

  /// هل عند النورس مال لها أصلاً. لا مال: لا مبلغ يُسأل عنه، والتسوية حالة فقط.
  bool holdsMoney([Set<int> leftOut = const {}]) => _heldCents(leftOut) > 0;

  /// هل يلزم أن يُسأل الموظف عن الفرق: المبلغ أقل مما عنده، ولا تشرحه أجوره المعروفة.
  ///
  /// نسخة للعرض فقط — القرار للخادم، وهذا يُظهر السؤال قبل أن يضغط أحد.
  bool hasUnexplainedDifference(String received, [Set<int> leftOut = const {}]) {
    final amount = _cents(received);

    if (amount == null) return false;

    return amount < _heldCents(leftOut) && amount != _heldCents(leftOut) - _feeCents(leftOut);
  }

  /// الفرق كما يُعرض في السؤال.
  String differenceFor(String received, [Set<int> leftOut = const {}]) =>
      _amount(_heldCents(leftOut) - (_cents(received) ?? 0));

  /// أكبر مما عنده لهذه الطلبيات — غالباً لأن التحويل يشمل طلبيات لن تتحرك.
  bool exceedsHeld(String received, [Set<int> leftOut = const {}]) {
    final amount = _cents(received);

    return amount != null && amount > _heldCents(leftOut);
  }

  /// هل اكتمل ما يلزم للضغط على «تنفيذ»: [accounts] أجوبة حقول الحساب بمفاتيحها.
  ///
  /// **الفرق لا يمرّ إلا أجرةً مقصودة.** «ما زال عند النورس» يوقف الزرّ حتى تُترك طلبياته،
  /// لأن طلبية مسوّاة لا تحمل عهدة، ومبلغٌ ناقص بلا جواب كان سيُقيَّد أجرة بلا أن يقصد أحد.
  ///
  /// نسخة للعرض: تُطفئ الزرّ بدل أن يُرفض الموظف بعد الضغط، والخادم يتحقق من كل ذلك من جديد.
  bool canSubmit({
    required String received,
    required String reason,
    required Map<String, String?> accounts,
    NawrisSettlementDifference? difference,
    Set<int> leftOut = const {},
  }) {
    if (settlingCount(leftOut) <= 0) return false;

    if (fields.any((field) => field.isRequired && accounts[field.key] == null)) return false;

    if (!holdsMoney(leftOut)) return true;

    if (_cents(received) == null || exceedsHeld(received, leftOut)) return false;

    if (!hasUnexplainedDifference(received, leftOut)) return true;

    return difference == NawrisSettlementDifference.fee && reason.trim().isNotEmpty;
  }
}

/// جواب الموظف عن فرقٍ لا تشرحه الأجور المعروفة.
enum NawrisSettlementDifference {
  /// احتفظ به النورس: يُقيَّد مصروفاً.
  fee,

  /// لم يصل بعد: تُترك طلبياته، ويبقى في عهدة النورس.
  notArrived,
}

/// الموظف الذي نفّذ الدفعة.
@freezed
abstract class NawrisSettlementImporter with _$NawrisSettlementImporter {
  const factory NawrisSettlementImporter({required int id, required String name}) =
      _NawrisSettlementImporter;

  factory NawrisSettlementImporter.fromJson(Map<String, dynamic> json) =>
      _$NawrisSettlementImporterFromJson(json);
}

/// دفعة نُفّذت. [items] في التفاصيل وحدها.
@freezed
abstract class NawrisSettlementImport with _$NawrisSettlementImport {
  const factory NawrisSettlementImport({
    required int id,
    @JsonKey(name: 'file_name') required String fileName,
    required NawrisSettlementSummary summary,
    @JsonKey(name: 'total_held') required String totalHeld,
    @JsonKey(name: 'received_amount') required String receivedAmount,
    @JsonKey(name: 'fee_total') required String feeTotal,
    @JsonKey(name: 'imported_by') NawrisSettlementImporter? importedBy,
    @JsonKey(name: 'difference_reason') String? differenceReason,
    @JsonKey(name: 'created_at') DateTime? createdAt,
    @Default(<NawrisSettlementLine>[]) List<NawrisSettlementLine> items,
  }) = _NawrisSettlementImport;

  factory NawrisSettlementImport.fromJson(Map<String, dynamic> json) =>
      _$NawrisSettlementImportFromJson(json);
}

/// ما يرسله الموظف مع «تنفيذ».
@immutable
class NawrisSettlementSubmission {
  const NawrisSettlementSubmission({
    required this.fingerprint,
    required this.clientToken,
    this.receivedAmount,
    this.differenceReason,
    this.accounts = const {},
    this.leftOut = const {},
  });

  final String fingerprint;

  /// واحد لكل معاينة، فالضغطة الثانية أو الإعادة بعد انقطاع لا تسوّي مرتين.
  final String clientToken;
  final String? receivedAmount;
  final String? differenceReason;

  /// مفتاح الحقل => الحساب. ما تُرك على «تلقائي» لا يُرسل.
  final Map<String, String> accounts;

  /// طلبيات صالحة لم يصل مالها.
  final Set<int> leftOut;
}

/// قروش إلى نصّ مبلغ، كما يرسله الخادم.
String _amount(int cents) => '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

/// المبلغ بالقروش، أو null إن لم يكن رقماً.
///
/// **أعداد صحيحة لا `double`**: قرشٌ يضيع في التقريب يُظهر خانة السبب لمبلغ صحيح. و`٣٨٠` كما
/// تكتبه لوحة مفاتيح عربية يُقرأ كما تقرؤه الخانة.
int? _cents(String value) {
  final match = RegExp(
    r'^(\d+)(?:\.(\d{1,2})\d*)?$',
  ).firstMatch(Validators.toWesternDigits(value).trim());

  if (match == null) return null;

  return int.parse(match.group(1)!) * 100 + int.parse((match.group(2) ?? '').padRight(2, '0'));
}
