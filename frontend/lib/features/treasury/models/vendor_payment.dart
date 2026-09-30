/// دفعات الموردين — what the company paid a vendor, and what it still owes. TREASURY-DESIGN §٨.
///
/// Plain classes for the same reason as `treasury_models.dart`.
library;

/// One row of a vendor's or a purchase order's payments.
class VendorPayment {
  const VendorPayment({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.amount,
    required this.isReversed,
    required this.isReversible,
    this.purchaseOrderId,
    this.methodLabel,
    this.accountName,
    this.paidAt,
    this.notes,
    this.recorderName,
  });

  final int id;

  /// `payment`, `reversal` or `opening_debt`.
  final String type;
  final String typeLabel;
  final String amount;
  final int? purchaseOrderId;
  final String? methodLabel;

  /// The drawer it left — none on an opening debt, which moved no money.
  final String? accountName;
  final DateTime? paidAt;
  final String? notes;
  final String? recorderName;
  final bool isReversed;
  final bool isReversible;

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

/// Paid and still owed on one purchase order.
///
/// [remaining] is null on an order from before the treasury: its payments were never recorded,
/// so the owner chose to show nothing owed on it rather than its whole total.
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
      payments: rows
          .whereType<Map<String, dynamic>>()
          .map(VendorPayment.fromJson)
          .toList(growable: false),
    );
  }
}
