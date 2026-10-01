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

  /// `payment`, `reversal`, `opening_debt` or `credit` («خصم من المورد»).
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
      payments: rows
          .whereType<Map<String, dynamic>>()
          .map(VendorPayment.fromJson)
          .toList(growable: false),
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
