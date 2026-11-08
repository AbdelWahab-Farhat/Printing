import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:flutter/foundation.dart' show immutable;

/// «تسوية الدفعات» — the two lists the page switches between. TREASURY-DESIGN §٢٣.
enum SettlementState {
  /// Money still where it landed, on orders not yet settled. Oldest first; the dates are the day
  /// the money was taken.
  pending('pending', 'بانتظار التسوية'),

  /// Payments settled on their own. Newest settlement first; the dates are the day settled.
  settled('settled', 'مسوّاة');

  const SettlementState(this.wire, this.label);

  final String wire;
  final String label;
}

/// The period a list of «مراجعة وتسوية الدفعات» shows.
///
/// **The week starts on Saturday** — the shop's week, the owner's choice — so «هذا الأسبوع» on a
/// Tuesday is Saturday to today.
///
/// [custom] is no chip: it is «من» / «إلى» from the advanced filter (2026-10-08).
enum SettlementPeriod {
  today('اليوم'),
  thisWeek('هذا الأسبوع'),
  thisMonth('هذا الشهر'),
  all('الكل'),
  custom('من – إلى');

  const SettlementPeriod(this.label);

  final String label;

  /// The chips under the search box, in this order — «الكل» first, and picked to begin with.
  static const List<SettlementPeriod> chips = [all, today, thisWeek, thisMonth];

  /// The first and last day, or null for «الكل». «من – إلى» knows no dates here and answers
  /// null — the Cubit holds them. [now] is passed so the week can be tested without a clock.
  ({DateTime from, DateTime to})? rangeAt(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    return switch (this) {
      SettlementPeriod.today => (from: today, to: today),
      // DateTime.weekday: Monday 1 … Saturday 6, Sunday 7 — days since Saturday is (w + 1) % 7.
      SettlementPeriod.thisWeek => (
        from: today.subtract(Duration(days: (today.weekday + 1) % 7)),
        to: today,
      ),
      SettlementPeriod.thisMonth => (from: DateTime(now.year, now.month), to: today),
      SettlementPeriod.all || SettlementPeriod.custom => null,
    };
  }
}

/// One account on the page: a place payments wait in, or one they may be settled to.
@immutable
class SettlementAccount {
  const SettlementAccount({
    required this.id,
    required this.name,
    this.kind,
    this.kindLabel,
  });

  factory SettlementAccount.fromJson(Map<String, dynamic> json) => SettlementAccount(
    id: json['id'] as int,
    name: json['name'] as String,
    kind: json['kind'] as String?,
    kindLabel: json['kind_label'] as String?,
  );

  final int id;
  final String name;
  final String? kind;
  final String? kindLabel;

  @override
  bool operator ==(Object other) =>
      other is SettlementAccount && other.id == id && other.name == name && other.kind == kind;

  @override
  int get hashCode => Object.hash(id, name, kind);
}

/// `GET /order-payments/settlement-accounts`.
@immutable
class SettlementAccounts {
  const SettlementAccounts({required this.sources, required this.destinations});

  factory SettlementAccounts.fromJson(Map<String, dynamic> json) => SettlementAccounts(
    sources: [
      for (final row in (json['sources'] as List<dynamic>? ?? const []))
        SettlementAccount.fromJson(row as Map<String, dynamic>),
    ],
    destinations: [
      for (final row in (json['destinations'] as List<dynamic>? ?? const []))
        SettlementAccount.fromJson(row as Map<String, dynamic>),
    ],
  );

  /// Where payments wait to be settled — Nawris, a driver, «مصرف علي».
  final List<SettlementAccount> sources;

  /// Every active cash box, bank and wallet — where money may be settled to.
  final List<SettlementAccount> destinations;
}

/// زرٌّ من «نوع الدفعة»: طريقة دفع أو حساب، لا الاثنان.
///
/// «حوالة» طريقة، أمّا «كاش نورس» و«مكتب قرجي» فطريقتهما كاش والحساب هو الفرق، فالخادم يقول أيّهما
/// يحمل الزرّ ولا يعرف التطبيق أسماء الحسابات.
@immutable
class PaymentKind {
  const PaymentKind({required this.label, this.method, this.accountId});

  factory PaymentKind.fromJson(Map<String, dynamic> json) {
    final wire = json['method'] as String?;

    return PaymentKind(
      label: json['label'] as String,
      method: PaymentMethod.values.where((method) => method.wire == wire).firstOrNull,
      accountId: json['account_id'] as int?,
    );
  }

