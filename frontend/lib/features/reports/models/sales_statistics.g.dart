// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sales_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SalesStatistics _$SalesStatisticsFromJson(Map<String, dynamic> json) =>
    _SalesStatistics(
      period: StatisticsPeriod.fromJson(json['period'] as Map<String, dynamic>),
      salesValue: SalesValue.fromJson(
        json['sales_value'] as Map<String, dynamic>,
      ),
      byType: (json['by_type'] as List<dynamic>)
          .map((e) => BagTypeRow.fromJson(e as Map<String, dynamic>))
          .toList(),
      topItems:
          (json['top_items'] as List<dynamic>?)
              ?.map((e) => TopSellingItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <TopSellingItem>[],
      weightComparison: WeightComparison.fromJson(
        json['weight_comparison'] as Map<String, dynamic>,
      ),
      printedPieces: PrintedPieces.fromJson(
        json['printed_pieces'] as Map<String, dynamic>,
      ),
      ordersCounted: (json['orders_counted'] as num).toInt(),
    );

Map<String, dynamic> _$SalesStatisticsToJson(_SalesStatistics instance) =>
    <String, dynamic>{
      'period': instance.period.toJson(),
      'sales_value': instance.salesValue.toJson(),
      'by_type': instance.byType.map((e) => e.toJson()).toList(),
      'top_items': instance.topItems.map((e) => e.toJson()).toList(),
      'weight_comparison': instance.weightComparison.toJson(),
      'printed_pieces': instance.printedPieces.toJson(),
      'orders_counted': instance.ordersCounted,
    };

_StatisticsPeriod _$StatisticsPeriodFromJson(Map<String, dynamic> json) =>
    _StatisticsPeriod(from: json['from'] as String, to: json['to'] as String);

Map<String, dynamic> _$StatisticsPeriodToJson(_StatisticsPeriod instance) =>
    <String, dynamic>{'from': instance.from, 'to': instance.to};

_SalesValue _$SalesValueFromJson(Map<String, dynamic> json) => _SalesValue(
  plain: json['plain'] as String,
  printed: json['printed'] as String,
  total: json['total'] as String,
);

Map<String, dynamic> _$SalesValueToJson(_SalesValue instance) =>
    <String, dynamic>{
      'plain': instance.plain,
      'printed': instance.printed,
      'total': instance.total,
    };

_BagTypeRow _$BagTypeRowFromJson(Map<String, dynamic> json) => _BagTypeRow(
  type: json['type'] as String,
  value: json['value'] as String,
  weightKg: json['weight_kg'] as String,
  plainKg: json['plain_kg'] as String,
  printedKg: json['printed_kg'] as String,
  pieces: (json['pieces'] as num).toInt(),
  plainValue: json['plain_value'] as String? ?? '0.00',
  printedValue: json['printed_value'] as String? ?? '0.00',
  weighed: json['weighed'] as bool?,
  sizes:
      (json['sizes'] as List<dynamic>?)
          ?.map((e) => BagSizeRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <BagSizeRow>[],
);

Map<String, dynamic> _$BagTypeRowToJson(_BagTypeRow instance) =>
    <String, dynamic>{
      'type': instance.type,
      'value': instance.value,
      'weight_kg': instance.weightKg,
      'plain_kg': instance.plainKg,
      'printed_kg': instance.printedKg,
      'pieces': instance.pieces,
      'plain_value': instance.plainValue,
      'printed_value': instance.printedValue,
      'weighed': instance.weighed,
      'sizes': instance.sizes.map((e) => e.toJson()).toList(),
    };

_BagSizeRow _$BagSizeRowFromJson(Map<String, dynamic> json) => _BagSizeRow(
  widthCm: (json['width_cm'] as num?)?.toInt(),
  heightCm: (json['height_cm'] as num?)?.toInt(),
  value: json['value'] as String,
  plainValue: json['plain_value'] as String,
  printedValue: json['printed_value'] as String,
  weightKg: json['weight_kg'] as String?,
  plainKg: json['plain_kg'] as String?,
  printedKg: json['printed_kg'] as String?,
  pieces: (json['pieces'] as num?)?.toInt(),
);

Map<String, dynamic> _$BagSizeRowToJson(_BagSizeRow instance) =>
    <String, dynamic>{
      'width_cm': instance.widthCm,
      'height_cm': instance.heightCm,
      'value': instance.value,
      'plain_value': instance.plainValue,
      'printed_value': instance.printedValue,
      'weight_kg': instance.weightKg,
      'plain_kg': instance.plainKg,
      'printed_kg': instance.printedKg,
      'pieces': instance.pieces,
    };

_TopSellingItem _$TopSellingItemFromJson(Map<String, dynamic> json) =>
    _TopSellingItem(
      product: json['product'] as String,
      variant: json['variant'] as String,
      type: json['type'] as String,
      kind: $enumDecode(
        _$SaleKindEnumMap,
        json['kind'],
        unknownValue: SaleKind.printed,
      ),
      widthCm: (json['width_cm'] as num?)?.toInt(),
      heightCm: (json['height_cm'] as num?)?.toInt(),
      value: json['value'] as String,
      sharePercent: json['share_percent'] as String,
      weightKg: json['weight_kg'] as String?,
      pieces: (json['pieces'] as num?)?.toInt(),
    );

Map<String, dynamic> _$TopSellingItemToJson(_TopSellingItem instance) =>
    <String, dynamic>{
      'product': instance.product,
      'variant': instance.variant,
      'type': instance.type,
      'kind': _$SaleKindEnumMap[instance.kind]!,
      'width_cm': instance.widthCm,
      'height_cm': instance.heightCm,
      'value': instance.value,
      'share_percent': instance.sharePercent,
      'weight_kg': instance.weightKg,
      'pieces': instance.pieces,
    };

const _$SaleKindEnumMap = {
  SaleKind.plain: 'plain',
  SaleKind.printed: 'printed',
};

_WeightComparison _$WeightComparisonFromJson(Map<String, dynamic> json) =>
    _WeightComparison(
      plainKg: json['plain_kg'] as String,
      printedKg: json['printed_kg'] as String,
      totalKg: json['total_kg'] as String,
      printedSharePercent: json['printed_share_percent'] as String,
      weightCoveragePercent: json['weight_coverage_percent'] as String,
    );

Map<String, dynamic> _$WeightComparisonToJson(_WeightComparison instance) =>
    <String, dynamic>{
      'plain_kg': instance.plainKg,
      'printed_kg': instance.printedKg,
      'total_kg': instance.totalKg,
      'printed_share_percent': instance.printedSharePercent,
      'weight_coverage_percent': instance.weightCoveragePercent,
    };

_PrintedPieces _$PrintedPiecesFromJson(Map<String, dynamic> json) =>
    _PrintedPieces(
      count: (json['count'] as num).toInt(),
      weightKg: json['weight_kg'] as String,
    );

Map<String, dynamic> _$PrintedPiecesToJson(_PrintedPieces instance) =>
    <String, dynamic>{'count': instance.count, 'weight_kg': instance.weightKg};
