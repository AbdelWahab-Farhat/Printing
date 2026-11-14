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

/// «تعديل الطلبية» on the dial — offered in every status (owner's decision, 2026-11-11).
///
/// It used to follow the sections of the edit screen and vanish from «جاري التوصيل» on, taking
/// the discount with it. Now it is there for whoever may edit orders, and for whoever may
/// discount wherever the server says the discount is open. Never on an archived order.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockCarrierRepository extends Mock implements CarrierRepository {}

void main() {
  late _MockOrderRepository repository;

  Order orderIn(
    OrderStatus status, {
    bool discountIsEditable = true,
    DateTime? deletedAt,
  }) => Order(
    id: 55,
    code: '55',
    status: status,
    statusLabel: status.label,
    isFinal: false,
    isClosed: status.isFinished,
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
    paymentStatusLabel: 'مدفوعة',
    discountIsEditable: discountIsEditable,
    deletedAt: deletedAt,
  );

  Future<void> sign(Order answer, List<String> permissions) async {
    await Injector.reset();

    repository = _MockOrderRepository();
    when(() => repository.order(55)).thenAnswer((_) async => Right(answer));

    sl
      ..registerSingleton<Session>(
        Session()
          ..adopt(
            AuthUser(
              id: 1,
              name: 'عبدالوهاب',
              phone: '0911234567',
              permissions: ['orders.view', ...permissions],
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
          confirmReturnMessage: ConfirmReturnMessage(repository),
          confirmDepositReceipt: ConfirmDepositReceipt(repository),
        ),
      );
  }

  /// Opens the order on a phone-sized screen and opens its dial.
  Future<void> openTheDial(WidgetTester tester, Order answer, List<String> permissions) async {
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await sign(answer, permissions);

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

    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();
  }

  tearDown(Injector.reset);

  for (final status in [
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
    OrderStatus.settled,
    OrderStatus.cancelled,
  ]) {
    testWidgets('a clerk is offered the edit on an order in «${status.label}»', (tester) async {
      // Arrange — every one of these hid the button before.
      final order = orderIn(status, discountIsEditable: status != OrderStatus.cancelled);

      // Act
      await openTheDial(tester, order, ['orders.manage']);

      // Assert
      expect(find.text('تعديل الطلبية'), findsOneWidget);
    });
  }

  testWidgets('the discount grant alone opens it where the discount is open', (tester) async {
    // Arrange
    final order = orderIn(OrderStatus.delivered);

    // Act
    await openTheDial(tester, order, ['orders.discount']);

    // Assert
    expect(find.text('تعديل الطلبية'), findsOneWidget);
  });

  testWidgets('the discount grant alone does not open it where the discount is shut', (
    tester,
  ) async {
    // Arrange — «إلغاء تام»: nothing is owed, so the server shuts the discount.
    final order = orderIn(OrderStatus.cancelled, discountIsEditable: false);

    // Act
    await openTheDial(tester, order, ['orders.discount']);

    // Assert
    expect(find.text('تعديل الطلبية'), findsNothing);
  });

  testWidgets('somebody who may only read the order is not offered it', (tester) async {
    // Arrange
    final order = orderIn(OrderStatus.delivered);

    // Act
    await openTheDial(tester, order, const []);

    // Assert
    expect(find.text('تعديل الطلبية'), findsNothing);
  });

  testWidgets('an archived order is never offered it', (tester) async {
    // Arrange — every write on an archived order answers 404.
    final order = orderIn(OrderStatus.delivered, deletedAt: DateTime(2026, 9, 10));

    // Act
    await openTheDial(tester, order, ['orders.manage', 'orders.discount']);

    // Assert
    expect(find.text('تعديل الطلبية'), findsNothing);
  });
}
