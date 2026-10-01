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

  /// `payment` أو `reversal` أو `opening_debt`.
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
  });

  final String? total;
  final String paid;
  final String? remaining;
  final bool predatesTreasury;
  final List<VendorPayment> payments;

  /// بعد دفعةٍ سجّلها الخادم: الصفُّ أعلى القائمة، والمدفوعُ يزيد بمبلغه والمتبقي ينقص.
  ///
  /// **جمعٌ على تعريف الخادم نفسه** (`VendorPaymentSummary`: المدفوع = الدفعات − عكوسها،
  /// والمتبقي = الإجمالي − المدفوع)، فلا يحتاج الصفُّ الجديد إعادةَ قراءة القسم كله.
  PurchaseOrderPayments withPayment(VendorPayment payment) => PurchaseOrderPayments(
    total: total,
    paid: _money(addDecimals(paid, payment.amount)),
    remaining: remaining == null ? null : _money(subtractDecimals(remaining!, payment.amount)),
    predatesTreasury: predatesTreasury,
    payments: [payment, ...payments],
  );

  /// بعد عكس [original]: صفُّ العكس أعلى القائمة، والأصل مشطوب، والمدفوع ينقص بمبلغه.
  PurchaseOrderPayments withReversal(VendorPayment original, VendorPayment reversal) =>
      PurchaseOrderPayments(
        total: total,
        paid: _money(subtractDecimals(paid, reversal.amount)),
        remaining: remaining == null ? null : _money(addDecimals(remaining!, reversal.amount)),
        predatesTreasury: predatesTreasury,
        payments: [
          reversal,
          for (final payment in payments)
            if (payment.id == original.id) payment.markedReversed() else payment,
        ],
      );

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
      remaining: summary['remaining']?.toString(),
      predatesTreasury: summary['predates_treasury'] == true,
      payments: [
        for (final row in rows.whereType<Map<String, dynamic>>()) VendorPayment.fromJson(row),
      ],
    );
  }
}
