// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_payment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_OrderPayment _$OrderPaymentFromJson(Map<String, dynamic> json) =>
    _OrderPayment(
      id: (json['id'] as num).toInt(),
      orderId: (json['order_id'] as num).toInt(),
      type: $enumDecode(
        _$OrderPaymentTypeEnumMap,
        json['type'],
        unknownValue: OrderPaymentType.unknown,
      ),
      typeLabel: json['type_label'] as String,
      amount: json['amount'] as String,
      excessAmount: json['excess_amount'] as String? ?? '0.00',
      isReversed: json['is_reversed'] as bool? ?? false,
      isReversible: json['is_reversible'] as bool? ?? false,
      hasReceipt: json['has_receipt'] as bool? ?? false,
      receiptIsImage: json['receipt_is_image'] as bool? ?? false,
      method: $enumDecodeNullable(
        _$PaymentMethodEnumMap,
        json['method'],
        unknownValue: PaymentMethod.unknown,
      ),
      methodLabel: json['method_label'] as String?,
      reference: json['reference'] as String?,
      receiptUrl: json['receipt_url'] as String?,
      receiptFilename: json['receipt_filename'] as String?,
      receiptSizeBytes: (json['receipt_size_bytes'] as num?)?.toInt(),
      notes: json['notes'] as String?,
      reversesPaymentId: (json['reverses_payment_id'] as num?)?.toInt(),
      reversal: json['reversal'] == null
          ? null
          : OrderPaymentReversal.fromJson(
              json['reversal'] as Map<String, dynamic>,
            ),
      recordedBy: json['recorder'] == null
          ? null
          : PaymentRecorder.fromJson(json['recorder'] as Map<String, dynamic>),
      paidAt: json['paid_at'] == null
          ? null
          : DateTime.parse(json['paid_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      requiresReview: json['requires_review'] as bool? ?? false,
      isReviewed: json['is_reviewed'] as bool? ?? false,
      reviewedAt: json['reviewed_at'] == null
          ? null
          : DateTime.parse(json['reviewed_at'] as String),
      reviewedBy: json['reviewer'] == null
          ? null
          : PaymentRecorder.fromJson(json['reviewer'] as Map<String, dynamic>),
      canReview: json['can_review'] as bool? ?? false,
      canUnreview: json['can_unreview'] as bool? ?? false,
      reviewBlockedReason: json['review_blocked_reason'] as String?,
      order: json['order'] == null
          ? null
          : PaymentOrderRef.fromJson(json['order'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$OrderPaymentToJson(_OrderPayment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'type': _$OrderPaymentTypeEnumMap[instance.type]!,
      'type_label': instance.typeLabel,
      'amount': instance.amount,
      'excess_amount': instance.excessAmount,
      'is_reversed': instance.isReversed,
      'is_reversible': instance.isReversible,
      'has_receipt': instance.hasReceipt,
      'receipt_is_image': instance.receiptIsImage,
      'method': _$PaymentMethodEnumMap[instance.method],
      'method_label': instance.methodLabel,
      'reference': instance.reference,
      'receipt_url': instance.receiptUrl,
      'receipt_filename': instance.receiptFilename,
      'receipt_size_bytes': instance.receiptSizeBytes,
      'notes': instance.notes,
      'reverses_payment_id': instance.reversesPaymentId,
      'reversal': instance.reversal?.toJson(),
      'recorder': instance.recordedBy?.toJson(),
      'paid_at': instance.paidAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
      'requires_review': instance.requiresReview,
      'is_reviewed': instance.isReviewed,
      'reviewed_at': instance.reviewedAt?.toIso8601String(),
      'reviewer': instance.reviewedBy?.toJson(),
      'can_review': instance.canReview,
      'can_unreview': instance.canUnreview,
      'review_blocked_reason': instance.reviewBlockedReason,
      'order': instance.order?.toJson(),
    };

const _$OrderPaymentTypeEnumMap = {
  OrderPaymentType.payment: 'payment',
  OrderPaymentType.reversal: 'reversal',
  OrderPaymentType.refund: 'refund',
  OrderPaymentType.writeOff: 'write_off',
  OrderPaymentType.excessKept: 'excess_kept',
  OrderPaymentType.unknown: 'unknown',
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.bankTransfer: 'bank_transfer',
  PaymentMethod.bankCard: 'bank_card',
  PaymentMethod.libyana: 'libyana',
  PaymentMethod.unknown: 'unknown',
};

_PaymentOrderRef _$PaymentOrderRefFromJson(Map<String, dynamic> json) =>
    _PaymentOrderRef(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      customerName: json['customer_name'] as String?,
    );

Map<String, dynamic> _$PaymentOrderRefToJson(_PaymentOrderRef instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'customer_name': instance.customerName,
    };

_OrderPaymentReversal _$OrderPaymentReversalFromJson(
  Map<String, dynamic> json,
) => _OrderPaymentReversal(
  id: (json['id'] as num).toInt(),
  reason: json['reason'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$OrderPaymentReversalToJson(
  _OrderPaymentReversal instance,
) => <String, dynamic>{
  'id': instance.id,
  'reason': instance.reason,
  'created_at': instance.createdAt?.toIso8601String(),
};

_PaymentRecorder _$PaymentRecorderFromJson(Map<String, dynamic> json) =>
    _PaymentRecorder(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      employeeCode: json['employee_code'] as String?,
    );

Map<String, dynamic> _$PaymentRecorderToJson(_PaymentRecorder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'employee_code': instance.employeeCode,
    };

_PaymentSummary _$PaymentSummaryFromJson(Map<String, dynamic> json) =>
    _PaymentSummary(
      grandTotal: json['grand_total'] as String,
      paidAmount: json['paid_amount'] as String,
      writtenOffAmount: json['written_off_amount'] as String? ?? '0.00',
      excessAmount: json['excess_amount'] as String? ?? '0.00',
      remainingAmount: json['remaining_amount'] as String,
      paymentStatus: $enumDecode(
        _$PaymentStatusEnumMap,
        json['payment_status'],
        unknownValue: PaymentStatus.unknown,
      ),
      paymentStatusLabel: json['payment_status_label'] as String,
      hasUnrecordedMoney: json['has_unrecorded_money'] as bool? ?? false,
    );

Map<String, dynamic> _$PaymentSummaryToJson(_PaymentSummary instance) =>
    <String, dynamic>{
      'grand_total': instance.grandTotal,
      'paid_amount': instance.paidAmount,
      'written_off_amount': instance.writtenOffAmount,
      'excess_amount': instance.excessAmount,
      'remaining_amount': instance.remainingAmount,
      'payment_status': _$PaymentStatusEnumMap[instance.paymentStatus]!,
      'payment_status_label': instance.paymentStatusLabel,
      'has_unrecorded_money': instance.hasUnrecordedMoney,
    };

const _$PaymentStatusEnumMap = {
  PaymentStatus.unpaid: 'unpaid',
  PaymentStatus.partiallyPaid: 'partially_paid',
  PaymentStatus.paid: 'paid',
  PaymentStatus.overpaid: 'overpaid',
  PaymentStatus.writtenOff: 'written_off',
  PaymentStatus.unknown: 'unknown',
};

_OrderLedger _$OrderLedgerFromJson(Map<String, dynamic> json) => _OrderLedger(
  payments: (json['payments'] as List<dynamic>)
      .map((e) => OrderPayment.fromJson(e as Map<String, dynamic>))
      .toList(),
  summary: PaymentSummary.fromJson(json['summary'] as Map<String, dynamic>),
);

Map<String, dynamic> _$OrderLedgerToJson(_OrderLedger instance) =>
    <String, dynamic>{
      'payments': instance.payments.map((e) => e.toJson()).toList(),
      'summary': instance.summary.toJson(),
    };
