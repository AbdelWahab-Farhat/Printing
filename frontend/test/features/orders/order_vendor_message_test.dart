import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';
import 'package:dayaa/features/carrier/usecases/lodge_order.dart';
import 'package:dayaa/features/carrier/usecases/release_shipment.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_invoice_actions.dart';
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
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The «رسالة المورد» section on the order screen of an outsourced order.
///
/// Drawn on the server's word (`vendor_message_applies`: outsourced, and in «جديدة», «قيد
/// التصميم» or «قيد التصنيع»), live for a holder of `orders.status.manufacturing`, and shut but
/// visible for anybody else. Copying does not tick the switch.
///
/// See Docs/outsourced-products/OUTSOURCED-PRODUCTS.md §10.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockCarrierRepository extends Mock implements CarrierRepository {}

void main() {
  late _MockOrderRepository repository;

  const vendorText = 'طلبية جديدة من دعاية رقم : [ 55 ]\n• شنطة كرافت — 25×35 — 500 قطعة';

  Order order({bool applies = true, bool sent = false, OrderActor? sentBy}) => Order(
    id: 55,
    code: '55',
    status: OrderStatus.manufacturing,
    statusLabel: 'قيد التصنيع',
    isFinal: false,
    vendorMessageApplies: applies,
    isVendorMessageSent: sent,
    vendorMessageSentBy: sentBy,
    vendorMessageText: applies ? vendorText : null,
    vendorName: 'مطبعة الشرق',
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'من الزبون',
    itemsTotal: '110.00',
    designFee: '0.00',
    deliveryPrice: '15.00',
    discount: '0.00',
    grandTotal: '125.00',
    remainingAmount: '125.00',
    paymentStatusLabel: 'غير مدفوعة',
  );

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
      // Registered but never reached, exactly as `send_to_carrier_visibility_test` does it: a
      // missing registration would fail for a reason that has nothing to do with the question.
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
          unsettleOrder: UnsettleOrder(repository),
          undoOrderDelivery: UndoOrderDelivery(repository),
          deleteOrder: DeleteOrder(repository),
          restoreOrder: RestoreOrder(repository),
          confirmReadyMessage: ConfirmReadyMessage(repository),
          confirmReturnMessage: ConfirmReturnMessage(repository),
          confirmVendorMessage: ConfirmVendorMessage(repository),
          confirmDepositReceipt: ConfirmDepositReceipt(repository),
        ),
      );
  }

  Widget detail() => ScreenUtilInit(
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
  );

  SwitchListTile vendorSwitch(WidgetTester tester) => tester.widget<SwitchListTile>(
    find.ancestor(of: find.text('تم إرسال الطلبية للمورد'), matching: find.byType(SwitchListTile)),
  );

  tearDown(Injector.reset);

  testWidgets('an outsourced order draws the vendor message above the invoice button', (
    tester,
  ) async {
    // Arrange
    await sign(['orders.view', 'orders.status.manufacturing'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(CopyVendorMessageButton), findsOneWidget);
    expect(find.text('نسخ رسالة المورد'), findsOneWidget);
    expect(vendorSwitch(tester).onChanged, isNotNull);
    expect(
      tester.getRect(find.byType(CopyVendorMessageButton)).top,
      lessThan(tester.getRect(find.byType(CopyInvoiceButton)).top),
    );
  });

  testWidgets('an order the vendor message does not apply to draws no section', (tester) async {
    // Arrange
    await sign(['orders.view', 'orders.status.manufacturing'], order(applies: false));

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.byType(CopyVendorMessageButton), findsNothing);
    expect(find.text('تم إرسال الطلبية للمورد'), findsNothing);
  });

  testWidgets('the switch is drawn but locked without the manufacturing grant', (tester) async {
    // Arrange — the customer-messages grant is a different one.
    await sign(['orders.view', 'orders.ready_message'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(vendorSwitch(tester).onChanged, isNull);
  });

  testWidgets('pressing «نسخ رسالة المورد» copies the server text and leaves the switch', (
    tester,
  ) async {
    // Arrange
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (
      call,
    ) async {
      if (call.method == 'Clipboard.setData') {
        copied = (call.arguments as Map)['text'] as String?;
      }

      return null;
    });
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await sign(['orders.view', 'orders.status.manufacturing'], order());
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(CopyVendorMessageButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(copied, vendorText);
    expect(find.text('تم نسخ رسالة المورد'), findsOneWidget);
    expect(find.text('ألصقها في محادثة المورد'), findsOneWidget);
    verifyNever(() => repository.confirmVendorMessage(any(), sent: any(named: 'sent')));
    resetSnackBars();
    await tester.pump();
  });

  testWidgets('ticking the switch records who sent the job to the vendor', (tester) async {
    // Arrange
    await sign(['orders.view', 'orders.status.manufacturing'], order());
    when(() => repository.confirmVendorMessage(55, sent: true)).thenAnswer(
      (_) async => Right(order(sent: true, sentBy: const OrderActor(id: 1, name: 'عبدالوهاب'))),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    final tile = find.ancestor(
      of: find.text('تم إرسال الطلبية للمورد'),
      matching: find.byType(SwitchListTile),
    );
    await tester.ensureVisible(tile);
    await tester.pumpAndSettle();
    await tester.tap(tile);
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.confirmVendorMessage(55, sent: true)).called(1);
    expect(vendorSwitch(tester).value, isTrue);
    expect(find.textContaining('أرسلها عبدالوهاب'), findsOneWidget);
  });
}