  final String label;
  final PaymentMethod? method;
  final int? accountId;

  /// زرٌّ بطريقةٍ لا تعرفها هذه النسخة لا يحمل شيئاً، ولو رُسم لقرأ كـ«الكل».
  bool get narrows => method != null || accountId != null;
}

/// موظفٌ في ورقة الفلتر: اسمٌ ورقمٌ لا غير.
@immutable
class PaymentPerson {
  const PaymentPerson({required this.id, required this.name});

  factory PaymentPerson.fromJson(Map<String, dynamic> json) =>
      PaymentPerson(id: json['id'] as int, name: json['name'] as String);

  final int id;
  final String name;

  @override
  bool operator ==(Object other) => other is PaymentPerson && other.id == id && other.name == name;

  @override
  int get hashCode => Object.hash(id, name);
}

/// `GET /order-payments/filter-options` — ما تعرضه ورقة الفلتر. أسماءٌ لا أرصدة.
@immutable
class PaymentFilterOptions {
  const PaymentFilterOptions({
    this.kinds = const [],
    this.accounts = const [],
    this.recorders = const [],
    this.settlers = const [],
  });

  factory PaymentFilterOptions.fromJson(Map<String, dynamic> json) => PaymentFilterOptions(
    kinds: [
      for (final row in (json['kinds'] as List<dynamic>? ?? const []))
        PaymentKind.fromJson(row as Map<String, dynamic>),
    ].where((kind) => kind.narrows).toList(growable: false),
    accounts: [
      for (final row in (json['accounts'] as List<dynamic>? ?? const []))
        SettlementAccount.fromJson(row as Map<String, dynamic>),
    ],
    recorders: _people(json['recorders']),
    settlers: _people(json['settlers']),
  );

  static List<PaymentPerson> _people(Object? rows) => [
    for (final row in (rows as List<dynamic>? ?? const []))
      PaymentPerson.fromJson(row as Map<String, dynamic>),
  ];

  /// أزرار «نوع الدفعة».
  final List<PaymentKind> kinds;

  /// كل حسابٍ قد تكون الدفعة فيه — «حساب آخر» و«سُوّيت إلى».
  final List<SettlementAccount> accounts;

  /// مَن سجّل قيداً.
  final List<PaymentPerson> recorders;

  /// مَن سوّى دفعة.
  final List<PaymentPerson> settlers;
}

/// ما يضيّقه الفلتر المتقدّم فوق التواريخ والحساب والنوع. مشتركٌ بين القائمتين، و[toAccountId]
/// و[settledBy] لـ«مسوّاة» وحدها.
///
/// **يُقارَن بالقيمة**: يُسلَّم إلى المستودع كاملاً، فتقول الاختبارات ما أُرسل بسطرٍ واحد.
@immutable
class PaymentDetailFilter {
  const PaymentDetailFilter({
    this.method,
    this.recordedBy,
    this.minAmount,
    this.maxAmount,
    this.toAccountId,
    this.settledBy,
  });

  final PaymentMethod? method;
  final int? recordedBy;

  /// نصّاً لا عدداً، كما يُحفظ كل مبلغ في التطبيق: يصل إلى الخادم كما كُتب.
  final String? minAmount;
  final String? maxAmount;

  final int? toAccountId;
  final int? settledBy;

  bool get isEmpty => toQuery().isEmpty;

  /// ما يُضاف إلى الطلب. الفارغ لا يُرسل.
  Map<String, Object> toQuery() => {
    if (method case final method?) 'method': method.wire,
    'recorded_by': ?recordedBy,
    'amount_min': ?minAmount,
    'amount_max': ?maxAmount,
    'to_account_id': ?toAccountId,
    'settled_by': ?settledBy,
  };

  @override
  bool operator ==(Object other) =>
      other is PaymentDetailFilter &&
      other.method == method &&
      other.recordedBy == recordedBy &&
      other.minAmount == minAmount &&
      other.maxAmount == maxAmount &&
      other.toAccountId == toAccountId &&
      other.settledBy == settledBy;

  @override
  int get hashCode => Object.hash(method, recordedBy, minAmount, maxAmount, toAccountId, settledBy);
}

/// One payment in a settle request.
@immutable
class SettleRow {
  const SettleRow({required this.paymentId, this.fee});

  final int paymentId;

  /// What the carrier kept, as typed — only on money held in custody.
  final String? fee;

  Map<String, dynamic> toJson() => {
    'payment_id': paymentId,
    if (fee != null && fee!.trim().isNotEmpty) 'fee': fee,
  };
}
