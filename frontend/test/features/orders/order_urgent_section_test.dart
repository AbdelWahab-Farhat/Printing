import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_edit_page.dart';
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

/// قسم «الاستعجال» على «تعديل الطلبية».
///
/// **القسم لا يختفي، والمفتاح وحده هو ما يُقفل.** كان يُخفى في الطلبية المقفلة وعند من لا يملك
/// المنح، فكانت الشاشة نفسها تُفتح مرّةً وفيها القسم ومرّةً وليس فيها — ومن لم يجده لا يملك ما
/// يفرّق به بين «ممنوع» و«غير موجود». الحال الآن كحال «البنود» تحته: القسم واقف، والسطر يقول
/// لماذا أُقفل.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;

  Order order({bool isUrgent = false, bool isClosed = false}) => Order(
    id: 55,
    code: '55',
    status: isClosed ? OrderStatus.delivered : OrderStatus.ready,
    statusLabel: isClosed ? 'تم الاستلام' : 'جاهزة',
    isFinal: false,
    isClosed: isClosed,
    isUrgent: isUrgent,
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
          unsettleOrder: UnsettleOrder(repository),
          undoOrderDelivery: UndoOrderDelivery(repository),
          deleteOrder: DeleteOrder(repository),
          restoreOrder: RestoreOrder(repository),
          confirmReadyMessage: ConfirmReadyMessage(repository),
          confirmDepositReceipt: ConfirmDepositReceipt(repository),
        ),
      );
  }

  Widget edit() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: OrderEditPage(orderId: 55),
    ),
  );

  /// Whether the switch on screen will take a tap.
  bool isSwitchLive(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).onChanged != null;

  tearDown(Injector.reset);

  testWidgets('a clerk on an open order gets the switch, live', (tester) async {
    // Arrange
    await sign(['orders.view', 'orders.manage'], order());

    // Act
    await tester.pumpWidget(edit());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الاستعجال'), findsOneWidget);
    expect(find.text('طلبية مستعجلة'), findsOneWidget);
    expect(isSwitchLive(tester), isTrue);
  });

  testWidgets('the switch starts where the order already stands', (tester) async {
    // Arrange — seeded from the order, so the screen never opens disagreeing with the badge on
    // the card that led to it.
    await sign(['orders.view', 'orders.manage'], order(isUrgent: true));

    // Act
    await tester.pumpWidget(edit());
    await tester.pumpAndSettle();

    // Assert
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
  });

  testWidgets('a reader without the grant still sees it, shut', (tester) async {
    // Arrange — present rather than hidden: «ليس لك» and «غير موجود» must not look the same.
    await sign(['orders.view'], order(isUrgent: true));

    // Act
    await tester.pumpWidget(edit());
    await tester.pumpAndSettle();

    // Assert — and it still reads the truth about the order while it is shut.
    expect(find.text('الاستعجال'), findsOneWidget);
    expect(isSwitchLive(tester), isFalse);
    expect(tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value, isTrue);
    expect(find.text('لا تملك صلاحية تعديل الطلبية'), findsOneWidget);
  });

  testWidgets('a closed order says so rather than dropping the section', (tester) async {
    // Arrange — `UpdateOrder` refuses a closed order, so the switch is shut on the server's own
    // line rather than on a status this screen checks for itself.
    await sign(['orders.view', 'orders.manage'], order(isClosed: true));

    // Act
    await tester.pumpWidget(edit());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الاستعجال'), findsOneWidget);
    expect(isSwitchLive(tester), isFalse);
    expect(find.text('الاستعجال مقفل بعد إغلاق الطلبية'), findsOneWidget);
  });

  testWidgets('it sits above the lines, not under them', (tester) async {
    // Arrange — أقصر سؤالٍ على الشاشة وأكثر ما تُفتح لأجله، فلا يُدفن تحت قائمةِ بنودٍ قد تمتدّ
    // خارج الشاشة.
    await sign(['orders.view', 'orders.manage'], order());

    // Act
    await tester.pumpWidget(edit());
    await tester.pumpAndSettle();

    // Assert
    expect(
      tester.getCenter(find.text('الاستعجال')).dy,
      lessThan(tester.getCenter(find.text('البنود')).dy),
    );
  });
}
