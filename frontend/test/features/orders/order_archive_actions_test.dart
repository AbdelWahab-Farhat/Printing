import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/carrier/repositories/carrier_repository.dart';
import 'package:dayaa/features/carrier/usecases/lodge_order.dart';
import 'package:dayaa/features/carrier/usecases/release_shipment.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/models/stock_effect.dart';
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
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «حذف الطلبية» and «استعادة الطلبية» on the order's own screen.
///
/// **What is being pinned is that not one Arabic sentence in the confirmation is written in
/// Dart.** The headline, the lines, their units and the closing note all arrive on the order as
/// `stock_effect`; §٧ gives the two reasons that has to be so — the wording reaches every
/// installed build without a release, and the preview is built from the same accessor the
/// action reads, so «سيُعاد إلى المخزن» cannot promise something the delete will not do. These
/// tests therefore assert on *the server's strings*, and a screen that composed its own would
/// fail them.
///
/// **And that the two never appear together.** An order is either in the shop or in الأرشيف, so
/// the dial offers exactly one of them — [Order.isArchived] decides which, and each sits behind
/// its own grant.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _MockCarrierRepository extends Mock implements CarrierRepository {}

void main() {
  late _MockOrderRepository repository;

  /// The delete's preview: goods still drawn, so they come back.
  const returning = StockEffect(
    stock: WarehouseEffect(
    kind: StockEffectKind.returnToShelf,
    warning: 'سيُعاد إلى المخزن ما خصمته هذه الطلبية:',
    lines: [StockEffectLine(label: 'كيس شحن 25*35', quantity: '300', unit: 'قطعة')],
    ),
  );

  /// The restore's: drawn again, and the cost may not be the cost it left with.
  const rededucting = StockEffect(
    stock: WarehouseEffect(
    kind: StockEffectKind.rededuct,
    warning: 'سيُخصم من المخزن من جديد:',
    lines: [StockEffectLine(label: 'كيس شحن 25*35', quantity: '300', unit: 'قطعة')],
    note: 'وقد تختلف تكلفة الطلبية عمّا كانت، لأن الخصم الجديد يأكل طبقات اليوم',
    ),
  );

  Order order({
    DateTime? deletedAt,
    StockEffect? effect = returning,
    OrderStatus? reinstateTo,
    String? reinstateToLabel,
  }) => Order(
    reinstateTo: reinstateTo,
    reinstateToLabel: reinstateToLabel,
    id: 55,
    code: '55',
    status: OrderStatus.ready,
    statusLabel: 'جاهزة',
    isFinal: false,
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
    deletedAt: deletedAt,
    stockEffect: effect,
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
      // Registered and never reached, exactly as `send_to_carrier_visibility_test.dart` does:
      // a missing registration would fail these for a reason none of them is about.
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

  /// Opens the dial, which keeps its labels hidden until it is.
  ///
  /// **This step is the one §٨ warns about.** [AppSpeedDial] renders a single surviving action
  /// as a plain extended button and two or more as a closed dial, so a screen that gains an arm
  /// silently changes how every one of its labels is reached. These tests all grant
  /// `orders.payments.view` beside whatever they are about, which keeps the dial a dial.
  Future<void> openTheDial(WidgetTester tester) async {
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();
  }

  /// Takes the toast off the screen.
  ///
  /// A snackbar floats over the corner the dial lives in, so a test that presses something,
  /// reads the confirmation and then presses the dial again would be trying to tap through it.
  Future<void> clearTheToast(WidgetTester tester) async {
    resetSnackBars();
    await tester.pump();
  }

  tearDown(Injector.reset);

  testWidgets('a live order is offered «حذف الطلبية», never «استعادة»', (tester) async {
    // Arrange
    await sign(['orders.view', 'orders.payments.view', 'orders.delete'], order());
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Act
    await openTheDial(tester);

    // Assert
    expect(find.text('حذف الطلبية'), findsOneWidget);
    expect(find.text('استعادة الطلبية'), findsNothing);
  });

  testWidgets('an archived order is offered «استعادة», never «حذف»', (tester) async {
    // Arrange — the same screen, the same grants, one field different on the order.
    await sign(
      ['orders.view', 'orders.payments.view', 'orders.delete', 'orders.restore'],
      order(deletedAt: DateTime(2026, 9, 10), effect: rededucting),
    );
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Act
    await openTheDial(tester);

    // Assert
    expect(find.text('استعادة الطلبية'), findsOneWidget);
    expect(find.text('حذف الطلبية'), findsNothing);
  });

  testWidgets('without the grant, neither arm is on the dial', (tester) async {
    // Arrange — a courtesy rather than a boundary: the server refuses regardless. What it
    // spares is somebody starting work they cannot finish.
    await sign(['orders.view', 'orders.payments.view'], order());
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Act
    await openTheDial(tester);

    // Assert
    expect(find.text('حذف الطلبية'), findsNothing);
    expect(find.text('استعادة الطلبية'), findsNothing);
  });

  testWidgets('the delete asks first, in the words the server sent', (tester) async {
    // Arrange
    await sign(['orders.view', 'orders.payments.view', 'orders.delete'], order());
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Act
    await tester.tap(find.text('حذف الطلبية'));
    await tester.pumpAndSettle();

    // Assert — the headline and the line, both `stock_effect`'s. Nothing was sent.
    expect(find.text('سيُعاد إلى المخزن ما خصمته هذه الطلبية:'), findsOneWidget);
    expect(find.text('كيس شحن 25*35'), findsOneWidget);
    expect(find.text('300 قطعة'), findsOneWidget);
    verifyNever(() => repository.deleteOrder(any()));
  });

  testWidgets('the restore says the cost may change, and that is the server\'s sentence too', (
    tester,
  ) async {
    // Arrange — the one thing nobody would guess: the new deduction eats today's layers.
    await sign(
      ['orders.view', 'orders.payments.view', 'orders.restore'],
      order(deletedAt: DateTime(2026, 9, 10), effect: rededucting),
    );
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Act
    await tester.tap(find.text('استعادة الطلبية'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('سيُخصم من المخزن من جديد:'), findsOneWidget);
    expect(
      find.text('وقد تختلف تكلفة الطلبية عمّا كانت، لأن الخصم الجديد يأكل طبقات اليوم'),
      findsOneWidget,
    );
  });

  testWidgets('confirming sends the delete and redraws the order as archived', (tester) async {
    // Arrange — the response *is* the order, trashed, so the screen stays open on it and the
    // dial turns over to «استعادة» with no second request.
    await sign(
      ['orders.view', 'orders.payments.view', 'orders.delete', 'orders.restore'],
      order(),
    );
    when(() => repository.deleteOrder(55)).thenAnswer(
      (_) async => Right(order(deletedAt: DateTime(2026, 9, 10), effect: rededucting)),
    );
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);
    await tester.tap(find.text('حذف الطلبية'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('حذف').last);
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.deleteOrder(55)).called(1);
    expect(find.text('نُقلت الطلبية إلى الأرشيف'), findsOneWidget);

    await clearTheToast(tester);
    await openTheDial(tester);
    expect(find.text('استعادة الطلبية'), findsOneWidget);
  });

  testWidgets('a refusal is the server\'s own sentence, and the order stays put', (tester) async {
    // Arrange — «عليها مبلغ مدفوع» names what to do first, and could not be written here
    // without this app holding a copy of the order's ledger.
    await sign(['orders.view', 'orders.payments.view', 'orders.delete'], order());
    when(() => repository.deleteOrder(55)).thenAnswer(
      (_) async => const Left(
        Failure.server(message: 'لا يمكن حذف طلبية عليها مبلغ مدفوع — اعكس الدفعات أولاً'),
      ),
    );
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);
    await tester.tap(find.text('حذف الطلبية'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('حذف').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(
      find.text('لا يمكن حذف طلبية عليها مبلغ مدفوع — اعكس الدفعات أولاً'),
      findsOneWidget,
    );

    await clearTheToast(tester);
    await openTheDial(tester);
    expect(find.text('حذف الطلبية'), findsOneWidget);
  });

  testWidgets('an archived order without orders.restore is offered no way back', (
    tester,
  ) async {
    // Arrange — holding «حذف» is not holding «استعادة». They are two grants because they are
    // two decisions, and the second draws stock off the shelf a second time — so somebody
    // trusted to take a duplicate row out of the shop is not automatically trusted to put one
    // back at today's cost.
    await sign(
      ['orders.view', 'orders.payments.view', 'orders.delete'],
      order(deletedAt: DateTime(2026, 9, 10), effect: rededucting),
    );
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Act
    await openTheDial(tester);

    // Assert — and «حذف» does not reappear to fill the gap: the order is already archived.
    expect(find.text('استعادة الطلبية'), findsNothing);
    expect(find.text('حذف الطلبية'), findsNothing);
  });

  testWidgets('a live order held by somebody with only orders.restore offers nothing', (
    tester,
  ) async {
    // Arrange — the mirror, and it is the arm that would be easy to leak: a single
    // `AppPermission` on both arms would have shown «حذف» to whoever may only restore.
    await sign(['orders.view', 'orders.payments.view', 'orders.restore'], order());
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Act
    await openTheDial(tester);

    // Assert
    expect(find.text('حذف الطلبية'), findsNothing);
    expect(find.text('استعادة الطلبية'), findsNothing);
  });

  testWidgets('the delete dialog carries no note — that sentence belongs to the restore', (
    tester,
  ) async {
    // Arrange — «وقد تختلف تكلفة الطلبية» is about a *new* deduction eating today's layers, and
    // a delete makes none. The screen must not draw the note for whichever preview it is given:
    // it draws the one the server put on this order and no other.
    await sign(['orders.view', 'orders.payments.view', 'orders.delete'], order());
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Act
    await tester.tap(find.text('حذف الطلبية'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('سيُعاد إلى المخزن ما خصمته هذه الطلبية:'), findsOneWidget);
    expect(
      find.text('وقد تختلف تكلفة الطلبية عمّا كانت، لأن الخصم الجديد يأكل طبقات اليوم'),
      findsNothing,
    );
  });

  testWidgets('the restore lists what it is about to draw, line by line', (tester) async {
    // Arrange — the note is the second half of that dialog; the first is still a list of goods,
    // and «كم» is the number somebody checks a shelf against before agreeing.
    await sign(
      ['orders.view', 'orders.payments.view', 'orders.restore'],
      order(deletedAt: DateTime(2026, 9, 10), effect: rededucting),
    );
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Act
    await tester.tap(find.text('استعادة الطلبية'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('كيس شحن 25*35'), findsOneWidget);
    expect(find.text('300 قطعة'), findsOneWidget);
  });

  testWidgets('a preview that moves nothing still asks, and draws no list', (tester) async {
    // Arrange — an order whose stock a cancellation already put back. §٧ says «حذف بلا خصمٍ
    // قائم: لا سطر مخزون أصلاً», and the server still sends a sentence: «لا شيء يتحرّك» is an
    // answer worth reading before a delete, where an empty dialog would read as one that failed
    // to load.
    await sign(
      ['orders.view', 'orders.payments.view', 'orders.delete'],
      order(
        effect: const StockEffect(
          stock: WarehouseEffect(
          kind: StockEffectKind.none,
          warning: 'لن يتحرّك أي مخزون بحذف هذه الطلبية.',
          ),
        ),
      ),
    );
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Act
    await tester.tap(find.text('حذف الطلبية'));
    await tester.pumpAndSettle();

    // Assert — the sentence, the confirm button, and nothing between them.
    expect(find.text('لن يتحرّك أي مخزون بحذف هذه الطلبية.'), findsOneWidget);
    expect(find.text('كيس شحن 25*35'), findsNothing);
    expect(find.text('حذف'), findsOneWidget);
  });

  testWidgets('walking out of the dialog sends nothing', (tester) async {
    // Arrange — «إلغاء» is the answer, and so is the barrier being unavailable: a stray tap
    // outside must not be one of the two ways to archive an order.
    await sign(['orders.view', 'orders.payments.view', 'orders.delete'], order());
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);
    await tester.tap(find.text('حذف الطلبية'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // Assert
    verifyNever(() => repository.deleteOrder(any()));
    expect(find.text('نُقلت الطلبية إلى الأرشيف'), findsNothing);
  });

  testWidgets('a refusal says nothing about success, and the order is still live', (
    tester,
  ) async {
    // Arrange — the failure arm has to be silent about the thing that did not happen. A
    // «نُقلت الطلبية إلى الأرشيف» beside the refusal is two sentences that contradict each
    // other, and the reader believes whichever one they read first.
    await sign(['orders.view', 'orders.payments.view', 'orders.delete'], order());
    when(() => repository.deleteOrder(55)).thenAnswer(
      (_) async =>
          const Left(Failure.server(message: 'لا يمكن حذف طلبية لها طرد مفتوح لدى نورس')),
    );
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);
    await tester.tap(find.text('حذف الطلبية'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('حذف').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(find.text('نُقلت الطلبية إلى الأرشيف'), findsNothing);

    await clearTheToast(tester);
    await openTheDial(tester);
    expect(find.text('حذف الطلبية'), findsOneWidget);
    expect(find.text('استعادة الطلبية'), findsNothing);
  });

  // ───────────────────── the preview the screen came back without ─────────────────────

  testWidgets('an order carrying no preview has one fetched before the dialog', (tester) async {
    // Arrange — exactly what «تغيير الحالة» leaves behind. `stock_effect` is sent by show,
    // destroy and restore alone, so the order that screen pops with — and which this one keeps
    // rather than re-reading — has none. The tap used to do nothing at all: no dialog, no
    // sentence, no request.
    await sign(['orders.view', 'orders.payments.view', 'orders.delete'], order(effect: null));
    var reads = 0;
    when(() => repository.order(55)).thenAnswer((_) async {
      reads++;

      return Right(reads == 1 ? order(effect: null) : order());
    });
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Act
    await tester.tap(find.text('حذف الطلبية'));
    await tester.pumpAndSettle();

    // Assert — the server's own headline, fetched on the spot, and nothing deleted yet.
    expect(find.text('سيُعاد إلى المخزن ما خصمته هذه الطلبية:'), findsOneWidget);
    expect(reads, 2);
    verifyNever(() => repository.deleteOrder(any()));
  });

  testWidgets('a preview the server never sends stops the delete out loud', (tester) async {
    // Arrange — an older server, or a payload trimmed on the way. Whatever the reason, the one
    // thing this must not be is silence: «حذف الطلبية» that draws nothing and says nothing is a
    // button the user presses again harder.
    await sign(['orders.view', 'orders.payments.view', 'orders.delete'], order(effect: null));
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    await openTheDial(tester);

    // Act
    await tester.tap(find.text('حذف الطلبية'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert — one of ours, and it is the only sentence in this feature that is: there is no
    // server sentence to show, because the server said nothing.
    expect(
      find.text('تعذّر معرفة ما ستفعله هذه العملية بالمخزون — أعد المحاولة'),
      findsOneWidget,
    );
    verifyNever(() => repository.deleteOrder(any()));
    await clearTheToast(tester);
  });

  testWidgets('a refused re-read for the preview is the server\'s own sentence', (tester) async {
    // Arrange — the fetch is a request like any other and can be refused like any other.
    await sign(['orders.view', 'orders.payments.view', 'orders.delete'], order(effect: null));
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();
    when(() => repository.order(55)).thenAnswer(
      (_) async => const Left(Failure.network(message: 'تعذّر الاتصال بالخادم')),
    );
    await openTheDial(tester);

    // Act
    await tester.tap(find.text('حذف الطلبية'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert — theirs, not ours, and said once.
    expect(find.text('تعذّر الاتصال بالخادم'), findsOneWidget);
    expect(
      find.text('تعذّر معرفة ما ستفعله هذه العملية بالمخزون — أعد المحاولة'),
      findsNothing,
    );
    verifyNever(() => repository.deleteOrder(any()));
    await clearTheToast(tester);
  });

  // ───────────────────── what an archived order says about itself ─────────────────────

  testWidgets('an archived order says so, instead of blaming the reader', (tester) async {
    // Arrange — every grant there is. A trashed order arrives with no `available_transitions`
    // at all (§٦), so `hasActions` is false and the note used to fall through to «لا تملك
    // صلاحية» — telling an administrator holding everything that they lack a permission.
    await sign(
      [
        'orders.view',
        'orders.payments.view',
        'orders.manage',
        'orders.delete',
        'orders.restore',
      ],
      order(deletedAt: DateTime(2026, 9, 10), effect: rededucting),
    );
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('لا تملك صلاحية تغيير حالة هذه الطلبية'), findsNothing);
    expect(find.text('الطلبية في الأرشيف — لا تُغيَّر حالتها قبل استعادتها'), findsOneWidget);
  });

  testWidgets('an archived cancelled order is offered no «تراجع عن الإلغاء»', (tester) async {
    // Arrange — `reinstate_to` is not withheld from a trashed order, so the button would be
    // drawn under a note that has just said the order is in الأرشيف: two sentences arguing, and
    // the tap earns a 404 because every write route refuses a deleted order.
    //
    // **A phone-shaped surface rather than the 800×600 default**, because this test's whole
    // claim is that something is *absent*: the button sits under the note, which is the last
    // thing the default viewport has room to build, and a sliver that was never built would
    // pass this test without the fix.
    tester.view.physicalSize = const Size(1290, 2796);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await sign(
      ['orders.view', 'orders.payments.view', 'orders.restore'],
      order(
        deletedAt: DateTime(2026, 9, 10),
        effect: rededucting,
        reinstateTo: OrderStatus.ready,
        reinstateToLabel: 'جاهزة',
      ),
    );
    await tester.pumpWidget(detail());
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('تراجع عن الإلغاء'), findsNothing);
    expect(find.text('الطلبية في الأرشيف — لا تُغيَّر حالتها قبل استعادتها'), findsOneWidget);
  });
}
