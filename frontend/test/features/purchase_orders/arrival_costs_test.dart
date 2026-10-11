import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/receive_arrival_sheet.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository_impl.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «مصاريف عند وصول البضاعة» — what the app sends and reads for a purchase order's costs now that
/// they can be typed on the receive screen and say who was paid.
/// Docs/purchase-orders/PURCHASE-ORDER-ARRIVAL-COSTS.md.
///
/// Arrange - Act - Assert throughout.
void main() {
  group('on the wire', () {
    late PurchaseOrderRepositoryImpl repository;
    late RequestOptions captured;

    setUp(() {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.reject(DioException(requestOptions: options, message: 'captured'), true);
          },
        ),
      );
      repository = PurchaseOrderRepositoryImpl(dio);
    });

    test('a receipt carries its arrival costs, who was paid included', () async {
      // Arrange
      final receive = ReceivePurchaseOrderArrival(repository);

      // Act
      await receive(
        7,
        quantities: {3: '10'},
        additionalCosts: const [
          DraftAdditionalCost(name: ' نقل ', amount: '٣٠', treasuryAccountId: 5),
          DraftAdditionalCost(name: 'تحميل', amount: '20'),
          DraftAdditionalCost(name: '', amount: ' '),
        ],
      );

      // Assert — the blank row dropped, digits normalised, «vendor's bill» said as null
      final body = captured.data as Map<String, dynamic>;

      expect(body['additional_costs'], [
        {'name': 'نقل', 'amount': '30', 'treasury_account_id': 5},
        {'name': 'تحميل', 'amount': '20', 'treasury_account_id': null},
      ]);
    });

    test('a receipt with no costs sends no key at all', () async {
      // Act
      await ReceivePurchaseOrderArrival(repository)(7, quantities: {3: '10'});

      // Assert — the request older servers took, unchanged.
      expect((captured.data as Map<String, dynamic>).containsKey('additional_costs'), isFalse);
    });

    test('a planned cost carries who was paid, and null to put it back on the vendor', () async {
      // Act
      await SavePurchaseOrder(repository)(
        id: 9,
        vendorId: 1,
        warehouseId: 2,
        orderDate: '2026-10-11',
        items: const [DraftLine(stockItemId: 3, quantity: '10', baseTotalCost: '100')],
        additionalCosts: const [
          DraftAdditionalCost(id: 4, name: 'توصيل', amount: '20', treasuryAccountId: 5),
          DraftAdditionalCost(id: 6, name: 'جمارك', amount: '15'),
        ],
      );

      // Assert
      final sent = (captured.data as Map<String, dynamic>)['additional_costs'] as List<dynamic>;

      expect((sent.first as Map<String, dynamic>)['treasury_account_id'], 5);
      expect((sent.last as Map<String, dynamic>).containsKey('treasury_account_id'), isTrue);
      expect((sent.last as Map<String, dynamic>)['treasury_account_id'], isNull);
    });
  });

  group('reading an order', () {
    final order = PurchaseOrder.fromJson(<String, dynamic>{
      'id': 12,
      'vendor_id': 3,
      'status': 'completed',
      'status_label': 'مكتمل',
      'order_date': '2026-10-11',
      'total_amount': '175.00',
      'vendor_amount': '120.00',
      'additional_costs': [
        {'id': 1, 'name': 'توصيل', 'amount': '20.00'},
        {
          'id': 2,
          'name': 'نقل',
          'amount': '30.00',
          'stock_arrival_id': 40,
          'treasury_account_id': 5,
          'treasury_account': {'id': 5, 'name': 'الخزنة الرئيسية', 'kind': 'cash'},
        },
        {
          'id': 3,
          'name': 'جمارك',
          'amount': '25.00',
          'stock_arrival_id': 40,
          'treasury_account_id': 8,
          'treasury_account': {'id': 8, 'name': 'المخلّص', 'kind': 'payable'},
        },
      ],
      'items': [
        {
          'id': 50,
          'stock_item_id': 3,
          'quantity_ordered': '10.000',
          'quantity_received': '10.000',
          'quantity_remaining': '0.000',
          'base_total_cost': '100.00',
          'base_unit_cost': '10.000',
          'allocated_additional_cost': '20.00',
          'final_unit_cost': '12.000',
          'final_total_cost': '120.00',
          'arrival_additional_cost': '55.00',
          'landed_unit_cost': '17.500',
        },
      ],
    });

    test('splits the planned costs from those paid on arrival', () {
      // Assert
      expect(order.plannedCosts.map((cost) => cost.name), ['توصيل']);
      expect(order.arrivalCosts.map((cost) => cost.name), ['نقل', 'جمارك']);
      expect(order.vendorAmount, '120.00');
      expect(order.hasCostsPaidElsewhere, isTrue);
    });

    test('says who was paid in words', () {
      // Assert
      expect(order.additionalCosts[0].paidByLabel, 'على فاتورة المورد');
      expect(order.additionalCosts[1].paidByLabel, 'دُفعت من الخزنة الرئيسية');
      expect(order.additionalCosts[2].paidByLabel, 'علينا لـالمخلّص');
    });

    test('a line tells what its stock entered at apart from the planned price', () {
      // Arrange
      final line = order.items.single;

      // Assert
      expect(line.unitCostLabel, '12');
      expect(line.landedDiffersFromPlanned, isTrue);
      expect(line.landedCostLabel, '17.5');
      expect(line.hasArrivalCost, isTrue);
    });
  });

  group('the receive sheet', () {
    const order = PurchaseOrder(
      id: 12,
      vendorId: 3,
      status: PurchaseOrderStatus.arrived,
      statusLabel: 'قيد الاستلام',
      orderDate: '2026-10-11',
      items: [
        PurchaseOrderItem(
          id: 50,
          stockItemId: 3,
          quantityOrdered: '10.000',
          quantityReceived: '0.000',
          quantityRemaining: '10.000',
        ),
      ],
    );

    Widget host(void Function(ReceivedShipment? result) onClosed) => ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  onClosed(await showReceiveArrivalSheet(context: context, order: order)),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    );

    Future<void> openAndAddACost(WidgetTester tester, {required String amount}) async {
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(0), '10');
      await tester.ensureVisible(find.text('إضافة تكلفة'));
      await tester.tap(find.text('إضافة تكلفة'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).at(1), 'نقل');
      await tester.enterText(find.byType(TextFormField).at(2), amount);
      await tester.ensureVisible(find.text('تسجيل الشحنة'));
      await tester.tap(find.text('تسجيل الشحنة'));
      await tester.pumpAndSettle();
    }

    testWidgets('hands back the costs typed with the quantities', (tester) async {
      // Arrange
      ReceivedShipment? result;
      await tester.pumpWidget(host((shipment) => result = shipment));

      // Act
      await openAndAddACost(tester, amount: '30');

      // Assert — on the vendor's bill: nobody here may spend from a drawer
      expect(result, isNotNull);
      expect(result!.quantities, {3: '10'});
      expect(result!.additionalCosts.single.name, 'نقل');
      expect(result!.additionalCosts.single.amount, '30');
      expect(result!.additionalCosts.single.treasuryAccountId, isNull);
    });

    testWidgets('a cost of nothing paid on arrival is refused before sending', (tester) async {
      // Arrange
      var closed = false;
      await tester.pumpWidget(host((_) => closed = true));

      // Act
      await openAndAddACost(tester, amount: '0');

      // Assert
      expect(closed, isFalse);
      expect(find.text('القيمة يجب أن تكون أكبر من صفر'), findsOneWidget);
    });
  });
}
