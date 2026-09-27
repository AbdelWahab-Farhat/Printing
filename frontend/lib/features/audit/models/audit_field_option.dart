import 'package:flutter/foundation.dart';

/// One field a history can be searched by — «سعر الوحدة» on an order line.
///
/// The server sends the list with the history (`meta.fields`), and only the fields that history
/// actually touches, so every one of them leads to at least one card. [key] is what goes back as
/// `?field=`; it carries the kind of record as well as the column, because a label is not a
/// column — «التصنيف» is a different column on a product than on a stock item.
@immutable
class AuditFieldOption {
  const AuditFieldOption({required this.key, required this.label, this.subjectLabel});

  /// Null for anything that is not a field entry — a malformed row is skipped, not shown.
  static AuditFieldOption? tryParse(Object? json) {
    if (json is! Map) return null;

    final key = json['key'];
    final label = json['label'];
    if (key is! String || label is! String) return null;

    final subjectLabel = json['subject_label'];

    return AuditFieldOption(
      key: key,
      label: label,
      subjectLabel: subjectLabel is String ? subjectLabel : null,
    );
  }

  final String key;

  /// What the field is called — what the person types to find it.
  final String label;

  /// Whose field it is — «بند الطلبية» — for the times two labels read alike.
  final String? subjectLabel;

  @override
  bool operator ==(Object other) => other is AuditFieldOption && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
