import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/pagination/paged_cubit.dart';
import 'package:printing/features/audit/models/activity_log_entry.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/audit/usecases/get_activity_log.dart';

/// A record's history, paged.
///
/// It inherits everything a list needs — the request-id guard, the append-on-load-more, keeping
/// what is on screen when a later page fails — and adds only *which* record.
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

  @override
  Future<Either<Failure, Paginated<ActivityLogEntry>>> fetchPage({
    String? search,
    required int page,
  }) => _getActivityLog(subject, recordId, page: page);
}
