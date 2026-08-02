import 'package:dartz/dartz.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/audit/models/activity_log_entry.dart';
import 'package:printing/features/audit/models/audit_subject.dart';

/// Reading any record's history.
///
/// One method for every model, because the API is one shape for every model: the log hangs off
/// the record, and [AuditSubject] carries the only part that differs.
abstract interface class AuditRepository {
  Future<Either<Failure, Paginated<ActivityLogEntry>>> logs(
    AuditSubject subject,
    int recordId, {
    int page,
    int perPage,
  });
}
