import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_message.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_customer_card.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_invoice_actions.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_money_row.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Getting the order out of the app and into the customer's chat.
///
/// **Two doors, on purpose.** «نسخ الفاتورة» sits under the header, in the open, because sending
/// the order on is what happens right after somebody reads what state it is in; «مشاركة الفاتورة»
/// lives on the dial with the rest of the actions, because it opens the phone's own sheet and is
/// the rarer of the two.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;
  late Session session;

  const customer = Customer(
    id: 10,
    code: 'C10',
    name: 'عبدالوهاب',
    phone: '0944909850',
    isActive: true,
  );

  const item = OrderItem(
    id: 1,
    productId: 3,
    productVariantId: 9,
    productName: 'أكياس الشحن',
    variantLabel: '35*40',
    pricingUnitLabel: 'قطعة',
    quantity: '400',
    unitPrice: '1.050',
    lineTotal: '420.00',
  );

  final order = Order(
    id: 55,
    code: '55',
    status: OrderStatus.taken,
    statusLabel: 'جديدة',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'customer',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'استلام مكتب',
    isOfficePickup: true,
    designSourceLabel: 'من الزبون',
    itemsTotal: '420.00',
    designFee: '0.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '420.00',
    remainingAmount: '420.00',
    paymentStatusLabel: 'غير مدفوعة',
    customer: customer,
    items: const [item],
    placedAt: DateTime(2026, 8, 12),
  );

  setUp(() async {
    await Injector.reset();

    repository = _MockOrderRepository();
    session = Session()
      ..adopt(
        const AuthUser(
          id: 1,
          name: 'عبدالوهاب',
          phone: '0911234567',
          // Enough for the dial to be a dial: with one action surviving it collapses to a plain
          // button whose label is already on screen, and «is it hidden until opened» has no
          // meaning there. See AppSpeedDial.
          permissions: ['orders.view', 'orders.payments.view'],
        ),
      );

    when(() => repository.order(55)).thenAnswer((_) async => Right(order));

    sl
      ..registerSingleton<Session>(session)
      ..registerFactoryParam<OrderDetailCubit, int, void>(
        (orderId, _) => OrderDetailCubit(
          orderId: orderId,
          getOrder: GetOrder(repository),
          addDesign: AddOrderDesign(repository),
          reviewDesign: ReviewOrderDesign(repository),
        ),
      );
  });

  tearDown(Injector.reset);

  // The toast's bookkeeping is library-level, so it outlives the tree that raised it — and by the
  // time a `tearDown` runs, the Navigator that owns its ticker is already being torn down. Every
  // test that taps the copy button clears it while there is still a tree to clear it from.
  Future<void> clearTheToast(WidgetTester tester) async {
    resetSnackBars();
    await tester.pump();
  }

  /// Answers `Clipboard.setData` — the platform side is absent in a widget test — and reports
  /// what was put on it.
  ValueGetter<String?> watchTheClipboard(WidgetTester tester) {
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

    return () => copied;
  }

  Widget host() => ScreenUtilInit(
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

  testWidgets('the copy button sits under the header, above everything else', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.pumpAndSettle();
    // The header is a sliver; its flexible space is the box the list starts under.
    final header = tester.getRect(find.byType(FlexibleSpaceBar));
    final copy = tester.getRect(find.byType(CopyInvoiceButton));
    final money = tester.getRect(find.byType(OrderMoneyRow));

    // Assert — nothing between it and the status it follows.
    expect(copy.top, greaterThanOrEqualTo(header.bottom));
    expect(copy.bottom, lessThanOrEqualTo(money.top));
  });

  testWidgets('it takes the width, like every other button in the app', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.pumpAndSettle();

    // Assert — the width of the list's own column, measured against the card under it.
    expect(
      tester.getSize(find.byType(CopyInvoiceButton)).width,
      tester.getSize(find.byType(OrderCustomerCard)).width,
    );
  });

  testWidgets('pressing it puts the whole message on the clipboard', (tester) async {
    // Arrange
    final clipboard = watchTheClipboard(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(CopyInvoiceButton));
    await tester.pump();

    // Assert — the message itself, not a summary of it.
    expect(clipboard(), OrderMessage.of(order));
    await clearTheToast(tester);
  });

  testWidgets('it says so, because a clipboard gives no sign of its own', (tester) async {
    // Arrange
    watchTheClipboard(tester);
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byType(CopyInvoiceButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Assert
    expect(find.text('تم نسخ الفاتورة'), findsOneWidget);
    await clearTheToast(tester);
  });

  testWidgets('sharing the invoice is on the dial, not beside the copy button', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — the dial keeps its labels hidden until it is opened.
    expect(find.text('مشاركة الفاتورة'), findsNothing);
    await tester.tap(find.byType(FloatingActionButton).last);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('مشاركة الفاتورة'), findsOneWidget);
  });
}
