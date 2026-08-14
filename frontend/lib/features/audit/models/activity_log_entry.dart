import 'package:dayaa/features/audit/models/audit_event.dart';
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

    /// What to call each column that moved — `page_url` → «رابط الصفحة».
    ///
    /// **Sent by the server, never kept here.** The screen used to show raw column names, and
    /// the alternative to this was a dictionary in the app — which is wrong the first morning
    /// somebody adds a column, with no build failing to say so. Carrying only the columns this
    /// entry touched keeps a page of fifteen entries small.
    @JsonKey(name: 'attribute_labels') Map<String, String>? attributeLabels,

    /// And what each of those values *says* — `printing` → «قيد الطباعة».
    ///
    /// Mirrors [changes] half for half rather than being a value → translation map, because a
    /// map cannot hold it: JSON keys are strings, so `12` and `'12'` collide, and `12` in
    /// `customer_id` is not `12` in `city_id`. Only the column plus which half it is on
    /// identifies a value without ambiguity.
    ///
    /// Null against a server that predates it, which is why every read goes through
    /// [valueLabelFor] and falls back to the raw value.
    @JsonKey(name: 'value_labels') AuditValueLabels? valueLabels,

    /// The Arabic for what is inside [properties] — today, the permissions a role gained or
    /// lost. Keyed by the permission itself, which *is* unambiguous in a way a foreign key's
    /// `12` never is.
    @JsonKey(name: 'property_labels') Map<String, Map<String, String>>? propertyLabels,

    @JsonKey(name: 'created_at') DateTime? createdAt,
  }) = _ActivityLogEntry;

  const ActivityLogEntry._();

  factory ActivityLogEntry.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogEntryFromJson(json);

  /// True when this is the line that says the record came into existence.
  bool get isCreation => event == 'created';

  /// Which of the four this is, or null for one this build has no case for.
  AuditEvent? get kind => AuditEvent.tryFromWire(event);

  /// Who to name. «النظام» when nobody did it by hand, which is honest rather than blank.
  String get byWhom => causer?.name ?? 'النظام';

  /// What to call one column.
  ///
  /// Falls back to the raw name, which is exactly what this screen showed before labels
  /// existed. An unlabelled column looking unlabelled is what gets the label written; a guessed
  /// Arabic name would look right and be wrong.
  String labelFor(String field) => attributeLabels?[field] ?? field;

  /// What one value *says*, or null when the server sent no translation for it.
  ///
  /// Null is the common case and not a fault: a name is already Arabic, a total is a number,
  /// and «نعم/لا» this app says for itself. The caller draws the raw value, which is the same
  /// fallback [labelFor] takes for a column nobody has named yet.
  String? valueLabelFor(String field, {required bool old}) =>
      (old ? valueLabels?.old : valueLabels?.attributes)?[field];

  /// The Arabic for one permission, or null for one this server has not named.
  String? permissionLabelFor(String permission) => propertyLabels?['permissions']?[permission];
}

/// What the values in [ActivityLogEntry.changes] say, in Arabic.
///
/// The same two halves as [AuditChanges], because it is read alongside it key for key.
@freezed
abstract class AuditValueLabels with _$AuditValueLabels {
  const factory AuditValueLabels({
    Map<String, String>? old,
    Map<String, String>? attributes,
  }) = _AuditValueLabels;

  factory AuditValueLabels.fromJson(Map<String, dynamic> json) =>
      _$AuditValueLabelsFromJson(json);
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
  const factory AuditChanges({Map<String, dynamic>? old, Map<String, dynamic>? attributes}) =
      _AuditChanges;

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

  /// True when both halves exist — an edit, and the only case that reads as «قبل ← بعد».
  ///
  /// A creation has no "from" and a deletion has no "to"; drawing an arrow for either would
  /// invent a value that never existed.
  bool get isMovement => (old?.isNotEmpty ?? false) && (attributes?.isNotEmpty ?? false);

  /// The values this entry simply states, for the cases that are not a movement.
  ///
  /// A creation states what the record started as; a deletion restates what it last was —
  /// which is the only place that information survives, since the row itself is gone from
  /// every list.
  List<(String, Object?)> get statedValues => [
    for (final entry in (attributes ?? old ?? const <String, dynamic>{}).entries)
      (entry.key, entry.value),
  ];

  /// Whether there is anything at all to draw under the heading.
  bool get isEmpty => (old?.isEmpty ?? true) && (attributes?.isEmpty ?? true);
}
