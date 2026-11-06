// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nawris_settlement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NawrisSettlementWarning _$NawrisSettlementWarningFromJson(
  Map<String, dynamic> json,
) => _NawrisSettlementWarning(
  code: json['code'] as String,
  message: json['message'] as String,
);

Map<String, dynamic> _$NawrisSettlementWarningToJson(
  _NawrisSettlementWarning instance,
) => <String, dynamic>{'code': instance.code, 'message': instance.message};

_NawrisSettlementLine _$NawrisSettlementLineFromJson(
  Map<String, dynamic> json,
) => _NawrisSettlementLine(
  rowNumber: (json['row_number'] as num).toInt(),
  outcome: $enumDecode(
    _$NawrisSettlementOutcomeEnumMap,
    json['outcome'],
    unknownValue: NawrisSettlementOutcome.unknown,
  ),
  outcomeLabel: json['outcome_label'] as String,
  rawCode: json['raw_code'] as String?,
  rawReceiver: json['raw_receiver'] as String?,
  orderId: (json['order_id'] as num?)?.toInt(),
  orderCode: json['order_code'] as String?,
  previousStatusLabel: json['previous_status_label'] as String?,
  reason: json['reason'] as String?,
  warnings:
      (json['warnings'] as List<dynamic>?)
          ?.map(
            (e) => NawrisSettlementWarning.fromJson(e as Map<String, dynamic>),
          )
          .toList() ??
      const <NawrisSettlementWarning>[],
  heldAmount: json['held_amount'] as String? ?? '0.00',
  feeAmount: json['fee_amount'] as String? ?? '0.00',
);

Map<String, dynamic> _$NawrisSettlementLineToJson(
  _NawrisSettlementLine instance,
) => <String, dynamic>{
  'row_number': instance.rowNumber,
  'outcome': _$NawrisSettlementOutcomeEnumMap[instance.outcome]!,
  'outcome_label': instance.outcomeLabel,
  'raw_code': instance.rawCode,
  'raw_receiver': instance.rawReceiver,
  'order_id': instance.orderId,
  'order_code': instance.orderCode,
  'previous_status_label': instance.previousStatusLabel,
  'reason': instance.reason,
  'warnings': instance.warnings.map((e) => e.toJson()).toList(),
  'held_amount': instance.heldAmount,
  'fee_amount': instance.feeAmount,
};

const _$NawrisSettlementOutcomeEnumMap = {
  NawrisSettlementOutcome.settled: 'settled',
  NawrisSettlementOutcome.alreadySettled: 'already_settled',
  NawrisSettlementOutcome.rejected: 'rejected',
  NawrisSettlementOutcome.leftOut: 'left_out',
  NawrisSettlementOutcome.unknown: 'unknown',
};

_NawrisSettlementSummary _$NawrisSettlementSummaryFromJson(
  Map<String, dynamic> json,
) => _NawrisSettlementSummary(
  rowsCount: (json['rows_count'] as num).toInt(),
  ordersCount: (json['orders_count'] as num).toInt(),
  settledCount: (json['settled_count'] as num).toInt(),
  skippedCount: (json['skipped_count'] as num).toInt(),
  rejectedCount: (json['rejected_count'] as num).toInt(),
  warningsCount: (json['warnings_count'] as num).toInt(),
  leftOutCount: (json['left_out_count'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$NawrisSettlementSummaryToJson(
  _NawrisSettlementSummary instance,
) => <String, dynamic>{
  'rows_count': instance.rowsCount,
  'orders_count': instance.ordersCount,
  'settled_count': instance.settledCount,
  'skipped_count': instance.skippedCount,
  'rejected_count': instance.rejectedCount,
  'warnings_count': instance.warningsCount,
  'left_out_count': instance.leftOutCount,
};

_NawrisSettlementPreview _$NawrisSettlementPreviewFromJson(
  Map<String, dynamic> json,
) => _NawrisSettlementPreview(
  summary: NawrisSettlementSummary.fromJson(
    json['summary'] as Map<String, dynamic>,
  ),
  totalHeld: json['total_held'] as String,
  knownFees: json['known_fees'] as String,
  expectedReceived: json['expected_received'] as String,
  fingerprint: json['fingerprint'] as String,
  fields:
      (json['fields'] as List<dynamic>?)
          ?.map((e) => TransitionField.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <TransitionField>[],
  lines:
      (json['lines'] as List<dynamic>?)
          ?.map((e) => NawrisSettlementLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NawrisSettlementLine>[],
);

Map<String, dynamic> _$NawrisSettlementPreviewToJson(
  _NawrisSettlementPreview instance,
) => <String, dynamic>{
  'summary': instance.summary.toJson(),
  'total_held': instance.totalHeld,
  'known_fees': instance.knownFees,
  'expected_received': instance.expectedReceived,
  'fingerprint': instance.fingerprint,
  'fields': instance.fields.map((e) => e.toJson()).toList(),
  'lines': instance.lines.map((e) => e.toJson()).toList(),
};

_NawrisSettlementImporter _$NawrisSettlementImporterFromJson(
  Map<String, dynamic> json,
) => _NawrisSettlementImporter(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
);

Map<String, dynamic> _$NawrisSettlementImporterToJson(
  _NawrisSettlementImporter instance,
) => <String, dynamic>{'id': instance.id, 'name': instance.name};

_NawrisSettlementImport _$NawrisSettlementImportFromJson(
  Map<String, dynamic> json,
) => _NawrisSettlementImport(
  id: (json['id'] as num).toInt(),
  fileName: json['file_name'] as String,
  summary: NawrisSettlementSummary.fromJson(
    json['summary'] as Map<String, dynamic>,
  ),
  totalHeld: json['total_held'] as String,
  receivedAmount: json['received_amount'] as String,
  feeTotal: json['fee_total'] as String,
  importedBy: json['imported_by'] == null
      ? null
      : NawrisSettlementImporter.fromJson(
          json['imported_by'] as Map<String, dynamic>,
        ),
  differenceReason: json['difference_reason'] as String?,
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => NawrisSettlementLine.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <NawrisSettlementLine>[],
);

Map<String, dynamic> _$NawrisSettlementImportToJson(
  _NawrisSettlementImport instance,
) => <String, dynamic>{
  'id': instance.id,
  'file_name': instance.fileName,
  'summary': instance.summary.toJson(),
  'total_held': instance.totalHeld,
  'received_amount': instance.receivedAmount,
  'fee_total': instance.feeTotal,
  'imported_by': instance.importedBy?.toJson(),
  'difference_reason': instance.differenceReason,
  'created_at': instance.createdAt?.toIso8601String(),
  'items': instance.items.map((e) => e.toJson()).toList(),
};
