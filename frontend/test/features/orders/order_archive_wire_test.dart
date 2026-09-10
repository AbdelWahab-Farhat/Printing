import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/features/orders/models/orders_sort.dart';
import 'package:dayaa/features/orders/repositories/order_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What deleting, restoring and reading the archive actually put on the wire.
///
/// **The four routes are pinned here because three of them are indistinguishable from a
/// mistake.** `DELETE /orders/7` and `GET /orders/7` differ only by a verb; `/orders/archive`
/// differs from `/orders/7` only by the segment being a word rather than a number — and the
/// server declares it **before** its own `apiResource`, so an app that asked for
/// `/orders/archive/` or `/orders/7/archive` would earn a 404 that reads like a missing order.
///
/// **The archive list sends the same query as the live list**, and that is the whole design:
/// the archive screen is the orders screen with a different source, so every filter the reader
/// already had — the status, the payment states, urgency, the sort — has to travel unchanged.
/// A route that quietly dropped one of them would show «كل المحذوفات» to somebody who asked for
/// «المحذوفة الجاهزة» and say nothing.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('what leaves the phone', () {
    late _CaptureUri capture;
    late OrderRepositoryImpl repository;

    setUp(() {
      capture = _CaptureUri();
      repository = OrderRepositoryImpl(
        Dio(
          BaseOptions(
            baseUrl: 'http://test/api/v1',
            // The same setting the real client carries — see `orders_query_format_test.dart`
            // for the queue this file's `status[]` would otherwise lose.
            listFormat: ListFormat.multiCompatible,
          ),
        )..interceptors.add(capture),
      );
    });

    test('deleting an order is a DELETE on the order itself', () async {
      // Arrange - Act
      await repository.deleteOrder(7);

      // Assert
      expect(capture.method, 'DELETE');
      expect(capture.uri!.path, '/api/v1/orders/7');
    });

    test('restoring is a POST on a child of the order, never a second DELETE', () async {
      // Arrange — a POST for the reason `/status` and `/reinstate` are: the order's history
      // gains a row, so it is an event rather than an edit to a value.
      // Act
      await repository.restoreOrder(7);

      // Assert
      expect(capture.method, 'POST');
      expect(capture.uri!.path, '/api/v1/orders/7/restore');
    });

    test('the archive is its own path, not a flag on the orders list', () async {
      // Arrange - Act
      await repository.archivedOrders();

      // Assert — a literal segment where an id would be, which is why the server declares this
      // route before the resource.
      expect(capture.uri!.path, '/api/v1/orders/archive');
    });

    test('the archive carries every filter the live list carries', () async {
      // Arrange — «أرِني المحذوفة الجاهزة غير المدفوعة، المستعجلة، الأقدم أولاً» is one
      // question, and the archive screen is the orders screen: it must be askable there too.
      // Act
      await repository.archivedOrders(
        search: 'أحمد',
        statuses: const ['ready'],
        paymentStatuses: const ['unpaid'],
        isUrgent: true,
        sort: OrdersSort.oldest,
        page: 2,
      );

      // Assert
      final query = capture.uri!;

      expect(query.queryParametersAll['status[]'], ['ready']);
      expect(query.queryParametersAll['payment_status[]'], ['unpaid']);
      expect(query.queryParameters['search'], 'أحمد');
      expect(query.queryParameters['urgent'], '1');
      expect(query.queryParameters['sort'], 'oldest');
      expect(query.queryParameters['page'], '2');
    });

    test('the archive counts hang under the archive, not under the live summary', () async {
      // Arrange — two rows of chips that describe two different sets is the worst of the three
      // failures §٦ names, because they contradict each other in front of the eye.
      // Act
      await repository.archivedStatusCounts(search: 'أحمد');

      // Assert
      expect(capture.uri!.path, '/api/v1/orders/archive/summary');
      expect(capture.uri!.queryParameters['search'], 'أحمد');
    });
  });

  group('what comes back', () {
    test('a deleted order answers with itself, stamped and trashed', () async {
      // Arrange — the response *is* the order, which is what lets the list behind drop the row
      // without a request: `deleted_at` is the whole answer `belongs()` reads.
      final repository = OrderRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
          ..httpClientAdapter = _StubAdapter(
            _orderJson(deletedAt: '2026-09-10T09:00:00+00:00'),
          ),
      );

      // Act
      final result = await repository.deleteOrder(7);

      // Assert
      final order = result.getOrElse(() => throw StateError('expected an order'));

      expect(order.deletedAt, DateTime.parse('2026-09-10T09:00:00+00:00'));
      expect(order.isArchived, isTrue);
    });

    test('a restored order comes back with no stamp at all', () async {
      // Arrange
      final repository = OrderRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))
          ..httpClientAdapter = _StubAdapter(_orderJson()),
      );

      // Act
      final result = await repository.restoreOrder(7);

      // Assert
      final order = result.getOrElse(() => throw StateError('expected an order'));

      expect(order.deletedAt, isNull);
      expect(order.isArchived, isFalse);
    });
  });
}

/// A live order with nothing but the keys the resource always sends.
Map<String, dynamic> _orderJson({String? deletedAt}) => {
  'id': 7,
  'code': '7',
  'status': 'ready',
  'status_label': 'جاهزة',
  'is_final': false,
  'customer_id': 5,
  'city_id': 3,
  'design_source': 'none',
  'city_name': 'طرابلس',
  'fulfilment_type_label': 'توصيل',
  'is_office_pickup': false,
  'design_source_label': 'بدون تصميم',
  'items_total': '330.00',
  'design_fee': '0.00',
  'delivery_price': '20.00',
  'discount': '0.00',
  'grand_total': '350.00',
  'deleted_at': deletedAt,
};

/// Rejects every request, keeping the verb and the URI it would have gone to.
///
/// Rejecting rather than answering, exactly as `orders_query_format_test.dart` does: this group
/// is about what leaves the phone, and a fake body would only add something nothing here reads.
class _CaptureUri extends Interceptor {
  Uri? uri;
  String? method;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    uri = options.uri;
    method = options.method;

    handler.reject(DioException(requestOptions: options, message: 'captured'), true);
  }
}

/// Answers every request with one order in the app's envelope.
class _StubAdapter implements HttpClientAdapter {
  _StubAdapter(this.data);

  final Map<String, dynamic> data;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      jsonEncode({'status': true, 'message': 'تم بنجاح', 'data': data}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
