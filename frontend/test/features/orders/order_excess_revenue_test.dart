import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_detail_cubit.dart';
import 'package:dayaa/features/orders/presentation/views/order_detail_page.dart';
import 'package:dayaa/features/orders/presentation/widgets/order_money_row.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/archive_order.dart';
import 'package:dayaa/features/orders/usecases/confirm_deposit_receipt.dart';
import 'package:dayaa/features/orders/usecases/confirm_ready_message.dart';
import 'package:dayaa/features/orders/usecases/get_order.dart';
import 'package:dayaa/features/orders/usecases/manage_order_designs.dart';
import 'package:dayaa/features/orders/usecases/reinstate_order.dart';
import 'package:dayaa/features/orders/usecases/undo_order_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «الزائد» — ما دفعه الزبون فوق الطلبية — من السلك إلى شاشة الطلبية.
///
/// منذ ٢٠٢٦-١٠-٠٧ يقف «المدفوع» عند سعر الطلبية ويصير الزائدُ إيراداً، فلا يراه أحدٌ إلا في
/// صفوف الدفعات. الخادمُ يجمعه في `excess_revenue_amount`، وهذه المجموعة تُلزم التطبيقَ بقراءته
/// وبإيصاله إلى بطاقة المال كما هو.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  group('the wire', () {
    test('the ledger summary reads it', () {
      // Arrange
      final json = {
        'grand_total': '40000.00',
        'paid_amount': '40000.00',
        'excess_revenue_amount': '500.00',
        'remaining_amount': '0.00',
        'payment_status': 'paid',
        'payment_status_label': 'مدفوعة بالكامل',
      };

      // Act
      final summary = PaymentSummary.fromJson(json);

      // Assert
      expect(summary.excessRevenueAmount, '500.00');
      expect(summary.hasExcessRevenue, isTrue);
    });

    test('a server from before it reads as nothing beyond', () {
      // Arrange — no `excess_revenue_amount` key, which is also what a list row carries.
      final json = {
        'grand_total': '40000.00',
        'paid_amount': '40000.00',
        'remaining_amount': '0.00',
        'payment_status': 'paid',
        'payment_status_label': 'مدفوعة بالكامل',
      };

      // Act
      final summary = PaymentSummary.fromJson(json);

      // Assert
      expect(summary.excessRevenueAmount, '0.00');
      expect(summary.hasExcessRevenue, isFalse);
    });
  });

  group('the order screen', () {
    late _MockOrderRepository repository;

    final order = Order(
      id: 55,
      code: '55',
      status: OrderStatus.delivered,
      statusLabel: 'تم الاستلام',
      isFinal: false,
      customerId: 10,
      cityId: 1,
      designSource: 'customer',
      cityName: 'طرابلس',
      fulfilmentTypeLabel: 'استلام مكتب',
      isOfficePickup: true,
      designSourceLabel: 'من الزبون',
      itemsTotal: '40000.00',
      designFee: '0.00',
      deliveryPrice: '0.00',
      discount: '0.00',
      grandTotal: '40000.00',
      paidAmount: '40000.00',
      excessRevenueAmount: '500.00',
      remainingAmount: '0.00',
      paymentStatus: PaymentStatus.paid,
      paymentStatusLabel: 'مدفوعة بالكامل',
      placedAt: DateTime(2026, 10, 25),
    );

    setUp(() async {
      await Injector.reset();

      repository = _MockOrderRepository();
      when(() => repository.order(55)).thenAnswer((_) async => Right(order));

      sl
        ..registerSingleton<Session>(
          Session()
            ..adopt(
              const AuthUser(
                id: 1,
                name: 'عبدالوهاب',
                phone: '0911234567',
                permissions: ['orders.view', 'orders.payments.view'],
              ),
            ),
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
    });

    tearDown(Injector.reset);

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

    testWidgets('the money card carries what was paid beyond the order', (tester) async {
      // Arrange
      await tester.pumpWidget(host());

      // Act
      await tester.pumpAndSettle();
      final money = find.byType(OrderMoneyRow);

      // Assert
      expect(find.descendant(of: money, matching: find.text('الزائد')), findsOneWidget);
      expect(find.descendant(of: money, matching: find.text('500')), findsOneWidget);
    });
  });
}
