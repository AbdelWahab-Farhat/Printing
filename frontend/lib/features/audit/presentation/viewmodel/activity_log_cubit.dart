import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show Change;
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/core/pagination/paged_state.dart';
import 'package:printing/features/audit/models/activity_log_entry.dart';
import 'package:printing/features/audit/models/audit_event.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/audit/usecases/get_activity_log.dart';

/// A record's history, paged and filterable by what happened.
///
/// It inherits everything a list needs — the request-id guard, the append-on-load-more, keeping
/// what is on screen when a later page fails — and adds only *which* record and *which* event.
///
/// Search is deliberately not wired: `PagedCubit` offers it, but the API's log endpoints take no
/// term, and a box that filters nothing is worse than no box.
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
  Map<AuditEvent, int> _counts = const {};

  /// Which kind of change is being shown, or null for all of them.
  AuditEvent? get event => _event;

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

  @override
  Future<Either<Failure, Paginated<ActivityLogEntry>>> fetchPage({
    String? search,
    required int page,
  }) => _getActivityLog(subject, recordId, event: _event, page: page);
}
