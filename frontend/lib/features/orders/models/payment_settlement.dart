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

/// The page's period chips.
///
/// **The week starts on Saturday** — the shop's week, the owner's choice — so «هذا الأسبوع» on a
/// Tuesday is Saturday to today.
enum SettlementPeriod {
  today('اليوم'),
  thisWeek('هذا الأسبوع'),
  thisMonth('هذا الشهر'),
  all('الكل'),
  custom('من – إلى');

  const SettlementPeriod(this.label);

  final String label;

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

  /// Where payments wait to be settled — Nawris, a driver, «مصرف علي». The page's filter chips.
  final List<SettlementAccount> sources;

  /// Every active cash box, bank and wallet — where money may be settled to.
  final List<SettlementAccount> destinations;
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
