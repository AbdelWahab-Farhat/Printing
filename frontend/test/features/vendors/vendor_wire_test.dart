import 'package:dayaa/features/vendors/repositories/vendor_repository.dart';
import 'package:dayaa/features/vendors/repositories/vendor_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What actually leaves the phone for الموردون وشحنات التوريد.
///
/// **The three things worth pinning are all things the server would accept while meaning
/// something else**, which is exactly the class of bug no screen shows:
///
/// - `is_active` on the vendor list is a `0`/`1` the server filters on; sending `true` narrows
///   nothing and quietly returns both.
/// - a full vendor update must **not** carry `is_active` — the server would read its absence as
///   nothing to change, but a `true` slipped in there reactivates a supplier somebody retired.
/// - `received_by` must never be sent: the server stamps it from the token, and a client that
///   sends one is claiming who received a shipment it cannot know.
///
/// Requests are stopped at the door, so nothing here needs a server.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _Capture capture;
  late VendorRepositoryImpl repository;

  setUp(() {
    capture = _Capture();
    repository = VendorRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://test/api/v1'))..interceptors.add(capture),
    );
  });

  // ─────────────────────────────── vendors ───────────────────────────────

  test('the active filter goes out as the 0/1 the server reads', () async {
    // Act
    await repository.vendors(isActive: false);

    // Assert — `false` on the wire is not what the API filters on.
    expect(capture.uri!.queryParameters['is_active'], '0');
  });

  test('no active filter is not sent at all', () async {
    // Arrange — omitting it asks for both, which is not the same question as `is_active=0`.
    // Act
    await repository.vendors();

    // Assert
    expect(capture.uri!.query, isNot(contains('is_active')));
  });

  test('an update replaces the details and leaves the activation alone', () async {
    // Act
    await repository.update(12, name: 'شركة المريد', phone: '0912345678', email: null);

    // Assert — every detail is present, including the cleared ones, because this is a full
    // replacement. `is_active` is the one thing that must travel on its own endpoint.
    final body = capture.body! as Map<String, dynamic>;

    expect(body['name'], 'شركة المريد');
    expect(body['phone'], '0912345678');
    expect(body.containsKey('email'), isTrue, reason: 'a cleared field must arrive as a null');
    expect(body['email'], isNull);
    expect(body.containsKey('is_active'), isFalse);
  });

  test('activation is its own PATCH, carrying nothing else', () async {
    // Act
    await repository.setActive(12, false);

    // Assert
    expect(capture.method, 'PATCH');
    expect(capture.uri!.path, endsWith('/vendors/12/activation'));
    expect(capture.body, <String, dynamic>{'is_active': false});
  });

  // ───────────────────────────── stock arrivals ─────────────────────────────

  test('a shipment posts its lines and never claims who received it', () async {
    // Act
    await repository.recordStockArrival(
      vendorId: 12,
      warehouseId: 3,
      invoiceNumber: 'INV-1001',
      items: const [
        StockArrivalLine(productVariantId: 45, quantity: '200'),
        StockArrivalLine(productVariantId: 46, quantity: '50.5'),
      ],
    );

    // Assert
    final body = capture.body! as Map<String, dynamic>;

    expect(body['vendor_id'], 12);
    expect(body['warehouse_id'], 3);
    expect(body['invoice_number'], 'INV-1001');
    expect(body['items'], [
      {'product_variant_id': 45, 'quantity': '200'},
      {'product_variant_id': 46, 'quantity': '50.5'},
    ]);

    // The two the server owns, and the one it would have accepted from us.
    expect(body.containsKey('received_by'), isFalse);
    expect(body.containsKey('notes'), isFalse, reason: 'an empty note is not a note');
  });

  test('the quantity stays the text it was typed as', () async {
    // Arrange — `50.5` through a `double` is how a decimal the server sent comes back as
    // something it did not.
    // Act
    await repository.recordStockArrival(
      vendorId: 1,
      warehouseId: 1,
      items: const [StockArrivalLine(productVariantId: 9, quantity: '0.850')],
    );

    // Assert
    final items = (capture.body! as Map<String, dynamic>)['items'] as List<dynamic>;

    expect((items.single as Map<String, dynamic>)['quantity'], isA<String>());
    expect((items.single as Map<String, dynamic>)['quantity'], '0.850');
  });

  test('the arrivals list narrows by vendor, warehouse and a plain day', () async {
    // Act
    await repository.stockArrivals(vendorId: 12, warehouseId: 3, from: '2026-08-01');

    // Assert — days, not timestamps: where a day begins is the server's business, since it is
    // the one that knows the shop's timezone.
    final query = capture.uri!.queryParameters;

    expect(query['vendor_id'], '12');
    expect(query['warehouse_id'], '3');
    expect(query['from'], '2026-08-01');
    expect(query.containsKey('to'), isFalse);
  });
}

/// Rejects every request, keeping what it was about to send.
class _Capture extends Interceptor {
  Uri? uri;
  Object? body;
  String? method;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    uri = options.uri;
    body = options.data;
    method = options.method;

    handler.reject(DioException(requestOptions: options, message: 'captured'), true);
  }
}
