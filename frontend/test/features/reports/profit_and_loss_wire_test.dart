import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/reports/repositories/report_repository_impl.dart';

/// What actually goes on the wire for الأرباح والخسائر.
///
/// **The Impl is tested directly here, not a fake of the contract.** What is worth pinning is
/// the shape of the request — the path, and the two days going out as the plain dates a picker
/// produced — and a fake of the abstract repository would assert nothing about either. The Cubit
/// gets the fake; this gets Dio, with an interceptor that captures the request and refuses it.
///
/// Arrange - Act - Assert throughout.
void main() {
  late Dio dio;
  late ReportRepositoryImpl repository;
  late RequestOptions captured;

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          captured = options;
          handler.reject(
            DioException(requestOptions: options, message: 'captured'),
            true,
          );
        },
      ),
    );
    repository = ReportRepositoryImpl(dio);
  });

  group('the report', () {
    test('is read from the reports path, not from anything under orders', () async {
      // Act
      await repository.profitAndLoss(from: '2026-03-01', to: '2026-03-31');

      // Assert
      expect(captured.method, 'GET');
      expect(captured.path, '/reports/profit-loss');
    });

    test('carries both ends of the period, and nothing else', () async {
      // Act
      await repository.profitAndLoss(from: '2026-03-01', to: '2026-03-31');

      // Assert — the endpoint takes no other filter, so a third key would be a key the server
      // ignores and a reader here would have to go looking for
      expect(captured.queryParameters['from'], '2026-03-01');
      expect(captured.queryParameters['to'], '2026-03-31');
      expect(captured.queryParameters.keys, ['from', 'to']);
    });

    test('sends the plain day it was given, with no time on it', () async {
      // Arrange — a value with a time would have the server silently start the window at
      // midnight and echo back a date that says nothing about what was dropped
      const day = '2026-03-15';

      // Act — the same day at both ends is a valid one-day report
      await repository.profitAndLoss(from: day, to: day);

      // Assert
      expect(captured.queryParameters['from'], day);
      expect(captured.queryParameters['to'], day);
      expect(captured.uri.query, isNot(contains('T')));
    });
  });
}
