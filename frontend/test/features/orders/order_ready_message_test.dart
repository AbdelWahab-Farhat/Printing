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

/// قسم «رسالة الجاهزية» على شاشة الطلبية.
///
/// **ثلاثة أسئلة، ولكلٍّ منها صاحبٌ مختلف يجيب عنه:**
///
/// 1. **هل يُرسَم القسم أصلاً؟** الخادم يجيب بـ`ready_message_applies` — «بلغت الطلبية الجاهزية»
///    مقروءاً من `ready_at`، لا مقارنةَ حالاتٍ تُكتب هنا. فيبقى مرسوماً بعد التسليم أيضاً، لأنّ
///    «هل أُبلِغ أصلاً؟» يُسأل بعد خروج الطرد لا قبله.
/// 2. **هل يُفتح المفتاح؟** `orders.ready_message` — والقسم لا يختفي بدونها، على قاعدة
///    «الاستعجال»: «ليس لك» و«غير موجود» يجب ألّا يتشابها.
/// 3. **ماذا يقول حين يكون مضبوطاً؟** مَن ضغطه ومتى — وهي الواقعة نفسها، إذ الغرض من الخانة
///    التأكّد من أنّ الموظف المسؤول أرسل الرسالة.
///
/// See Docs/orders/ORDER-READY-MESSAGE.md.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockCarrierRepository extends Mock implements CarrierRepository {}

