import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository_impl.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// What actually goes on the wire for a purchase order.
///
/// **The Impl is tested directly here, not a fake of the contract.** What is worth pinning is
/// the shape of the request — the paths, the keys, which fields are omitted — and a fake of the
/// abstract repository would assert nothing about any of that. The Cubits get the fake; this
/// gets Dio, with an interceptor that captures the request and refuses it.
///
/// Arrange - Act - Assert throughout.
void main() {
  late Dio dio;
  late PurchaseOrderRepositoryImpl repository;
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
    repository = PurchaseOrderRepositoryImpl(dio);
  });

  group('the list', () {
    test('asks for one status and omits the filters nobody set', () async {
      // Act
      await repository.purchaseOrders(statuses: const ['arrived']);

      // Assert — a null in a query string becomes the literal "null", and this endpoint reads
      // its filters without validating them: `PurchaseOrderStatus::from('null')` is a 500.
      // One status travels as a one-item group, the same way «الجارية» travels as two.
      expect(captured.path, '/purchase-orders');
      expect(captured.queryParameters['status'], ['arrived']);
      expect(captured.queryParameters.containsKey('vendor_id'), isFalse);
      expect(captured.queryParameters.containsKey('warehouse_id'), isFalse);
    });

    test('sends nothing at all when every filter is off', () async {
      // Act
      await repository.purchaseOrders();

      // Assert
      expect(captured.queryParameters.containsKey('status'), isFalse);
      expect(captured.queryParameters.containsKey('search'), isFalse);
    });

    test('carries the search term, and drops it when the box is cleared', () async {
      // Act
      await repository.purchaseOrders(search: 'ولي العهد');

      // Assert
      expect(captured.queryParameters['search'], 'ولي العهد');

      // Act — the box cleared. `PagedCubit` hands an empty term down as null.
      await repository.purchaseOrders();

      // Assert — omitted rather than sent blank, like every other filter on this endpoint.
      expect(captured.queryParameters.containsKey('search'), isFalse);
    });

    test('searching and filtering are one question, not two', () async {
      // Act
      await repository.purchaseOrders(statuses: const ['cancelled'], search: 'الجنوب');

      // Assert — both ride on the same request; a screen that sent them separately would show
      // the list narrowed by whichever landed last.
      expect(captured.queryParameters['status'], ['cancelled']);
      expect(captured.queryParameters['search'], 'الجنوب');
    });
  });

  group('raising one', () {
    test('a line names the shelf, not a product size', () async {
      // Arrange — two shelves, «كيس شحن 25*35» and «كيس شحن 35*40». What separates two products
      // at one size is printing, which is a cost rate and not a different material, so both
      // draw on one pile and a purchase order buys the pile.
      const lines = [
        PurchaseOrderLine(stockItemId: 3, quantity: '10', baseTotalCost: '25'),
        PurchaseOrderLine(stockItemId: 4, quantity: '5', baseTotalCost: '15'),
      ];

      // Act
      await repository.create(
        vendorId: 1,
        warehouseId: 2,
        orderDate: '2026-08-08',
        items: lines,
      );

      // Assert — `stock_item_id`, and **not** `product_variant_id`: the old key is one the
      // server no longer reads, so a body still carrying it would be refused for a missing
      // stock item while looking, on this side, exactly like a body that named one. Sharing
      // runs across products at one size and never across sizes, which is why the two lines
      // stay two ids rather than collapsing into one.
      final body = captured.data as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>;

      expect((items.first as Map<String, dynamic>)['stock_item_id'], 3);
      expect((items.last as Map<String, dynamic>)['stock_item_id'], 4);
      expect(
        (items.first as Map<String, dynamic>).containsKey('product_variant_id'),
        isFalse,
      );
    });

    test('a new line carries no id, and an existing one does', () async {
      // Arrange — the load-bearing detail of editing: the server matches lines by id and
      // removes any it is not sent, so a line that arrived without one would be deleted and
      // recreated, taking its received quantity with it. It falls back to `stock_item_id` as
      // the natural key while syncing, but that is a safety net and not a reason to drop the id.
      const lines = [
        PurchaseOrderLine(id: 12, stockItemId: 3, quantity: '10', baseTotalCost: '25'),
        PurchaseOrderLine(stockItemId: 4, quantity: '5', baseTotalCost: '15'),
      ];

      // Act
      await repository.update(
        7,
        vendorId: 1,
        warehouseId: 2,
        orderDate: '2026-08-08',
        items: lines,
      );

      // Assert
      final body = captured.data as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>;

      expect(captured.method, 'PUT');
      expect(captured.path, '/purchase-orders/7');
      expect((items.first as Map<String, dynamic>)['id'], 12);
      expect((items.last as Map<String, dynamic>).containsKey('id'), isFalse);
    });

    test('every line carries its total cost, zero included', () async {
      // Arrange — a free replacement from the vendor. The server takes `gte:0`, so zero is a
      // recorded answer and not the absence of one; a line that dropped it would be refused.
      const lines = [
        PurchaseOrderLine(stockItemId: 3, quantity: '10', baseTotalCost: '25.500'),
        PurchaseOrderLine(stockItemId: 4, quantity: '5', baseTotalCost: '0'),
      ];

      // Act
      await repository.create(
        vendorId: 1,
        warehouseId: 2,
        orderDate: '2026-08-08',
        items: lines,
      );

      // Assert — `base_total_cost`, and it is the *line's* total: the server divides by the
      // quantity to get `base_unit_cost`, never the other way around.
      final body = captured.data as Map<String, dynamic>;
      final items = body['items'] as List<dynamic>;

      expect((items.first as Map<String, dynamic>)['base_total_cost'], '25.500');
      expect((items.last as Map<String, dynamic>)['base_total_cost'], '0');
      expect((items.first as Map<String, dynamic>).containsKey('unit_cost'), isFalse);
    });

    test('an optional date left empty is left out of the body', () async {
      // Act
      await repository.create(
        vendorId: 1,
        warehouseId: 2,
        orderDate: '2026-08-08',
        items: const [
          PurchaseOrderLine(stockItemId: 3, quantity: '10', baseTotalCost: '25'),
        ],
      );

      // Assert — `nullable|date` and "not mentioned" say slightly different things, and the
      // second is what an empty box means.
      final body = captured.data as Map<String, dynamic>;

      expect(captured.method, 'POST');
      expect(body.containsKey('expected_date'), isFalse);
      expect(body.containsKey('notes'), isFalse);
    });
  });

  group('the order-level costs', () {
    test('a new one carries no id, and an existing one does', () async {
      // Arrange — the same replace-the-whole-set contract the items follow.
      const costs = [
        PurchaseOrderAdditionalCostLine(id: 7, name: 'توصيل', amount: '10'),
        PurchaseOrderAdditionalCostLine(name: 'جمارك', amount: '3'),
      ];

      // Act
      await repository.update(
        7,
        vendorId: 1,
        warehouseId: 2,
        orderDate: '2026-08-08',
        items: const [
          PurchaseOrderLine(stockItemId: 3, quantity: '10', baseTotalCost: '25'),
        ],
        additionalCosts: costs,
      );

      // Assert
      final body = captured.data as Map<String, dynamic>;
      final sent = body['additional_costs'] as List<dynamic>;

      expect((sent.first as Map<String, dynamic>)['id'], 7);
      expect((sent.first as Map<String, dynamic>)['name'], 'توصيل');
      expect((sent.first as Map<String, dynamic>)['amount'], '10');
      expect((sent.last as Map<String, dynamic>).containsKey('id'), isFalse);
    });

    test('an empty list is sent rather than omitted', () async {
      // Act — an order whose last additional cost was just deleted on the form.
      await repository.update(
        7,
        vendorId: 1,
        warehouseId: 2,
        orderDate: '2026-08-08',
        items: const [
          PurchaseOrderLine(stockItemId: 3, quantity: '10', baseTotalCost: '25'),
        ],
      );

      // Assert — omitting the key on a PUT is how the server is told nothing changed; an empty
      // array is how it is told they are gone. The form always knows which, so it always says.
      final body = captured.data as Map<String, dynamic>;

      expect(body['additional_costs'], isEmpty);
    });

    test('an amount typed on an Arabic keyboard reaches the server as digits', () async {
      // Arrange — `numeric` on the server is ASCII-only, and «١٠٫٥» is not a number to it.
      final save = SavePurchaseOrder(repository);

      // Act
      await save(
        vendorId: 1,
        warehouseId: 2,
        orderDate: '2026-08-08',
        items: const [
          DraftLine(stockItemId: 3, quantity: '١٠', baseTotalCost: '٢٥'),
        ],
        additionalCosts: const [
          DraftAdditionalCost(name: '  توصيل  ', amount: '١٠٫٥'),
        ],
      );

      // Assert — the same normalising the quantity has always had, applied to both new numbers.
      final body = captured.data as Map<String, dynamic>;
      final line = (body['items'] as List<dynamic>).single as Map<String, dynamic>;
      final cost = (body['additional_costs'] as List<dynamic>).single
          as Map<String, dynamic>;

      expect(line['quantity_ordered'], '10');
      expect(line['base_total_cost'], '25');
      expect(cost['amount'], '10.5');
      expect(cost['name'], 'توصيل');
    });

    test('a row left blank on the form is not a cost', () async {
      // Arrange — the editor opens rows the way the line list does, and a half-filled one left
      // behind would be refused by `additional_costs.*.name.required` at an index nobody can
      // point at on screen.
      final save = SavePurchaseOrder(repository);

      // Act
      await save(
        vendorId: 1,
        warehouseId: 2,
        orderDate: '2026-08-08',
        items: const [
          DraftLine(stockItemId: 3, quantity: '10', baseTotalCost: '25'),
        ],
        additionalCosts: const [
          DraftAdditionalCost(name: 'توصيل', amount: '10'),
          DraftAdditionalCost(name: '   ', amount: '  '),
        ],
      );

      // Assert
      final body = captured.data as Map<String, dynamic>;

      expect((body['additional_costs'] as List<dynamic>).length, 1);
    });
  });

  test('a status change is a PATCH carrying the wire value alone', () async {
    // Act
    await repository.changeStatus(7, status: PurchaseOrderStatus.arrived);

    // Assert
    expect(captured.method, 'PATCH');
    expect(captured.path, '/purchase-orders/7/status');
    expect(captured.data, {'status': 'arrived'});
  });

  group('receiving a shipment', () {
    test('names neither the vendor nor the warehouse', () async {
      // Act
      await repository.receiveArrival(
        7,
        items: const [ReceivedLine(stockItemId: 3, quantity: '4')],
        invoiceNumber: 'INV-9',
      );

      // Assert — both come from the order. A client that could name them could book stock into
      // somebody else's warehouse. The line addresses the **shelf**, which is also what makes
      // it addressable at all: goods turn up as a pile, and there is no way to tell from a
      // pallet which of the two products sharing the shelf it was ordered against.
      final body = captured.data as Map<String, dynamic>;

      expect(captured.path, '/purchase-orders/7/arrivals');
      expect(body.containsKey('vendor_id'), isFalse);
      expect(body.containsKey('warehouse_id'), isFalse);
      expect(body['invoice_number'], 'INV-9');
      expect(body['items'], [
        {'stock_item_id': 3, 'quantity': '4'},
      ]);
    });

    test('an empty box is not a line', () async {
      // Arrange — the receive sheet opens with a box per outstanding line, and a shipment that
      // brought two of five shelves is the ordinary case. The map is keyed by stock item id,
      // which is what makes it safe to be a map at all: an order carries one line per shelf, so
      // a key can never stand for two of them.
      final receive = ReceivePurchaseOrderArrival(repository);

      // Act
      await receive(7, quantities: {3: '4', 4: '', 5: '  ', 6: '0'});

      // Assert — sending the empty ones would be refused for a quantity of zero, on a screen
      // whose user filled in exactly what turned up.
      final body = captured.data as Map<String, dynamic>;

      expect(body['items'], [
        {'stock_item_id': 3, 'quantity': '4'},
      ]);
    });

    test('a quantity typed on an Arabic keyboard reaches the server as digits', () async {
      // Arrange — every numeric rule on the server is ASCII-only, and «٤٠» is not a digit as
      // far as `numeric` is concerned.
      final receive = ReceivePurchaseOrderArrival(repository);

      // Act
      await receive(7, quantities: {3: '٤٠٫٥'.replaceAll('٫', ',')});

      // Assert
      final body = captured.data as Map<String, dynamic>;
      final line = (body['items'] as List<dynamic>).single as Map<String, dynamic>;

      expect(line['quantity'], '40.5');
    });
  });
}
