import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/api_endpoints.dart';
import 'package:dayaa/core/network/safe_request.dart';
import 'package:dayaa/features/reports/models/profit_and_loss_summary.dart';
import 'package:dayaa/features/reports/repositories/report_repository.dart';
import 'package:dio/dio.dart';

/// Fulfils [ReportRepository] over HTTP.
class ReportRepositoryImpl implements ReportRepository {
  const ReportRepositoryImpl(this._dio);

  final Dio _dio;

  /// [safeRequest] rather than [safePaginatedRequest]: the endpoint answers one object and sends
  /// no `meta`, so asking for page numbers would report «الرد لا يحتوي على بيانات الصفحات» for a
  /// response that is perfectly correct.
  ///
  /// The two days go on the wire exactly as the picker produced them — plain `YYYY-MM-DD`, no
  /// time and no offset. **Where a day begins is the server's business**, and sending anything
  /// with a time on it would have the window silently start at midnight anyway, with the echo
  /// saying nothing about what was dropped.
  @override
  Future<Either<Failure, ProfitAndLossSummary>> profitAndLoss({
    required String from,
    required String to,
  }) {
    return safeRequest<ProfitAndLossSummary>(
      () => _dio.get(
        ReportEndpoints.profitAndLoss,
        queryParameters: <String, dynamic>{'from': from, 'to': to},
      ),
      parse: (data) => ProfitAndLossSummary.fromJson(data as Map<String, dynamic>),
    );
  }
}
