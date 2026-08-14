import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/audit/models/activity_log_entry.dart';
import 'package:dayaa/features/audit/models/audit_event.dart';
import 'package:dayaa/features/audit/models/audit_subject.dart';
import 'package:dayaa/features/audit/repositories/audit_repository.dart';

/// One page of a record's history, newest first.
class GetActivityLog {
  const GetActivityLog(this._repository);

  final AuditRepository _repository;

  Future<Either<Failure, Paginated<ActivityLogEntry>>> call(
    AuditSubject subject,
    int recordId, {
    AuditEvent? event,
    int page = 1,
    int perPage = 20,
  }) => _repository.logs(subject, recordId, event: event, page: page, perPage: perPage);
}
