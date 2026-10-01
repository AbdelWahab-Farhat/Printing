/// دفعات الموردين — ما دفعته الشركة لمورد، وما بقي عليها. TREASURY-DESIGN §٨.
///
/// أصنافٌ عادية للسبب نفسه الذي في `treasury_models.dart`.
library;

import 'package:dayaa/core/utils/fixed_point.dart';

/// صفٌّ واحد من دفعات مورد أو أمر شراء.
class VendorPayment {
  const VendorPayment({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.amount,
    required this.isReversed,
    required this.isReversible,
    this.purchaseOrderId,
    this.reversesPaymentId,
    this.methodLabel,
    this.accountName,
    this.paidAt,
    this.notes,
    this.recorderName,
  });

  final int id;

  /// `payment` أو `reversal` أو `opening_debt` أو `credit` («خصم من المورد»).
  final String type;
  final String typeLabel;
  final String amount;
  final int? purchaseOrderId;

  /// الدفعة التي يعكسها هذا الصف، إن كان عكساً.
  final int? reversesPaymentId;
  final String? methodLabel;

  /// الدرج الذي خرج منه المال — لا درج لدَينٍ افتتاحي، لم يتحرك فيه مال.
  final String? accountName;
  final DateTime? paidAt;
  final String? notes;
  final String? recorderName;
  final bool isReversed;
  final bool isReversible;

  /// مالٌ عاد إلى الدرج: عكسُ دفعةٍ سُجِّلت خطأً.
  bool get isReversal => type == 'reversal';

  /// دَينٌ يوم الافتتاح: لم يتحرك فيه مال، فلا إشارة له.
  bool get isOpeningDebt => type == 'opening_debt';

  /// «خصم من المورد» — نقصٌ في الشحنة أو تخفيض: يُنقص ما علينا ولا يحرّك مالاً، فلا إشارة له.
  bool get isCredit => type == 'credit';

  /// الدفعة نفسها بعد أن عُكست: مشطوبة، ولا تُعكس مرةً ثانية.
  VendorPayment markedReversed() => VendorPayment(
    id: id,
    type: type,
    typeLabel: typeLabel,
    amount: amount,
    isReversed: true,
    isReversible: false,
    purchaseOrderId: purchaseOrderId,
    reversesPaymentId: reversesPaymentId,
    methodLabel: methodLabel,
    accountName: accountName,
    paidAt: paidAt,
    notes: notes,
    recorderName: recorderName,
  );

  factory VendorPayment.fromJson(Map<String, dynamic> json) {
    final account = json['treasury_account'];
    final recorder = json['recorder'];
    final paidAt = json['paid_at'];

    return VendorPayment(
      id: (json['id'] as num).toInt(),
      type: json['type']?.toString() ?? '',
      typeLabel: json['type_label']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0.00',
      purchaseOrderId: (json['purchase_order_id'] as num?)?.toInt(),
      reversesPaymentId: (json['reverses_payment_id'] as num?)?.toInt(),
      methodLabel: json['method_label']?.toString(),
      accountName: account is Map<String, dynamic> ? account['name']?.toString() : null,
      paidAt: paidAt is String ? DateTime.tryParse(paidAt)?.toLocal() : null,
      notes: json['notes']?.toString(),
      recorderName: recorder is Map<String, dynamic> ? recorder['name']?.toString() : null,
      isReversed: json['is_reversed'] == true,
      isReversible: json['is_reversible'] == true,
    );
  }
}

/// المدفوع والمتبقي على أمر شراءٍ واحد.
///
/// [remaining] فارغٌ على أمرٍ سابق للخزينة: دفعاته لم تُسجَّل قط، فاختار المالك ألّا يُظهر عليه
/// متبقياً بدل أن يُظهر إجماليه كله.
class PurchaseOrderPayments {
  const PurchaseOrderPayments({
    required this.paid,
    required this.predatesTreasury,
    required this.payments,
    this.total,
    this.remaining,
    this.credited = '0.00',
    this.payableUpTo,
  });

  final String? total;
  final String paid;

  /// The most one payment may be — what is left, or on an order from before the treasury its
  /// total less what was paid on it since. Null on a cancelled order. TREASURY-DESIGN §٢٠.
  final String? payableUpTo;

  /// «خصم من المورد» — what the vendor knocked off this order: a short delivery, a discount.
  final String credited;
  final String? remaining;
  final bool predatesTreasury;
  final List<VendorPayment> payments;

