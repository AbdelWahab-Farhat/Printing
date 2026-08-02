import 'package:freezed_annotation/freezed_annotation.dart';

part 'activity_log_entry.freezed.dart';
part 'activity_log_entry.g.dart';

/// One line of history: who changed what, when, and from what to what.
@freezed
abstract class ActivityLogEntry with _$ActivityLogEntry {
  const factory ActivityLogEntry({
    required int id,

    /// `created`, `updated`, `deleted` … with the Arabic beside it, so the app keeps no
    /// translation table in step with the server's.
    required String event,
    @JsonKey(name: 'event_label') String? eventLabel,

    /// The sentence written when it happened — not one composed now. History that rewords
    /// itself when the code changes is not history.
    String? description,

    /// A stable alias like `customer_shop`, never a PHP class name.
    @JsonKey(name: 'subject_type') String? subjectType,
    @JsonKey(name: 'subject_type_label') String? subjectTypeLabel,
    @JsonKey(name: 'subject_id') int? subjectId,

    /// Absent for anything no person did — a seeder, a console command, a queued job.
    AuditCauser? causer,

    AuditChanges? changes,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ActivityLogEntry;

  const ActivityLogEntry._();

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogEntryFromJson(json);

  /// True when this is the line that says the record came into existence.
  bool get isCreation => event == 'created';

  /// Who to name. «النظام» when nobody did it by hand, which is honest rather than blank.
  String get byWhom => causer?.name ?? 'النظام';
}

/// The person behind a change.
@freezed
abstract class AuditCauser with _$AuditCauser {
  const factory AuditCauser({
    int? id,
    required String name,
    @JsonKey(name: 'employee_code') String? employeeCode,
  }) = _AuditCauser;

  factory AuditCauser.fromJson(Map<String, dynamic> json) => _$AuditCauserFromJson(json);
}

/// What actually moved.
///
/// `old` is absent on a creation and `attributes` on a deletion, because neither half exists in
/// those cases.
@freezed
abstract class AuditChanges with _$AuditChanges {
  const factory AuditChanges({
    Map<String, dynamic>? old,
    Map<String, dynamic>? attributes,
  }) = _AuditChanges;

  const AuditChanges._();

  factory AuditChanges.fromJson(Map<String, dynamic> json) => _$AuditChangesFromJson(json);

  /// Every field that moved, as (field, before, after).
  ///
  /// Driven by `attributes` — the new values — because that is the set of things that were
  /// actually written. A key present only in `old` is a column that was dropped from the
  /// payload, which is not a change anybody made.
  List<(String, Object?, Object?)> get fields => [
    for (final entry in (attributes ?? const <String, dynamic>{}).entries)
      (entry.key, old?[entry.key], entry.value),
  ];
}
