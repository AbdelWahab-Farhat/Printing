import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/audit/models/activity_log_entry.dart';
import 'package:dayaa/features/audit/models/audit_event.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';

/// Reading any record's history.
///
/// One method for every model, because the API is one shape for every model: the log hangs off
/// the record, and [AuditSubject] carries the only part that differs.
abstract interface class AuditRepository {
  /// [event] narrows to one kind of change. Server-side, deliberately: filtering the page
  /// already downloaded would show «٤ من أصل ١٧» worth of history and call it the whole of it.
  ///
  /// The counts behind the filter chips come back in `Paginated.extraMeta['event_counts']` and
  /// describe the **whole** trail, unaffected by [event] — a chip has to say what tapping it
  /// would give.
  Future<Either<Failure, Paginated<ActivityLogEntry>>> logs(
    AuditSubject subject,
    int recordId, {
    AuditEvent? event,
    int page,
    int perPage,
  });
}
