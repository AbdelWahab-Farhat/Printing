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
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// When the order screen offers «إرسال للنورس», and when it says nothing.
///
/// **Three conditions, and all three are the screen's alone to decide whether to *offer*.** The
/// server refuses a hand-over it will not make — by name, in Arabic the clerk can read — so
/// nothing here is a second copy of a rule. It is the difference between a button that does
/// nothing and a button that is not there.
///
/// 1. «جاهزة». An order still in production has nothing for a courier to carry.
/// 2. A delivery. «استلام مكتب» never leaves the building.
/// 3. `carrier.manage`. A different grant from `orders.manage` — handing goods to a courier is
///    not editing paperwork.
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
  );

  /// The signed-in reader, with whatever grants the case is about.
  Future<void> sign(List<String> permissions, Order answer) async {
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
              permissions: permissions,
            ),
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

  testWidgets('a ready delivery, held by someone who may dispatch, offers it', (tester) async {
    // Arrange
    await sign(['orders.view', 'carrier.manage'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.overflowKey), findsOneWidget);
  });

  testWidgets('an order still in production does not offer it', (tester) async {
    // Arrange — the bags are not made yet, so there is nothing for a courier to carry.
    await sign(
      ['orders.view', 'carrier.manage'],
      order(status: OrderStatus.printing, statusLabel: 'قيد الطباعة'),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.overflowKey), findsNothing);
  });

  testWidgets('an office pickup never offers it', (tester) async {
    // Arrange — «استلام مكتب» does not leave the building, so handing it to a courier would be
    // inventing a journey it is not making.
    await sign(['orders.view', 'carrier.manage'], order(officePickup: true));

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.overflowKey), findsNothing);
  });

  testWidgets('a returned order is offered the re-send and not the send', (tester) async {
    // Arrange — the two are opposite moments: «إرسال» is for goods that have not left, «إعادة
    // الإرسال» is for goods that came back. Offering both at once would be offering a choice
    // that does not exist.
    await sign(
      ['orders.view', 'carrier.manage'],
      order(status: OrderStatus.returnedCourier, statusLabel: 'راجع لدى المندوب'),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderDetailHeader.overflowKey));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.resendShipmentKey), findsOneWidget);
    expect(find.byKey(OrderDetailHeader.sendToCarrierKey), findsNothing);
  });

  testWidgets('a ready order is offered the send and not the re-send', (tester) async {
    // Arrange
    await sign(['orders.view', 'carrier.manage'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderDetailHeader.overflowKey));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.sendToCarrierKey), findsOneWidget);
    expect(find.byKey(OrderDetailHeader.resendShipmentKey), findsNothing);
  });

  testWidgets('both moments can still take a hand-over back', (tester) async {
    // Arrange — a parcel may need deleting or unlinking whichever of the two moments it is in.
    await sign(
      ['orders.view', 'carrier.manage'],
      order(status: OrderStatus.returnedOffice, statusLabel: 'راجع مكتب'),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(OrderDetailHeader.overflowKey));
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.deleteShipmentKey), findsOneWidget);
    expect(find.byKey(OrderDetailHeader.unlinkShipmentKey), findsOneWidget);
  });

  testWidgets('a delivered order offers no carrier menu at all', (tester) async {
    // Arrange — «تم الاستلام» is the end of the journey; there is nothing left to ask a courier.
    await sign(
      ['orders.view', 'carrier.manage'],
      order(status: OrderStatus.delivered, statusLabel: 'تم الاستلام'),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.overflowKey), findsNothing);
  });

  testWidgets('without carrier.manage it is not offered', (tester) async {
    // Arrange — `orders.manage` is not this grant, and holding the first is not holding the
    // second.
    await sign(['orders.view', 'orders.manage'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byKey(OrderDetailHeader.overflowKey), findsNothing);
  });
}
