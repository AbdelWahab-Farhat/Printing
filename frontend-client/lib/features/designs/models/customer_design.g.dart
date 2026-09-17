// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customer_design.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CustomerDesign _$CustomerDesignFromJson(Map<String, dynamic> json) =>
    _CustomerDesign(
      id: (json['id'] as num).toInt(),
      label: json['label'] as String,
      kind:
          $enumDecodeNullable(
            _$DesignKindEnumMap,
            json['kind'],
            unknownValue: DesignKind.unknown,
          ) ??
          DesignKind.unknown,
      kindLabel: json['kind_label'] as String?,
      mimeType: json['mime_type'] as String?,
      originalFilename: json['original_filename'] as String?,
      sizeBytes: (json['size_bytes'] as num?)?.toInt(),
      widthPx: (json['width_px'] as num?)?.toInt(),
      heightPx: (json['height_px'] as num?)?.toInt(),
      fileUrl: json['file_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$CustomerDesignToJson(_CustomerDesign instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'kind': _$DesignKindEnumMap[instance.kind]!,
      'kind_label': instance.kindLabel,
      'mime_type': instance.mimeType,
      'original_filename': instance.originalFilename,
      'size_bytes': instance.sizeBytes,
      'width_px': instance.widthPx,
      'height_px': instance.heightPx,
      'file_url': instance.fileUrl,
      'created_at': instance.createdAt?.toIso8601String(),
    };

const _$DesignKindEnumMap = {
  DesignKind.image: 'image',
  DesignKind.pdf: 'pdf',
  DesignKind.unknown: 'unknown',
};
