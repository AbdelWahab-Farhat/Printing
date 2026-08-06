import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/orders/models/new_order.dart';
import 'package:printing/features/orders/repositories/order_repository_impl.dart';

/// What actually goes down the wire when an order is taken.
///
/// **Why the wire and not `toJson()`.** The body nests lines inside an order, and between the
/// model and the server sit Dio's transformer and `jsonEncode` — which is where a list of Dart
/// objects, a `null` that should have been omitted, or a price that arrived as a number instead
/// of a decimal string would be decided. `NewCustomer` has the same test for the same reason.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  String? body;
  String? path;
  String? method;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    path = options.path;
    method = options.method;

    if (requestStream != null) {
      final chunks = await requestStream.toList();
      body = utf8.decode(chunks.expand((chunk) => chunk).toList());
    }

    return ResponseBody.fromString(
      jsonEncode({
        'status': true,
        'message': 'تم إنشاء الطلبية بنجاح',
        'data': {
          'id': 52,
          'code': '52',
          'customer_id': 3,
          'status': 'new',
          'status_label': 'جديدة',
          'is_final': false,
          'design_source': 'none',
          'design_source_label': 'بدون تصميم',
          'city_id': 1,
          'city_name': 'طرابلس',
          'fulfilment_type_label': 'توصيل',
          'is_office_pickup': false,
          'items_total': '330.00',
          'design_fee': '0.00',
          'delivery_price': '20.00',
          'discount': '0.00',
          'grand_total': '350.00',
          'paid_amount': '0.00',
          'remaining_amount': '350.00',
          'payment_status': 'unpaid',
          'payment_status_label': 'غير مدفوعة',
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
  late OrderRepositoryImpl repository;

  setUp(() {
    adapter = _CapturingAdapter();
    repository = OrderRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );
  });

  const order = NewOrder(
    customerId: 3,
    cityId: 1,
    designSource: 'none',
    items: [
      NewOrderItem(productId: 7, productVariantId: 12, quantity: '300', sortOrder: 0),
      NewOrderItem(productId: 9, productVariantId: 14, quantity: '50', sortOrder: 1),
    ],
  );

  test('the lines are encoded, not handed over as objects', () async {
    // Arrange — see the class doc: this is the step `toJson()` alone cannot prove.

    // Act
    await repository.create(order);

    // Assert
    expect(adapter.method, 'POST');
    expect(adapter.path, '/orders');

    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
    expect(sent['items'], [
      {'product_id': 7, 'product_variant_id': 12, 'quantity': '300', 'sort_order': 0},
      {'product_id': 9, 'product_variant_id': 14, 'quantity': '50', 'sort_order': 1},
    ]);
  });

  test('what the clerk left blank is left out of the body, not sent as null', () async {
    // Arrange — every optional field on the API is `nullable`, and an absent key says something
    // different from an explicit null. The one that matters is `region_id`: a city that needs a
    // region refuses the order, and «missing» is the honest way to say the clerk chose none.

    // Act
    await repository.create(order);

    // Assert
    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
    expect(sent.keys, containsAll(<String>['customer_id', 'city_id', 'design_source', 'items']));
    expect(sent.containsKey('region_id'), isFalse);
    expect(sent.containsKey('customer_shop_id'), isFalse);
    expect(sent.containsKey('recipient_name'), isFalse);
    expect(sent.containsKey('discount'), isFalse);
    expect(sent.containsKey('design_fee'), isFalse);
  });

  test('money and quantities travel as strings', () async {
    // Arrange — a discount of 25.50 encoded as a number is a `double` by the time it reaches
    // `jsonEncode`, and the server adds it to a total that has to stay exact.
    const discounted = NewOrder(
      customerId: 3,
      cityId: 1,
      designSource: 'in_house',
      designFee: '40.00',
      discount: '25.50',
      items: [NewOrderItem(productId: 7, productVariantId: 12, quantity: '300.5', sortOrder: 0)],
    );

    // Act
    await repository.create(discounted);

    // Assert
    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
    expect(sent['discount'], '25.50');
    expect(sent['design_fee'], '40.00');
    expect((sent['items'] as List).first, containsPair('quantity', '300.5'));
  });

  test('a price named by a clerk rides on the line it belongs to', () async {
    // Arrange — the exception the API allows: a product the catalogue prices «حسب الطلب».
    const quoted = NewOrder(
      customerId: 3,
      cityId: 1,
      designSource: 'none',
      items: [
        NewOrderItem(
          productId: 9,
          productVariantId: 14,
          quantity: '200',
          unitPrice: '2.750',
          notes: 'بدون طباعة',
          sortOrder: 0,
        ),
      ],
    );

    // Act
    await repository.create(quoted);

    // Assert
    final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
    expect((sent['items'] as List).single, {
      'product_id': 9,
      'product_variant_id': 14,
      'quantity': '200',
      'unit_price': '2.750',
      'notes': 'بدون طباعة',
      'sort_order': 0,
    });
  });

  test('the order that comes back is the server’s, not the one that was sent', () async {
    // Arrange — the answer carries the number staff will call this order from now on.

    // Act
    final result = await repository.create(order);

    // Assert
    final created = result.getOrElse(() => throw StateError('expected an order'));
    expect(created.id, 52);
    expect(created.code, '52');
    expect(created.grandTotal, '350.00');
  });
}
