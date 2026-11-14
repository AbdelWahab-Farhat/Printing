import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/new_order.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/compensation_widgets.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_totals.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/take_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «طلبية تعويض» on the staff app — Docs/orders/ORDER-COMPENSATION.md.
///
/// Every figure is the server's string; these tests check what is sent and what is shown.
///
/// Arrange - Act - Assert throughout.
class _CapturingRepository extends Fake implements OrderRepository {
  NewOrder? sent;

  @override
  Future<Either<Failure, Order>> create(NewOrder order) async {
    sent = order;

    return const Left(Failure.unexpected(message: 'captured'));
  }
}

void main() {
  Widget host(Widget child) {
    return ScreenUtilInit(
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
          body: Directionality(
            textDirection: TextDirection.rtl,
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  Order compensation({List<SharedParcelOrder> compensatedBy = const []}) => Order(
    id: 9,
    code: '1250',
    status: OrderStatus.taken,
    statusLabel: 'جديدة',
    isFinal: false,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '500.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '0.00',
    paidAmount: '0.00',
    remainingAmount: '0.00',
    isCompensation: true,
    compensationReason: 'print_defect',
    compensationReasonLabel: 'خطأ طباعة',
    compensatesOrderId: 4,
    compensatesOrderCode: '1200',
    compensatedBy: compensatedBy,
  );

  group('what the new-order form sends', () {
    test('an ordinary order says nothing about compensation', () {
      // Arrange
      const order = NewOrder(customerId: 3, cityId: 1, designSource: 'none', items: []);

      // Act
      final json = order.toJson();

      // Assert
      expect(json.containsKey('is_compensation'), isFalse);
      expect(json.containsKey('compensation_reason'), isFalse);
    });

    test('a compensation sends its reason and original, and drops the charges', () async {
      // Arrange
      final repository = _CapturingRepository();

      // Act
      await TakeOrder(repository)(
        customerId: 3,
        cityId: 1,
        lines: const [DraftOrderLine(productId: 1, productVariantId: 2, quantity: '100')],
        discount: '30',
        additionalCost: '10',
        isCompensation: true,
        compensationReason: 'print_defect',
        compensationNote: '  حبر باهت  ',
        compensatesOrderId: 4,
      );

      // Assert
      final json = repository.sent!.toJson();
      expect(json['is_compensation'], isTrue);
      expect(json['compensation_reason'], 'print_defect');
      expect(json['compensation_note'], 'حبر باهت');
      expect(json['compensates_order_id'], 4);
      expect(json.containsKey('discount'), isFalse);
      expect(json.containsKey('additional_cost'), isFalse);
    });
  });

  group('the order', () {
    test('reads the links both ways off the server', () {
      // Act
      final order = Order.fromJson({
        ...compensation().toJson(),
        'compensated_by': [
          {'id': 11, 'code': '1300'},
        ],
      });

      // Assert
      expect(order.isCompensation, isTrue);
      expect(order.compensatesOrderCode, '1200');
      expect(order.compensatedBy.single.code, '1300');
    });

    testWidgets('the account takes the whole price off, so the total reads 0', (tester) async {
      // Act
      await tester.pumpWidget(host(OrderTotals(order: compensation())));

      // Assert
      expect(find.text('تعويض — بلا مقابل'), findsOneWidget);
      expect(find.textContaining('500'), findsWidgets);
    });

    testWidgets('the summary says why and names the original', (tester) async {
      // Arrange
      int? opened;

      // Act
      await tester.pumpWidget(host(CompensationSummary(order: compensation(), onOpenOrder: (id) => opened = id)));
      await tester.tap(find.text('تعويض عن الطلبية 1200'));

      // Assert
      expect(find.text('تعويض'), findsOneWidget);
      expect(find.textContaining('خطأ طباعة'), findsOneWidget);
      expect(opened, 4);
    });
  });
}
