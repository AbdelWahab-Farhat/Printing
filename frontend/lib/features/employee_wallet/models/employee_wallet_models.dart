/// «محفظة الموظف» — ما ترسله نقاطها وما يُكتب إليها. Docs/employees/EMPLOYEE-WALLET-DESIGN.md.
///
/// **المال نصٌّ من السلك إلى الشاشة**: «1250.00» هو ما قاله الخادم.
library;

import 'package:freezed_annotation/freezed_annotation.dart';

part 'employee_wallet_models.freezed.dart';
part 'employee_wallet_models.g.dart';

DateTime? _localDate(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

/// `category.name` لمن يدير المحافظ، و`category_name` لصاحبها — موردان، وسؤالٌ واحد.
Object? _categoryName(Map<dynamic, dynamic> json, String key) =>
    json[key] ?? (json['category'] as Map<dynamic, dynamic>?)?['name'];

Object? _reversalReason(Map<dynamic, dynamic> json, String _) =>
    (json['reversal'] as Map<dynamic, dynamic>?)?['reason'];

Object? _recorderName(Map<dynamic, dynamic> json, String _) =>
    (json['recorder'] as Map<dynamic, dynamic>?)?['name'];

/// سطرٌ واحد من محفظة موظف.
///
/// **نموذجٌ واحد لموردين**: من يدير المحافظ يصله الحساب واسم من سجّل، وصاحبُ المحفظة لا يصله شيءٌ
/// منهما (§١٠). ما لا يرسله الخادم يبقى فارغاً، فلا يُرسم، ولا يُخمَّن هنا.
@freezed
abstract class EmployeeWalletEntry with _$EmployeeWalletEntry {
  const EmployeeWalletEntry._();

  const factory EmployeeWalletEntry({
    required int id,

    /// `deposit` · `credit` · `withdrawal` · `adjustment_credit` · `adjustment_debit` · `reversal`.
    /// نوعٌ لا يعرفه هذا الإصدار يُرسم بـ[typeLabel] الخادم.
    required String type,
    @JsonKey(name: 'type_label') required String typeLabel,

    /// `in` يزيد المحفظة، و`out` ينقصها. **الخادم يقرّره**: العكسُ عكسُ ما يعكسه.
    required String direction,

    /// موجبٌ دائماً — الاتجاه في [direction].
    required String amount,

    /// غائبٌ عن سطر صاحب المحفظة: محفظتُه هو.
    @JsonKey(name: 'user_id') int? userId,

    /// يُرسل في «المعاملات المالية» وحدها، فهي تجمع الموظفين كلهم.
    EmployeeWalletPerson? user,

    /// الإيداع والسحب وحدهما.
    @JsonKey(name: 'method_label') String? methodLabel,

    /// المستحق وحده.
    @JsonKey(name: 'category_name', readValue: _categoryName) String? categoryName,

    String? notes,
    @JsonKey(name: 'occurred_at', fromJson: _localDate) DateTime? occurredAt,

    /// عُكس — يُرسم مشطوباً.
    @JsonKey(name: 'is_reversed') @Default(false) bool isReversed,

    /// **الخادم وحده يقول إن كان يُعكس من هنا**: الصلاحية، وأنه ليس محفظة القارئ نفسه.
    @JsonKey(name: 'can_reverse') @Default(false) bool canReverse,

    /// سببُ العكس، تحت السطر المشطوب.
    @JsonKey(name: 'reversal_reason', readValue: _reversalReason) String? reversalReason,

    @JsonKey(name: 'recorder_name', readValue: _recorderName) String? recorderName,
  }) = _EmployeeWalletEntry;

  factory EmployeeWalletEntry.fromJson(Map<String, dynamic> json) =>
      _$EmployeeWalletEntryFromJson(json);

  bool get isIn => direction == 'in';

  bool get isReversal => type == 'reversal';

  String? get employeeName => user?.name;

  /// السطر نفسه بعد أن عُكس.
  EmployeeWalletEntry markedReversed(String reason) =>
      copyWith(isReversed: true, canReverse: false, reversalReason: reason);
}

/// صاحب المحفظة، كما يُرسل في السجل الجامع.
@freezed
abstract class EmployeeWalletPerson with _$EmployeeWalletPerson {
  const factory EmployeeWalletPerson({required int id, required String name, String? code}) =
      _EmployeeWalletPerson;

  factory EmployeeWalletPerson.fromJson(Map<String, dynamic> json) =>
      _$EmployeeWalletPersonFromJson(json);
}

/// رأس المحفظة: رصيدها، وما يحقّ لهذا القارئ فيها.
@freezed
abstract class EmployeeWallet with _$EmployeeWallet {
  const factory EmployeeWallet({
    required String balance,

    /// هل يحرّكها هذا القارئ — كاذبٌ لصاحبها، والمدير مستثنى. غائبٌ عن «محفظتي»: قراءةٌ فقط.
    @JsonKey(name: 'can_move') @Default(false) bool canMove,

    /// راتب الموظف، **منه يُقترح مبلغ «رواتب»**. يصل لمن يملك `users.salary` وحده.
    String? salary,
  }) = _EmployeeWallet;

  factory EmployeeWallet.fromJson(Map<String, dynamic> json) => _$EmployeeWalletFromJson(json);
}

/// ما يعود بعد كتابةٍ على المحفظة: السطر الذي كتبه الخادم، والرصيد بعده.
@freezed
abstract class EmployeeWalletWrite with _$EmployeeWalletWrite {
  const factory EmployeeWalletWrite({
    required EmployeeWalletEntry entry,
    required String balance,
  }) = _EmployeeWalletWrite;

  factory EmployeeWalletWrite.fromJson(Map<String, dynamic> json) =>
      _$EmployeeWalletWriteFromJson(json);
}

/// مالٌ عبر الطاولة — ما تكتبه ورقتا الإيداع والسحب، فالحقول نفسها في الاتجاهين.
@freezed
abstract class EmployeeMoneyDraft with _$EmployeeMoneyDraft {
  const factory EmployeeMoneyDraft({
    required String amount,
    required EmployeeWalletMethod method,

    /// `null` لـ«تلقائي»: الخادم يختار الحساب.
    int? treasuryAccountId,
    String? reference,
    String? notes,
    String? receiptPath,
    String? receiptFilename,
  }) = _EmployeeMoneyDraft;
}

/// «مستحق» — كم، وتحت أيّ تصنيف.
@freezed
abstract class EmployeeCreditDraft with _$EmployeeCreditDraft {
  const factory EmployeeCreditDraft({
    required String amount,
    required int categoryId,
    String? notes,
  }) = _EmployeeCreditDraft;
}

/// أيُّ سجلٍّ يُقرأ: محفظةُ موظف، أو المحافظ كلها في «المعاملات المالية»، أو «محفظتي».
@freezed
sealed class EmployeeWalletLedger with _$EmployeeWalletLedger {
  const factory EmployeeWalletLedger.of(int userId) = EmployeeWalletLedgerOf;

  const factory EmployeeWalletLedger.all() = EmployeeWalletLedgerAll;

  const factory EmployeeWalletLedger.mine() = EmployeeWalletLedgerMine;
}

/// فلتر السجل. `adjustment` رقاقةٌ واحدة لنوعين، والخادم يقبلها كما هي.
enum EmployeeWalletEntryFilter {
  all(null, 'الكل'),
  deposit('deposit', 'إيداع'),
  credit('credit', 'مستحق'),
  withdrawal('withdrawal', 'سحب'),
  adjustment('adjustment', 'تعديل');

  const EmployeeWalletEntryFilter(this.wire, this.label);

  final String? wire;
  final String label;

  /// هل يبقى [entry] على القائمة وهذا الفلتر مختار.
  bool covers(EmployeeWalletEntry entry) => switch (this) {
    EmployeeWalletEntryFilter.all => true,
    EmployeeWalletEntryFilter.adjustment => entry.type.startsWith('adjustment'),
    _ => entry.type == wire,
  };
}

/// كيف دخل المال أو خرج — طرق المكتب الأربع في الاتجاهين، قرار صاحب العمل ٢٠٢٦-١١-٠٥.
enum EmployeeWalletMethod {
  cash('cash', 'كاش'),
  bankTransfer('bank_transfer', 'حوالة'),
  bankCard('bank_card', 'بطاقة مصرفية'),
  libyana('libyana', 'ليبيانا');

  const EmployeeWalletMethod(this.wire, this.label);

  final String wire;
  final String label;

  /// الحوالة وحدها تتطلب الواصل، في الاتجاهين — قاعدةُ الخادم وقيدُ القاعدة.
  bool get requiresReceipt => this == EmployeeWalletMethod.bankTransfer;
}
