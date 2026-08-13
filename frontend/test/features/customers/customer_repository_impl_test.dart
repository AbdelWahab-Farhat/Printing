import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/customers/models/customers_filter.dart';
import 'package:printing/features/customers/models/new_customer.dart';
import 'package:printing/features/customers/repositories/customer_repository_impl.dart';

/// What actually goes down the wire when a customer is created.
///
/// **Why this test exists.** Asserting on `NewCustomer.toJson()` proves what the model returns,
/// not what the server receives — and the two are not the same statement. Between them sit Dio's
/// transformer and `jsonEncode`, which is where a nested list, a `null` that should have been
/// omitted, or a number that arrived as a string would be decided. This reads the bytes Dio
/// actually produced, through a replaced adapter, so the assertions are about the request.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  String? body;
  String? path;
  Map<String, String> query = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    query = options.uri.queryParameters;

    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = utf8.decode(chunks.expand((chunk) => chunk).toList());
    }

    return ResponseBody.fromString(
      jsonEncode({
        'status': true,
        'message': 'تم إضافة العميل بنجاح',
        'data': {
          'id': 7,
          'code': 'C7',
          'name': 'مطبعة النور',
          'phone': '0913334444',
          'is_active': true,
        },
      }),
      201,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _CapturingAdapter adapter;
  late CustomerRepositoryImpl repository;

  setUp(() {
    adapter = _CapturingAdapter();
    repository = CustomerRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );
  });

  test('a customer with shops is encoded, not handed over as objects', () async {
    // Arrange
    const customer = NewCustomer(
      name: 'مطبعة النور',
      phone: '0913334444',
      shops: [
        NewCustomerShop(
          name: 'فرع سوق الجمعة',
          cityId: 3,
          regionId: 11,
          pageUrl: 'https://facebook.com/alnoor',
        ),
      ],
    );

    // Act
    final result = await repository.create(customer);

    // Assert — the shop is a JSON object carrying the two map ids, and the whole thing survived
    // `jsonEncode`. Decoding it back is what proves it: an unencodable body never gets here.
    expect(result.isRight(), isTrue);

    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
    expect(sent['name'], 'مطبعة النور');
    expect(sent['phone'], '0913334444');

    final shops = sent['shops'] as List<dynamic>;
    final shop = shops.single as Map<String, dynamic>;
    expect(shop['name'], 'فرع سوق الجمعة');
    expect(shop['city_id'], 3);
    expect(shop['region_id'], 11);
    expect(shop['page_url'], 'https://facebook.com/alnoor');
  });

  test('a customer with no shops does not mention the key', () async {
    // Arrange
    const customer = NewCustomer(name: 'مطبعة النور', phone: '0913334444');

    // Act
    await repository.create(customer);

    // Assert — `shops: []` would tell this API something different from saying nothing.
    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
    expect(sent.containsKey('shops'), isFalse);
    expect(adapter.path, '/customers');
  });

  test('a shop with no page link omits it rather than sending null', () async {
    // Arrange
    const customer = NewCustomer(
      name: 'مطبعة النور',
      phone: '0913334444',
      shops: [NewCustomerShop(name: 'الفرع', cityId: 3)],
    );

    // Act
    await repository.create(customer);

    // Assert — the API's rule is `nullable|url`; an absent key is the clean way to say nothing.
    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
    final shop = (sent['shops'] as List<dynamic>).single as Map<String, dynamic>;
    expect(shop.containsKey('page_url'), isFalse);
  });

  // ─────────────────────────── what the list asks for ───────────────────────────

  test('the plain list mentions neither the orders filter nor a sort', () async {
    // Arrange — the tab's own first request.

    // Act
    await repository.customers();

    // Assert — `sort=newest` is the same request as no sort, and the shorter one is the one
    // somebody reads in a log. A `has_orders` sent as null would arrive as the string "null".
    expect(adapter.query.containsKey('has_orders'), isFalse);
    expect(adapter.query.containsKey('sort'), isFalse);
  });

  test('«بدون طلبات» and «الأقدم طلباً» reach the API by their own names', () async {
    // Arrange

    // Act
    await repository.customers(hasOrders: false, sort: CustomersSort.leastRecentOrder);

    // Assert — the words `CustomerSort` and `CustomerFilters` know on the server. This is the
    // seam that fails here rather than as an unfiltered list on somebody's phone.
    expect(adapter.query['has_orders'], '0');
    expect(adapter.query['sort'], 'least_recent_order');
  });

  test('the filter travels with the page number, not only with the first request', () async {
    // Arrange

    // Act
    await repository.customers(hasOrders: false, page: 3);

    // Assert — page three of «بدون طلبات», not page three of everybody.
    expect(adapter.query['page'], '3');
    expect(adapter.query['has_orders'], '0');
  });
}
