import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/pagination/paged_cubit.dart';
import 'package:dayaa/core/pagination/paged_state.dart';
import 'package:dayaa/features/audit/models/activity_log_entry.dart';
import 'package:dayaa/features/audit/models/audit_event.dart';
import 'package:dayaa/features/audit/models/audit_field_option.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/audit/usecases/get_activity_log.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Change;

/// A record's history, paged and filterable by what happened and by which field it touched.
///
/// It inherits everything a list needs — the request-id guard, the append-on-load-more, keeping
/// what is on screen when a later page fails — and adds only *which* record, *which* event and
/// *which* field.
///
/// `PagedCubit`'s free-text search is deliberately not wired: the API takes no term. The field
/// search is a pick from a list the server sent, not a term — see [fields].
class ActivityLogCubit extends PagedCubit<ActivityLogEntry> {
  ActivityLogCubit({
    required this.subject,
    required this.recordId,
    required GetActivityLog getActivityLog,
  }) : _getActivityLog = getActivityLog;

  final AuditSubject subject;
  final int recordId;
  final GetActivityLog _getActivityLog;

  AuditEvent? _event;
  AuditFieldOption? _field;
  Map<AuditEvent, int> _counts = const {};
  List<AuditFieldOption> _fields = const [];

  /// Which kind of change is being shown, or null for all of them.
  AuditEvent? get event => _event;

  /// Which field the history is narrowed to, or null for every field.
  AuditFieldOption? get field => _field;

  /// The fields this history can be searched by — what the search box suggests from.
  ///
  /// From `meta`, and only the fields this record's entries actually touch, so a suggestion
  /// never leads to an empty list. The server builds it from the whole trail whatever filter is
  /// active, and it is kept across reloads for the same reason as [eventCounts].
  List<AuditFieldOption> get fields => _fields;

  /// How many entries of each kind the **whole** trail holds — the numbers on the chips.
  ///
  /// Read from `meta`, never counted from what is loaded: the second would be a lie the moment
  /// the history is longer than one page, and for a customer of any age it always is. Empty
  /// until the first page arrives, which is why a chip shows no badge rather than a zero.
  ///
  /// Kept across the reload a filter causes, deliberately. The chips are the control being
  /// used; numbers that blink out and back while the list behind them fetches make the row
  /// twitch under the thumb that is tapping it.
  Map<AuditEvent, int> get eventCounts => _counts;

  @override
  void onChange(Change<PagedState<ActivityLogEntry>> change) {
    super.onChange(change);

    final next = change.nextState;
    if (next is! PagedLoaded<ActivityLogEntry>) return;

    final counts = _countsIn(next.page);
    if (counts.isNotEmpty) _counts = counts;

    final fields = _fieldsIn(next.page);
    if (fields != null) _fields = fields;
  }

  /// Null when the page carries no list at all — a later page of an older server, say — so
  /// the list already known is not wiped by a page that simply did not repeat it.
  static List<AuditFieldOption>? _fieldsIn(Paginated<ActivityLogEntry> page) {
    final fields = page.extraMeta['fields'];
    if (fields is! List) return null;

    return [for (final json in fields) ?AuditFieldOption.tryParse(json)];
  }

  static Map<AuditEvent, int> _countsIn(Paginated<ActivityLogEntry> page) {
    final counts = page.extraMeta['event_counts'];
    if (counts is! Map) return const {};

    return {
      for (final event in AuditEvent.values)
        if (counts[event.wire] case final int total) event: total,
    };
  }

  /// Narrows to one kind of change, or clears the filter with null.
  ///
  /// Re-reads from page one, because this is a different question rather than a subset of the
  /// answer already on screen. A no-op when the filter has not moved: tapping the chip that is
  /// already active should not cost a request.
  Future<void> filterBy(AuditEvent? event) async {
    if (event == _event) return;

    _event = event;

    await load();
  }

  /// Narrows to the entries about one field, or clears the field with null.
  ///
  /// Kept alongside the event filter rather than replacing it: «who *changed* the price» is the
  /// two of them together.
  Future<void> filterByField(AuditFieldOption? field) async {
    if (field == _field) return;

    _field = field;

    await load();
  }

  @override
  Object identityOf(ActivityLogEntry item) => item.id;

  @override
  Future<Either<Failure, Paginated<ActivityLogEntry>>> fetchPage({
    String? search,
    required int page,
  }) => _getActivityLog(subject, recordId, event: _event, field: _field?.key, page: page);
}