void main() {
  late _MockOrderRepository repository;

  Order order({
    bool applies = true,
    bool sent = false,
    OrderStatus status = OrderStatus.ready,
    String statusLabel = 'جاهزة',
    OrderActor? sentBy,
    DateTime? sentAt,
  }) => Order(
    id: 55,
    code: '55',
    status: status,
    statusLabel: statusLabel,
    isFinal: false,
    readyMessageApplies: applies,
    isReadyMessageSent: sent,
    readyMessageSentBy: sentBy,
    readyMessageSentAt: sentAt,
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

  /// The one switch this screen draws. Absent altogether before «جاهزة», which is why every
  /// case that expects it asserts on the section's title first.
  SwitchListTile theSwitch(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byType(SwitchListTile));

  tearDown(Injector.reset);

  testWidgets('a ready order gives its holder the switch, live', (tester) async {
    // Arrange
    await sign(['orders.view', 'orders.ready_message'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert — the switch's own word is what is looked for: it shares «نسخ الفاتورة»'s card and
    // carries no heading of its own, because the two are one errand and a title over them would
    // print one meaning twice.
    expect(find.text('تم إرسال رسالة الجاهزية للزبون'), findsOneWidget);
    expect(theSwitch(tester).onChanged, isNotNull);
  });

  testWidgets('it shares one card with «نسخ الفاتورة»', (tester) async {
    // Arrange — انسخ، أرسل، علّم: عملٌ واحد في ثلاث خطوات، ففصلُه في بطاقتين يجعل الخطوة الأخيرة
    // شيئاً يُبحَث عنه بدل أن تكون حيث انتهت الخطوة التي قبلها.
    await sign(['orders.view', 'orders.ready_message'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert — the same ancestor holds both, and no heading stands over them.
    final card = find.ancestor(
      of: find.text('نسخ الفاتورة'),
      matching: find.ancestor(
        of: find.text('تم إرسال رسالة الجاهزية للزبون'),
        matching: find.byType(Container),
      ),
    );
    expect(card, findsWidgets);
    expect(find.text('رسالة الجاهزية'), findsNothing);
  });

  testWidgets('an order that has not been ready draws no section at all', (tester) async {
    // Arrange — nothing is made, so there is nobody to tell. The server says so with
    // `ready_message_applies`, and the write behind the switch would refuse anyway.
    await sign([
      'orders.view',
      'orders.ready_message',
    ], order(applies: false, status: OrderStatus.printing, statusLabel: 'قيد الطباعة'));

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert — and «نسخ الفاتورة» stays: the card is the invoice's, and the mark only joins it
    // once there is something to tell the customer about.
    expect(find.text('تم إرسال رسالة الجاهزية للزبون'), findsNothing);
    expect(find.byType(SwitchListTile), findsNothing);
    expect(find.text('نسخ الفاتورة'), findsOneWidget);
  });

  testWidgets('it stays after the parcel has left', (tester) async {
    // Arrange — `ready_at` is stamped once and never cleared, so «هل أُبلِغ أصلاً؟» is still
    // askable while the order is out for delivery. That is the whole reason the section is drawn
    // off the server's answer rather than off the status.
    await sign([
      'orders.view',
      'orders.ready_message',
    ], order(status: OrderStatus.outForDelivery, statusLabel: 'جاري التوصيل'));

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تم إرسال رسالة الجاهزية للزبون'), findsOneWidget);
  });

  testWidgets('a reader without the grant still sees it, shut', (tester) async {
    // Arrange — «أُرسلت الرسالة» is a fact about the order, and everybody who may read the order
    // may read it. Hiding the section would make «ليس لك» and «غير موجود» look the same.
    await sign(['orders.view'], order(sent: true));

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert — shut, and still telling the truth about the order while it is shut.
    expect(find.text('تم إرسال رسالة الجاهزية للزبون'), findsOneWidget);
    expect(theSwitch(tester).onChanged, isNull);
    expect(theSwitch(tester).value, isTrue);
  });

  testWidgets('a marked order names who sent it and when', (tester) async {
    // Arrange — the point of the box is confirming that the person responsible did the work, so
    // their name is the answer rather than a footnote to it.
    await sign(
      ['orders.view', 'orders.ready_message'],
      order(
        sent: true,
        sentBy: const OrderActor(id: 3, name: 'سالم'),
        sentAt: DateTime(2026, 8, 14, 14),
      ),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('أرسلها سالم'), findsOneWidget);
  });

  testWidgets('an unmarked order says nothing about who or when', (tester) async {
    // Arrange — nothing has happened, so there is nothing to record.
    await sign(['orders.view', 'orders.ready_message'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('أرسلها'), findsNothing);
  });

  testWidgets('ticking it sends the confirmation and redraws from the answer', (tester) async {
    // Arrange — the switch follows the server, never the tap: the stamp and the name come back
    // on the order, and neither could be invented here.
    await sign(['orders.view', 'orders.ready_message'], order());
    when(() => repository.confirmReadyMessage(55, sent: true)).thenAnswer(
      (_) async => Right(
        order(
          sent: true,
          sentBy: const OrderActor(id: 1, name: 'عبدالوهاب'),
          sentAt: DateTime(2026, 8, 14, 14),
        ),
      ),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    // Brought into view first: the section sits under the header and the customer card, and the
    // floating dial hangs over the bottom of the list — a tap at a location the widget is not
    // actually at is warned about and then does nothing.
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.confirmReadyMessage(55, sent: true)).called(1);
    expect(theSwitch(tester).value, isTrue);
    expect(find.textContaining('أرسلها عبدالوهاب'), findsOneWidget);
  });

  testWidgets('unticking a marked order takes the record back', (tester) async {
    // Arrange — the undo of a stray tap, and it costs the same grant. Both movements stay in the
    // order's own history.
    await sign([
      'orders.view',
      'orders.ready_message',
    ], order(sent: true, sentBy: const OrderActor(id: 3, name: 'سالم')));
    when(
      () => repository.confirmReadyMessage(55, sent: false),
    ).thenAnswer((_) async => Right(order()));

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    // Brought into view first: the section sits under the header and the customer card, and the
    // floating dial hangs over the bottom of the list — a tap at a location the widget is not
    // actually at is warned about and then does nothing.
    await tester.ensureVisible(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.confirmReadyMessage(55, sent: false)).called(1);
    expect(theSwitch(tester).value, isFalse);
    expect(find.textContaining('أرسلها'), findsNothing);
  });
}
