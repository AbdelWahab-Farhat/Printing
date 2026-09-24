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

/// بطاقة «العربون» على شاشة الطلبية.
///
/// **ثلاث وقائع لا واحدة**، ولكلٍّ صاحبٌ مختلف: ما اتُّفق عليه، ومن قال إنّه دُفع، ومن رأى المال.
/// البطاقة تعرض الأولى وتسجّل الثالثة، والثانية أثرٌ في الطريق بينهما.
///
/// **والمفتاح مقفولٌ على `can_confirm_deposit` وحدها، لا على المنحة.** الخادم يطوي فيها أمرين:
/// المنحة، وقاعدة أنّ من نقل الطلبية إلى «عربون مدفوع» لا يؤكّد عربونها. الثاني سؤالٌ لا يملك
/// التطبيق جوابه — في صفّ القائمة لا يصله اسم من ادّعى أصلاً — فاشتقاقه هنا رأيٌ ثانٍ خاطئ.
///
/// **ولا تُقرأ الحالة لرسمها.** العربون يُؤكَّد بعد أن تمضي الطلبية بوقتٍ طويل، وبعد شحنها
/// أحياناً، فالسؤال «هل كان على هذه الطلبية عربون؟» لا «أين هي الآن؟».
///
/// **وتحت المفتاح المقفل سببه.** مفتاحٌ رماديٌّ تحته فراغ يُقرأ كشاشةٍ معطوبة، وهذه القاعدة
/// تحديداً لا يخمّنها واقفٌ أمامها.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockCarrierRepository extends Mock implements CarrierRepository {}

