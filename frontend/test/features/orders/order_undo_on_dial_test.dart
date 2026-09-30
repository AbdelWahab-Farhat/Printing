import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';
import 'package:dayaa/features/carrier/usecases/lodge_order.dart';
import 'package:dayaa/features/carrier/usecases/release_shipment.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/archive_order.dart';
import 'package:dayaa/features/orders/usecases/confirm_deposit_receipt.dart';
import 'package:dayaa/features/orders/usecases/confirm_ready_message.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:dayaa/features/orders/usecases/undo_order_step.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «تراجع عن التسليم» و«تراجع عن التسوية» على الزر العائم، لا زراً عريضاً وسط الصفحة.
///
/// **الاسم وحده على الزر.** الوجهة والمخاطر مكانها نافذة التأكيد، وهي تقولها قبل أن يُرسَل
/// شيء — فالزر لا يحمل «— ترجع إلى …» بعد اليوم.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockCarrierRepository extends Mock implements CarrierRepository {}

void main() {
  late _MockOrderRepository repository;

  Order delivered({DateTime? deletedAt}) => Order(
    id: 55,
    code: '55',
    status: OrderStatus.delivered,
    statusLabel: 'تم الاستلام',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'استلام مكتب',
    isOfficePickup: true,
    designSourceLabel: 'من الزبون',
    itemsTotal: '60.00',
    designFee: '0.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '60.00',
    remainingAmount: '30.00',
    paymentStatusLabel: 'مدفوعة جزئياً',
    undoDeliveryTo: OrderStatus.officePickup,
    undoDeliveryToLabel: 'استلام مكتب',
    availableTransitions: const [
      OrderTransition(status: OrderStatus.settled, label: 'تم التسوية'),
    ],
    deletedAt: deletedAt,
  );

  Order settled() => const Order(
    id: 55,
    code: '55',
    status: OrderStatus.settled,
    statusLabel: 'تم التسوية',
    isFinal: true,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'استلام مكتب',
    isOfficePickup: true,
    designSourceLabel: 'من الزبون',
    itemsTotal: '60.00',
    designFee: '0.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '60.00',
    remainingAmount: '0.00',
    paymentStatusLabel: 'مدفوعة',
    canUnsettle: true,
  );

  Future<void> sign(Order answer) async {
    await Injector.reset();

    repository = _MockOrderRepository();
    when(() => repository.order(55)).thenAnswer((_) async => Right(answer));

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            const AuthUser(
              id: 1,
              name: 'عبدالوهاب',
              phone: '0911234567',
              permissions: ['orders.view', 'orders.payments.view'],
            ),
          ),
      )
      ..registerLazySingleton<UpdateOrderInvoice>(() => UpdateOrderInvoice(repository))
      ..registerLazySingleton<LodgeOrder>(() => LodgeOrder(_MockCarrierRepository()))
      ..registerLazySingleton<ResendCarrierShipment>(
        () => ResendCarrierShipment(_MockCarrierRepository()),
      )
      ..registerLazySingleton<DeleteCarrierShipment>(
        () => DeleteCarrierShipment(_MockCarrierRepository()),
      )
      ..registerLazySingleton<UnlinkCarrierShipment>(
        () => UnlinkCarrierShipment(_MockCarrierRepository()),
      )
      ..registerFactoryParam<OrderInvoiceCubit, Order, void>(
        (order, _) =>
            OrderInvoiceCubit(order: order, updateInvoice: sl<UpdateOrderInvoice>()),
      )
      ..registerFactoryParam<OrderDetailCubit, int, void>(
        (orderId, _) => OrderDetailCubit(
          orderId: orderId,
          getOrder: GetOrder(repository),
          addDesign: AddOrderDesign(repository),
          reviewDesign: ReviewOrderDesign(repository),
          reinstateOrder: ReinstateOrder(repository),
          unsettleOrder: UnsettleOrder(repository),
          undoOrderDelivery: UndoOrderDelivery(repository),
          deleteOrder: DeleteOrder(repository),
          restoreOrder: RestoreOrder(repository),
          confirmReadyMessage: ConfirmReadyMessage(repository),
          confirmDepositReceipt: ConfirmDepositReceipt(repository),
        ),
      );
  }

  /// على مقاس هاتف، لأن بعض ما يُثبَت هنا غيابُ زرٍّ من الصفحة، والصفحة على مقاس ٨٠٠×٦٠٠
  /// لا تبني ما تحت بطاقة العميل أصلاً — فتنجح المقارنة بلا إصلاح.
  Future<void> open(WidgetTester tester, Order answer) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await sign(answer);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: [Locale('ar')],
          localizationsDelegates: [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: OrderDetailPage(orderId: 55),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openTheDial(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();
  }

  tearDown(Injector.reset);

  testWidgets('a delivered order offers «تراجع عن التسليم» on the dial, by name alone', (
    tester,
  ) async {
    // Arrange
    await open(tester, delivered());

    // Act
    await openTheDial(tester);

    // Assert
    expect(find.text('تراجع عن التسليم'), findsOneWidget);
    expect(find.textContaining('ترجع إلى'), findsNothing);
  });

  testWidgets('a settled order offers «تراجع عن التسوية» on the dial, by name alone', (
    tester,
  ) async {
    // Arrange
    await open(tester, settled());

    // Act
    await openTheDial(tester);

    // Assert
    expect(find.text('تراجع عن التسوية'), findsOneWidget);
    expect(find.textContaining('ترجع إلى'), findsNothing);
  });

  testWidgets('the page itself no longer carries an undo button', (tester) async {
    // Arrange — the dial closed, so only what the page draws is on screen.

    // Act
    await open(tester, delivered());

    // Assert
    expect(find.textContaining('تراجع عن التسليم'), findsNothing);
  });

  testWidgets('the dial\'s arm asks first, and the dialog names where the order goes', (
    tester,
  ) async {
    // Arrange
    await open(tester, delivered());
    await openTheDial(tester);

    // Act
    await tester.tap(find.text('تراجع عن التسليم'));
    await tester.pumpAndSettle();

    // Assert — nothing sent; the destination is said before the tap that sends it.
    expect(find.textContaining('ترجع الطلبية إلى «استلام مكتب»'), findsOneWidget);
    verifyNever(() => repository.undoDelivery(any(), reason: any(named: 'reason')));
  });

  testWidgets('a settled order draws no note about what may be undone', (tester) async {
    // Arrange — «الطلبية تم التسوية — والتسوية وحدها ما يمكن التراجع عنه» stood under the
    // customer card; the undo is on the dial, and the user had the sentence removed.

    // Act
    await open(tester, settled());

    // Assert
    expect(find.textContaining('ما يمكن التراجع عنه'), findsNothing);
    expect(find.textContaining('لا مزيد من الإجراءات'), findsNothing);
  });

  testWidgets('an archived delivered order offers no undo on the dial', (tester) async {
    // Arrange — every write on a trashed order is a 404, whatever `undo_delivery_to` says.
    await open(tester, delivered(deletedAt: DateTime(2026, 9, 10)));

    // Act
    await openTheDial(tester);

    // Assert
    expect(find.textContaining('تراجع عن التسليم'), findsNothing);
  });
}
