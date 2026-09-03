import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/features/orders/models/new_order.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/repositories/order_repository_impl.dart';
import 'package:dayaa/features/orders/usecases/take_order.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «المورد» on its way from the new-order form to the API.
///
/// Two halves: the use case carries the id the picker answered with, and the wire carries it as
/// `vendor_id` — or not at all, because an absent key and a null are two different sentences to
/// a `nullable` rule, and «لم يُختر مورد» is the absent one.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _FakeNewOrder extends Fake implements NewOrder {}

class _CapturingAdapter implements HttpClientAdapter {
  String? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
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
          'vendor_id': 4,
          'vendor_name': 'مطبعة الأمل',
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
  const stored = Order(
    id: 52,
    code: '52',
    status: OrderStatus.taken,
    statusLabel: 'جديدة',
    isFinal: false,
    customerId: 3,
    cityId: 1,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '330.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '350.00',
  );

  const line = DraftOrderLine(productId: 7, productVariantId: 12, quantity: '50');

  group('the use case', () {
    late _MockOrderRepository repository;
    late TakeOrder takeOrder;

    setUpAll(() => registerFallbackValue(_FakeNewOrder()));

    setUp(() {
      repository = _MockOrderRepository();
      takeOrder = TakeOrder(repository);
      when(() => repository.create(any())).thenAnswer((_) async => const Right(stored));
    });

    NewOrder sent() => verify(() => repository.create(captureAny())).captured.single as NewOrder;

    test('carries the vendor the picker answered with', () async {
      // Arrange - Act
      await takeOrder(customerId: 3, cityId: 1, lines: const [line], vendorId: 4);

      // Assert
      expect(sent().vendorId, 4);
    });

    test('says nothing about a vendor when none was chosen', () async {
      // Arrange - Act
      await takeOrder(customerId: 3, cityId: 1, lines: const [line]);

      // Assert
      expect(sent().vendorId, isNull);
    });
  });

  group('the wire', () {
    late _CapturingAdapter adapter;
    late OrderRepositoryImpl repository;

    setUp(() {
      adapter = _CapturingAdapter();
      repository = OrderRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
      );
    });

    const items = [NewOrderItem(productId: 7, productVariantId: 12, quantity: '50')];

    test('a chosen vendor travels as vendor_id', () async {
      // Arrange - Act
      await repository.create(
        const NewOrder(customerId: 3, cityId: 1, designSource: 'none', items: items, vendorId: 4),
      );

      // Assert
      final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
      expect(sent['vendor_id'], 4);
    });

    test('no vendor is an absent key, not a null', () async {
      // Arrange - Act
      await repository.create(
        const NewOrder(customerId: 3, cityId: 1, designSource: 'none', items: items),
      );

      // Assert
      final sent = jsonDecode(adapter.body!) as Map<String, dynamic>;
      expect(sent.containsKey('vendor_id'), isFalse);
    });

    test('the vendor comes back on the order, name and all', () async {
      // Arrange - Act
      final result = await repository.create(
        const NewOrder(customerId: 3, cityId: 1, designSource: 'none', items: items, vendorId: 4),
      );

      // Assert — the name is the order's own snapshot, which is what the screen prints.
      final order = result.fold((failure) => fail(failure.message), (order) => order);
      expect(order.vendorId, 4);
      expect(order.vendorName, 'مطبعة الأمل');
    });
  });
}