  /// بعد صفٍّ سجّله الخادم — دفعةٍ أو خصم: الصفُّ أعلى القائمة، والأرقامُ تتحرّك بمبلغه.
  ///
  /// **جمعٌ على تعريف الخادم نفسه** (`VendorPaymentSummary`: المدفوع = الدفعات − عكوسها، والخصم
  /// = الخصومات − عكوسها، والمتبقي = الإجمالي − المدفوع − الخصم، وما يُدفع = المتبقي أو — لأمرٍ
  /// قبل الخزينة — إجماليه ناقصاً ما دُفع وخُصم منذ النظام)، فلا يحتاج الصفُّ الجديد إعادةَ قراءة
  /// القسم كله. والدَّينُ الافتتاحي لا يمسّ أرقام الأمر.
  PurchaseOrderPayments withPayment(VendorPayment payment) =>
      _moved(payment, payment.amount, payments: [payment, ...payments]);

  /// بعد عكس [original]: صفُّ العكس أعلى القائمة، والأصل مشطوب، وأرقامُه ترجع بمبلغه.
  PurchaseOrderPayments withReversal(VendorPayment original, VendorPayment reversal) => _moved(
    original,
    '-${reversal.amount}',
    payments: [
      reversal,
      for (final payment in payments)
        if (payment.id == original.id) payment.markedReversed() else payment,
    ],
  );

  /// [by] على ما يحرّكه نوعُ [row]: الدفعةُ المدفوعَ، والخصمُ الخصمَ، وكلاهما المتبقي وما يُدفع.
  PurchaseOrderPayments _moved(
    VendorPayment row,
    String by, {
    required List<VendorPayment> payments,
  }) {
    final settles = row.type == 'payment' || row.isCredit;

    String? less(String? value) =>
        value == null || !settles ? value : _money(subtractDecimals(value, by));

    return PurchaseOrderPayments(
      total: total,
      paid: row.type == 'payment' ? _money(addDecimals(paid, by)) : paid,
      credited: row.isCredit ? _money(addDecimals(credited, by)) : credited,
      remaining: less(remaining),
      payableUpTo: less(payableUpTo),
      predatesTreasury: predatesTreasury,
      payments: payments,
    );
  }

  /// منزلتان كما يرسل الخادم المال، لا ثلاث كما يجمع `fixed_point`.
  static String _money(String value) => fromThousandths(thousandths(value), scale: 2);

  factory PurchaseOrderPayments.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rows = json['payments'] is List ? json['payments'] as List : const [];

    return PurchaseOrderPayments(
      total: summary['total']?.toString(),
      paid: summary['paid']?.toString() ?? '0.00',
      credited: summary['credited']?.toString() ?? '0.00',
      remaining: summary['remaining']?.toString(),
      payableUpTo: summary['payable_up_to']?.toString(),
      predatesTreasury: summary['predates_treasury'] == true,
      payments: [
        for (final row in rows.whereType<Map<String, dynamic>>()) VendorPayment.fromJson(row),
      ],
    );
  }
}

/// «الحساب مع المورد» — what the company owes one vendor across all their orders. TREASURY-DESIGN
/// §٢٠: owed from the moment an order is raised, at its full total.
class VendorAccount {
  const VendorAccount({
    required this.ordered,
    required this.openingDebt,
    required this.paid,
    required this.credited,
    required this.owed,
    required this.payments,
    this.treasuryAccountId,
    this.paidOnOldOrders = '0.00',
  });

  /// Paid on orders from before the treasury — apart from [owed], whose debt never held them.
  final String paidOnOldOrders;

  /// Every live order's total, from the treasury on.
  final String ordered;
  final String openingDebt;
  final String paid;
  final String credited;
  final String owed;
  final List<VendorPayment> payments;

  /// The vendor's «علينا» account — its page is the statement. Null until anything was owed.
  final int? treasuryAccountId;

  factory VendorAccount.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final rows = json['payments'] is List ? json['payments'] as List : const [];

    return VendorAccount(
      ordered: summary['ordered']?.toString() ?? '0.00',
      openingDebt: summary['opening_debt']?.toString() ?? '0.00',
      paid: summary['paid']?.toString() ?? '0.00',
      credited: summary['credited']?.toString() ?? '0.00',
      owed: summary['owed']?.toString() ?? '0.00',
      paidOnOldOrders: summary['paid_on_old_orders']?.toString() ?? '0.00',
      treasuryAccountId: (json['treasury_account_id'] as num?)?.toInt(),
      payments: rows
          .whereType<Map<String, dynamic>>()
          .map(VendorPayment.fromJson)
          .toList(growable: false),
    );
  }
}
