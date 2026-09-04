import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/orders/models/additional_cost_reason.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa/features/orders/presentation/views/order_edit_page.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_additional_cost.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_totals.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The way to set the charge, on «تعديل الطلبية» with the rest of what can be changed.
///
/// **Changed on the edit screen, read on the order screen** — the same split the artwork
/// follows. The order screen prints the figure inside «الحساب» and names it underneath, because
/// that is the column it belongs to; the button that argues with it lives where every other
/// correction to the invoice does, and the order screen keeps one door onto editing instead of
/// two.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;

  Order order({
    String cost = '0.00',
    AdditionalCostReason? reason,
    bool isClosed = false,
  }) => Order(
    id: 55,
    code: '55',
    status: isClosed ? OrderStatus.delivered : OrderStatus.ready,
    statusLabel: isClosed ? 'تم الاستلام' : 'جاهزة',
    isFinal: false,
    isClosed: isClosed,
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
    additionalCost: cost,
    additionalCostReason: reason,
    additionalCostReasonLabel: reason?.label,
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

  Widget edit() => host(const OrderEditPage(orderId: 55));

  Widget detail() => host(const OrderDetailPage(orderId: 55));

  tearDown(Injector.reset);

  testWidgets('it stands on the edit screen, spanning it', (tester) async {
    // Arrange
    await sign(['orders.view', 'orders.additional_cost'], order());

    // Act
    await tester.pumpWidget(edit());
    await tester.pumpAndSettle();
    final button = find.widgetWithText(AppButton, 'إضافة تكلفة إضافية');
    await tester.scrollUntilVisible(button, 200);

    // Assert — the section's whole width, like every other action in the app.
    expect(button, findsOneWidget);
    expect(tester.getRect(button).width, greaterThan(300));
  });

  testWidgets('an order already carrying a charge is argued with, not added to', (
    tester,
  ) async {
    // Arrange
    await sign(
      ['orders.view', 'orders.additional_cost'],
      order(cost: '10.00', reason: AdditionalCostReason.transport),
    );

    // Act
    await tester.pumpWidget(edit());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.widgetWithText(AppButton, 'تعديل التكلفة الإضافية'),
      200,
    );

    // Assert — the word says which of the two acts this is, and the charge being argued with
    // is named above it.
    expect(find.text('تعديل التكلفة الإضافية'), findsOneWidget);
    expect(find.text('إضافة تكلفة إضافية'), findsNothing);
    expect(find.text('نقل'), findsOneWidget);
  });

  testWidgets('it opens the sheet, seeded with what the order carries', (tester) async {
    // Arrange
    await sign(
      ['orders.view', 'orders.additional_cost'],
      order(cost: '10.00', reason: AdditionalCostReason.specialPackaging),
    );
    await tester.pumpWidget(edit());
    await tester.pumpAndSettle();

    // Act
    final button = find.widgetWithText(AppButton, 'تعديل التكلفة الإضافية');
    await tester.scrollUntilVisible(button, 200);
    // Found in the tree is not the same as on the screen, and a tap at an offset past the
    // bottom edge hits nothing at all.
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();

    // Assert — the sheet's own words, and the amount the order already carries.
    expect(
      find.text('تُضاف إلى إجمالي الطلبية ويُطلب من الزبون دفعها. أفرغ الحقل لإلغائها.'),
      findsOneWidget,
    );
    expect(find.text('10'), findsOneWidget);
  });

  testWidgets('without the grant there is no button, and no section either', (
    tester,
  ) async {
    // Arrange — reading an order says nothing about being allowed to charge for one.
    await sign(['orders.view'], order());

    // Act
    await tester.pumpWidget(edit());
    await tester.pumpAndSettle();

    // Assert — absent, not greyed.
    expect(find.text('إضافة تكلفة إضافية'), findsNothing);
    expect(find.text('التكلفة الإضافية'), findsNothing);
  });

  testWidgets('a closed order is not offered one, because the server would refuse', (
    tester,
  ) async {
    // Arrange — `UpdateOrder` throws `OrderIsClosed` for exactly this order.
    await sign(['orders.view', 'orders.additional_cost'], order(isClosed: true));

    // Act
    await tester.pumpWidget(edit());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('إضافة تكلفة إضافية'), findsNothing);
  });

  testWidgets('the order screen prints the charge and offers no button for it', (
    tester,
  ) async {
    // Arrange — the grant is held, so an absent button is a decision about the screen and not
    // about this reader.
    await sign(
      ['orders.view', 'orders.additional_cost'],
      order(cost: '10.00', reason: AdditionalCostReason.transport),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byType(OrderTotals), 200);

    // Assert — «الحساب» adds up and names the charge on the line it belongs to. The section
    // that used to repeat the figure a card below it is gone, so «نقل» is read once; changing
    // the charge is still «تعديل الطلبية»'s business.
    expect(find.byType(OrderTotals), findsOneWidget);
    expect(find.byType(OrderAdditionalCost), findsNothing);
    expect(find.text('نقل'), findsOneWidget);
    expect(find.text('إضافة تكلفة إضافية'), findsNothing);
    expect(find.text('تعديل التكلفة الإضافية'), findsNothing);
  });
}