void main() {
  late _MockOrderRepository repository;

  Order order({
    String? expected = '250.00',
    String? methodLabel = 'كاش',
    bool received = false,
    bool canConfirm = true,
    OrderActor? claimedBy,
    OrderActor? confirmedBy,
    DateTime? confirmedAt,
    String paidAmount = '250.00',
  }) => Order(
    id: 55,
    code: '55',
    status: OrderStatus.depositPaid,
    statusLabel: 'عربون مدفوع',
    isFinal: false,
    depositExpectedAmount: expected,
    depositExpectedMethod: expected == null ? null : 'cash',
    depositExpectedMethodLabel: methodLabel,
    isDepositReceived: received,
    canConfirmDeposit: canConfirm,
    depositClaimedBy: claimedBy,
    depositConfirmedBy: confirmedBy,
    depositConfirmedAt: confirmedAt,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'من الزبون',
    itemsTotal: '1000.00',
    designFee: '0.00',
    deliveryPrice: '15.00',
    discount: '0.00',
    grandTotal: '1000.00',
    paidAmount: paidAmount,
    remainingAmount: '750.00',
    paymentStatusLabel: 'مدفوعة جزئياً',
  );

  /// Signs somebody in and answers `GET /orders/55` with [answer].
  ///
  /// [userId] is what makes «أنا من ادّعى» testable: the card compares it against
  /// `deposit_claimed_by` to choose which sentence sits under a greyed switch.
  Future<void> sign(List<String> permissions, Order answer, {int userId = 1}) async {
    await Injector.reset();

    repository = _MockOrderRepository();
    when(() => repository.order(55)).thenAnswer((_) async => Right(answer));

    sl
      ..registerSingleton<Session>(
        Session()..adopt(
          AuthUser(
            id: userId,
            name: 'عبدالوهاب',
            phone: '0911234567',
            permissions: permissions,
          ),
        ),
      )
      ..registerLazySingleton<UpdateOrderInvoice>(() => UpdateOrderInvoice(repository))
      // Registered but never reached, exactly as `order_ready_message_test` does it: a missing
      // registration would fail for a reason that has nothing to do with the question.
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

  /// The deposit switch — the only one on a screen whose ready-message card is not drawn, which
  /// every order here arranges by never having been «جاهزة».
  SwitchListTile theSwitch(WidgetTester tester) =>
      tester.widget<SwitchListTile>(find.byType(SwitchListTile));

  tearDown(Injector.reset);

  testWidgets('an order nobody asked a deposit of has no card at all', (tester) async {
    // Arrange — which is most orders. Read off the figure, never off the status.
    await sign(['orders.view', 'orders.deposit.confirm'], order(expected: null));

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تأكيد استلام العربون'), findsNothing);
  });

  testWidgets('a deposit of nothing is not a card either', (tester) async {
    // Arrange — طلبيةٌ ابتلع خصمُها فاتورتَها: مشت طريق العربون لتصل قائمة شغل المخزن، ولا مال
    // عليها. الخادم يردّ `can_confirm_deposit` كاذبة لأنّ لا شيء هناك يُرى في حساب.
    await sign(
      ['orders.view', 'orders.deposit.confirm'],
      order(expected: '0.00', methodLabel: null, canConfirm: false),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert — بطاقةٌ عنوانها «العربون 0» فوق مفتاحٍ لا يُضغط شرحٌ لشيءٍ لم يحدث.
    expect(find.text('تأكيد استلام العربون'), findsNothing);
  });

  testWidgets('the card states what was agreed, and how', (tester) async {
    // Arrange
    await sign(['orders.view', 'orders.deposit.confirm'], order());

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert — the arrangement is the heading; it is not money that has moved.
    expect(find.textContaining('العربون'), findsWidgets);
    expect(find.textContaining('250'), findsWidgets);
    expect(find.textContaining('كاش'), findsWidgets);
  });

  testWidgets('a colleague who may confirm it gets a live switch', (tester) async {
    // Arrange — somebody else made the claim, so this reader is the second person.
    await sign(
      ['orders.view', 'orders.deposit.confirm'],
      order(claimedBy: const OrderActor(id: 9, name: 'طه')),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تأكيد استلام العربون'), findsOneWidget);
    expect(theSwitch(tester).onChanged, isNotNull);
    expect(find.text('لم يُؤكَّد استلامه بعد'), findsOneWidget);
  });

  testWidgets('whoever claimed it is told why the switch is theirs to leave alone', (
    tester,
  ) async {
    // Arrange — the server refuses the claimer and says so through `can_confirm_deposit`; the
    // card only has to explain it.
    await sign(
      ['orders.view', 'orders.deposit.confirm'],
      order(canConfirm: false, claimedBy: const OrderActor(id: 1, name: 'عبدالوهاب')),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert — the rule is not one a person standing in front of it can guess.
    expect(theSwitch(tester).onChanged, isNull);
    expect(find.text('يؤكّد استلامَ العربون موظفٌ غير مَن نقل الطلبية'), findsOneWidget);
  });

  testWidgets('a reader without the grant sees the card, locked — «ليس لك» is not «غير موجود»', (
    tester,
  ) async {
    // Arrange — the same rule «الاستعجال» and «رسالة الجاهزية» follow: the section stands and
    // the switch is what locks, so nobody has to tell a missing control from a forbidden one.
    await sign(['orders.view'], order(canConfirm: false));

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تأكيد استلام العربون'), findsOneWidget);
    expect(theSwitch(tester).onChanged, isNull);
    expect(find.text('بانتظار التأكيد'), findsOneWidget);
  });

  testWidgets('the permission alone never opens the switch', (tester) async {
    // Arrange — the grant is held, and the server still says no. This is the whole reason the
    // card reads `can_confirm_deposit` rather than `AppPermission.confirmDepositReceipt`.
    await sign(['orders.view', 'orders.deposit.confirm'], order(canConfirm: false));

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(theSwitch(tester).onChanged, isNull);
  });

  testWidgets('once confirmed, the name and the stamp are the record', (tester) async {
    // Arrange
    await sign(
      ['orders.view', 'orders.deposit.confirm'],
      order(
        received: true,
        confirmedBy: const OrderActor(id: 9, name: 'طه'),
        confirmedAt: DateTime(2026, 9, 13, 14),
      ),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert — who confirmed it is the fact itself, not a footnote on it.
    expect(theSwitch(tester).value, isTrue);
    expect(find.textContaining('أكّده طه'), findsOneWidget);
  });

  testWidgets('a confirmed deposit with nothing in the till says so, and blocks nothing', (
    tester,
  ) async {
    // Arrange — the tick is a person's statement and the ledger is arithmetic. The gap between
    // them is the accountant's job.
    await sign(
      ['orders.view', 'orders.deposit.confirm'],
      order(received: true, paidAmount: '0.00', confirmedBy: const OrderActor(id: 9, name: 'طه')),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert — surfaced, never prevented: the switch stays exactly as usable as it was.
    expect(find.text('أُكِّد استلام العربون ولم تُسجَّل دفعة عليه'), findsOneWidget);
    expect(theSwitch(tester).onChanged, isNotNull);
  });

  testWidgets('a deposit recorded against real money draws no contradiction', (tester) async {
    // Arrange
    await sign(
      ['orders.view', 'orders.deposit.confirm'],
      order(received: true, confirmedBy: const OrderActor(id: 9, name: 'طه')),
    );

    // Act
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert — a warning that appears in every state is a warning nobody reads.
    expect(find.text('أُكِّد استلام العربون ولم تُسجَّل دفعة عليه'), findsNothing);
  });

  testWidgets('ticking it sends the order back stamped, and nothing is re-read', (tester) async {
    // Arrange
    final confirmed = order(
      received: true,
      canConfirm: false,
      confirmedBy: const OrderActor(id: 1, name: 'عبدالوهاب'),
      confirmedAt: DateTime(2026, 9, 13, 14),
    );
    await sign(['orders.view', 'orders.deposit.confirm'], order());
    when(
      () => repository.confirmDepositReceipt(55, received: true),
    ).thenAnswer((_) async => Right(confirmed));

    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('تأكيد استلام العربون'));
    await tester.pumpAndSettle();

    // Assert — the switch follows the server's answer, and the order is read exactly once.
    verify(() => repository.confirmDepositReceipt(55, received: true)).called(1);
    verify(() => repository.order(55)).called(1);
    expect(find.textContaining('أكّده عبدالوهاب'), findsOneWidget);
  });
}
