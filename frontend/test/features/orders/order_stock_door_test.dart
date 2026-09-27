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
import 'package:dayaa/features/orders/presentation/widgets/order_detail_header.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/archive_order.dart';
import 'package:dayaa/features/orders/usecases/confirm_deposit_receipt.dart';
import 'package:dayaa/features/orders/usecases/confirm_ready_message.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// When the order screen offers «المخزون» — what the order moved in the warehouse.
///
/// **Two conditions.** `inventory.view`, the ledger's own grant, which the API enforces too; and
/// an order that has drawn at all, read off `fulfillment_warehouse_id` — set when stock first
/// leaves and never cleared. Without the second the door opens onto an empty screen.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockCarrierRepository extends Mock implements CarrierRepository {}

void main() {
  late _MockOrderRepository repository;

  Order order({
    OrderStatus status = OrderStatus.ready,
    String statusLabel = 'جاهزة',
    bool officePickup = false,
    int? drewFrom = 3,
  }) => Order(
    id: 55,
    code: '55',
    status: status,
    statusLabel: statusLabel,
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: officePickup ? 'استلام مكتب' : 'توصيل',
    isOfficePickup: officePickup,
    designSourceLabel: 'من الزبون',
    itemsTotal: '110.00',
    designFee: '0.00',
    deliveryPrice: '15.00',
    discount: '0.00',
    grandTotal: '125.00',
    remainingAmount: '125.00',
    paymentStatusLabel: 'غير مدفوعة',
    fulfillmentWarehouseId: drewFrom,
  );

  /// The signed-in reader, with whatever grants the case is about.
  Future<void> sign(List<String> permissions, Order answer) async {
    await Injector.reset();

    repository = _MockOrderRepository();
    when(() => repository.order(55)).thenAnswer((_) async => Right(answer));

    sl
      ..registerSingleton<Session>(
        Session()..adopt(
          AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions),
        ),
      )
      ..registerLazySingleton<UpdateOrderInvoice>(() => UpdateOrderInvoice(repository))
      // Registered but never reached: these tests press nothing, and a missing registration
      // would fail for a reason that has nothing to do with what is being asked.
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
        (order, _) => OrderInvoiceCubit(order: order, updateInvoice: sl<UpdateOrderInvoice>()),
      )
      ..registerFactoryParam<OrderDetailCubit, int, void>(
        (orderId, _) => OrderDetailCubit(
          orderId: orderId,
          getOrder: GetOrder(repository),
          addDesign: AddOrderDesign(repository),
          reviewDesign: ReviewOrderDesign(repository),
          reinstateOrder: ReinstateOrder(repository),
          deleteOrder: DeleteOrder(repository),
          restoreOrder: RestoreOrder(repository),
          confirmReadyMessage: ConfirmReadyMessage(repository),
          confirmDepositReceipt: ConfirmDepositReceipt(repository),
        ),
      );
  }

  Widget host(Widget page) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: page,
    ),
  );

  Widget detail() => host(const OrderDetailPage(orderId: 55));

  tearDown(Injector.reset);

  testWidgets('an order that drew, read by someone who may see stock, offers it', (tester) async {
    // Arrange
    await sign(['orders.view', 'inventory.view'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.stockKey), findsOneWidget);
  });

  testWidgets('without the ledger grant the door is absent', (tester) async {
    // Arrange — may read the order, may not read the warehouse.
    await sign(['orders.view'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.stockKey), findsNothing);
  });

  testWidgets('an order that never drew has nothing to show', (tester) async {
    // Arrange — still being designed: no shelf has been named, so nothing has left one.
    await sign([
      'orders.view',
      'inventory.view',
    ], order(status: OrderStatus.designing, statusLabel: 'قيد التصميم', drewFrom: null));

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.stockKey), findsNothing);
  });
}
