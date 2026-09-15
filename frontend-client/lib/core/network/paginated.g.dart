// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PageMeta _$PageMetaFromJson(Map<String, dynamic> json) => _PageMeta(
  currentPage: (json['current_page'] as num).toInt(),
  perPage: (json['per_page'] as num).toInt(),
  lastPage: (json['last_page'] as num).toInt(),
  total: (json['total'] as num).toInt(),
);

Map<String, dynamic> _$PageMetaToJson(_PageMeta instance) => <String, dynamic>{
  'current_page': instance.currentPage,
  'per_page': instance.perPage,
  'last_page': instance.lastPage,
  'total': instance.total,
};
