import 'package:flutter/foundation.dart';

/// The four texts staff copy and send to customers, as the admin has worded them.
///
/// Plain classes rather than Freezed: read once from the server, shown in a form, and never
/// copied or compared field by field.
@immutable
class CustomerMessages {
  const CustomerMessages({required this.placeholder, required this.messages});

  factory CustomerMessages.fromJson(Map<String, dynamic> json) => CustomerMessages(
    placeholder: json['placeholder'] as String? ?? '{رقم_الفاتورة}',
    messages: [
      for (final item in json['messages'] as List<dynamic>? ?? const [])
        CustomerMessageTemplate.fromJson(item as Map<String, dynamic>),
    ],
  );

  /// The token the server replaces with the order's number — `{رقم_الفاتورة}`.
  final String placeholder;

  /// In the server's order: ready (pickup, delivery), then return (courier, carrier).
  final List<CustomerMessageTemplate> messages;
}

@immutable
class CustomerMessageTemplate {
  const CustomerMessageTemplate({
    required this.key,
    required this.label,
    required this.body,
    required this.defaultBody,
    required this.isCustomised,
  });

  factory CustomerMessageTemplate.fromJson(Map<String, dynamic> json) => CustomerMessageTemplate(
    key: json['key'] as String,
    label: json['label'] as String,
    body: json['body'] as String,
    defaultBody: json['default_body'] as String,
    isCustomised: json['is_customised'] as bool? ?? false,
  );

  /// `ready_pickup`, `ready_delivery`, `return_courier`, `return_carrier`.
  final String key;

  /// What the screen calls it — the server's Arabic.
  final String label;

  /// The wording in force: the admin's when set, the built-in one otherwise.
  final String body;

  /// The built-in wording, for «استعادة النص الافتراضي».
  final String defaultBody;

  final bool isCustomised;
}
