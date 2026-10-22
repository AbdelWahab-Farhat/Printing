/// Whether Nawris heard about a change to an order's money.
///
/// Comes back beside every payment, refund and cancelled entry while a parcel is out, and from
/// «إعادة إبلاغ نورس». **The money is saved either way** — what this says is whether the courier
/// now knows. When [warning] is not null they do not: they are still collecting [nawrisAsks], and
/// whoever took the money is the one who can still ring them.
///
/// A plain class rather than a generated one: it is read once, shown once, and never stored.
class CarrierMoneySync {
  const CarrierMoneySync({
    required this.told,
    required this.parcelCode,
    required this.nawrisAsks,
    required this.shouldAsk,
    this.reason,
    this.warning,
  });

  factory CarrierMoneySync.fromJson(Map<String, dynamic> json) => CarrierMoneySync(
    told: json['told'] as bool? ?? false,
    parcelCode: json['parcel_code'] as String? ?? '',
    nawrisAsks: json['nawris_asks'] as String? ?? '0.00',
    shouldAsk: json['should_ask'] as String? ?? '0.00',
    reason: json['reason'] as String?,
    warning: json['warning'] as String?,
  );

  final bool told;
  final String parcelCode;

  /// What Nawris holds for us, without their own fee — and what it should.
  final String nawrisAsks;
  final String shouldAsk;

  /// Their refusal, in their words.
  final String? reason;

  /// The sentence to show, written by the server; null when Nawris took the change.
  final String? warning;
}

/// The parcel out with Nawris, as the payments screen sees it **before** money is taken.
///
/// Before, because after can be too late: Nawris has refused edits once the courier holds the
/// parcel, and the person at the counter is the one who can still ring the courier.
class CarrierMoneyNotice {
  const CarrierMoneyNotice({
    required this.parcelCode,
    required this.nawrisAsks,
    required this.notice,
    this.moneyOutOfSync = false,
    this.reason,
  });

  factory CarrierMoneyNotice.fromJson(Map<String, dynamic> json) => CarrierMoneyNotice(
    parcelCode: json['parcel_code'] as String? ?? '',
    nawrisAsks: json['nawris_asks'] as String? ?? '0.00',
    notice: json['notice'] as String? ?? '',
    moneyOutOfSync: json['money_out_of_sync'] as bool? ?? false,
    reason: json['reason'] as String?,
  );

  final String parcelCode;
  final String nawrisAsks;

  /// The server's sentence for the form.
  final String notice;

  /// An earlier change already never reached them.
  final bool moneyOutOfSync;
  final String? reason;

  /// What the form shows: the notice, and the earlier refusal when there is one.
  String get message => moneyOutOfSync
      ? '$notice\nتنبيه: تغييرٌ سابق لم يصل نورس — ما زالت تطلب $nawrisAsks.'
      : notice;

  Map<String, dynamic> toJson() => {
    'parcel_code': parcelCode,
    'nawris_asks': nawrisAsks,
    'notice': notice,
    'money_out_of_sync': moneyOutOfSync,
    'reason': reason,
  };
}
