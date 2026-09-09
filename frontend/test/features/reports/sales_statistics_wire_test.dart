import 'package:dayaa/features/reports/repositories/report_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What actually goes on the wire for إحصائيات المبيعات.
///
/// **The Impl is tested directly here, not a fake of the contract** — the same choice
/// `profit_and_loss_wire_test.dart` makes and for the same reason: what is worth pinning is the
/// shape of the request, and a fake of the abstract repository would assert nothing about it.
///
/// The load-bearing claim is the first test's: **this report has a path of its own.** It answers
/// to a different permission from الأرباح والخسائر, so a copy-paste that left it pointing at
/// `/reports/profit-loss` would hand the press the margin screen and pass every other test here.
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

  group('the board', () {
    test('is read from its own path, not from the profit and loss one', () async {
      // Act
      await repository.salesStatistics(from: '2026-03-01', to: '2026-03-31');

      // Assert
      expect(captured.method, 'GET');
      expect(captured.path, '/reports/sales-statistics');
    });

    test('carries both ends of the period, and nothing else', () async {
      // Act
      await repository.salesStatistics(from: '2026-03-01', to: '2026-03-31');

      // Assert — the endpoint takes no other filter, so a third key would be one the server
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
      await repository.salesStatistics(from: day, to: day);

      // Assert
      expect(captured.queryParameters['from'], day);
      expect(captured.queryParameters['to'], day);
      expect(captured.uri.query, isNot(contains('T')));
    });
  });
}
