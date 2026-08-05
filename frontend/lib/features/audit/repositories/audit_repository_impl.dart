import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/core/network/safe_request.dart';
import 'package:printing/features/audit/models/activity_log_entry.dart';
import 'package:printing/features/audit/models/audit_event.dart';
import 'package:printing/features/audit/models/audit_subject.dart';
import 'package:printing/features/audit/repositories/audit_repository.dart';

class AuditRepositoryImpl implements AuditRepository {
  const AuditRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<Either<Failure, Paginated<ActivityLogEntry>>> logs(
    AuditSubject subject,
    int recordId, {
    AuditEvent? event,
    int page = 1,
    int perPage = 20,
  }) {
    return safePaginatedRequest<ActivityLogEntry>(
      // Built from the subject rather than from a switch over six endpoint constants: the API
      // deliberately hangs every log off its own record, so the path *is* the resource plus
      // `/logs`, and spelling that out six times would be six chances to get one wrong.
      () => _dio.get(
        '/${subject.path}/$recordId/logs',
        queryParameters: <String, dynamic>{
          'page': page,
          'per_page': perPage,
          // Omitted rather than sent as null: a null in a query string arrives as the literal
          // "null", and the API validates `event` against its four values.
          if (event != null) 'event': event.wire,
        },
      ),
      parseItem: ActivityLogEntry.fromJson,
    );
  }
}
