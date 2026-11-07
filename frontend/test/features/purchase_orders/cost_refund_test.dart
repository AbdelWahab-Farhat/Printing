import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/purchase_order_detail_cubit.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/cost_refund_sheet.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/cost_refunds.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository_impl.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «استرداد التكلفة» — what the app sends, and when it offers the button.
/// Docs/purchase-orders/PURCHASE-ORDER-ARRIVAL-COSTS.md §7.
///
/// Arrange - Act - Assert throughout.
class _MockPurchaseOrderRepository extends Mock
    implements PurchaseOrderRepository {}

void main() {
  const cost = PurchaseOrderAdditionalCost(
    id: 5,
    name: 'توصيل',
    amount: '20.00',
    treasuryAccountId: 1,
    refundableAmount: '20.00',
  );

  group('on the wire', () {
    late PurchaseOrderRepositoryImpl repository;
    late RequestOptions captured;

    setUp(() {
      final dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            captured = options;
            handler.reject(
              DioException(requestOptions: options, message: 'captured'),
              true,
            );
          },
        ),
      );
      repository = PurchaseOrderRepositoryImpl(dio);
    });

    test(
      'a refund normalises the amount and leaves the reason alone',
      () async {
        // Act
        await RefundCost(repository)(
          7,
          5,
          amount: '١٢,٥',
          reason: '  أعاد ٥ دنانير  ',
        );

        // Assert
        expect(captured.method, 'POST');
        expect(captured.path, '/purchase-orders/7/additional-costs/5/refunds');
        expect(captured.data, {'amount': '12.5', 'reason': 'أعاد ٥ دنانير'});
      },
    );

    test('taking one back carries the reason alone', () async {
      // Act
      await ReverseCostRefund(repository)(7, 5, 9, reason: 'سُجّل بالخطأ');

      // Assert
      expect(captured.method, 'POST');
      expect(
        captured.path,
        '/purchase-orders/7/additional-costs/5/refunds/9/reversal',
      );
      expect(captured.data, {'reason': 'سُجّل بالخطأ'});
    });
  });

  test('reads what the server says about a cost', () {
    // Act
    final read = PurchaseOrderAdditionalCost.fromJson({
      'id': 5,
      'name': 'توصيل',
      'amount': '20.00',
      'treasury_account_id': 1,
      'refundable_amount': '7.50',
      'refunds': [
        {
          'id': 9,
          'amount': '12.50',
          'reason': 'أعاد السائق المبلغ',
          'recorded_by_name': 'سالم',
          'created_at': '2026-11-04T10:00:00+00:00',
          'is_reversed': false,
          'reversal_reason': null,
        },
      ],
    });

    // Assert
    expect(read.hasRefundableAmount, isTrue);
    expect(read.refunds.single.amountLabel, '12.5');
    expect(read.refunds.single.recordedByName, 'سالم');
  });

  test('a cost the list sent, without the figure, offers no refund', () {
    // Act
    const read = PurchaseOrderAdditionalCost(
      id: 5,
      name: 'نقل',
      amount: '20.00',
    );

    // Assert
    expect(read.hasRefundableAmount, isFalse);
  });

  group('the cubit', () {
    late _MockPurchaseOrderRepository repository;
    late PurchaseOrderDetailCubit cubit;

    const order = PurchaseOrder(
      id: 7,
      vendorId: 3,
      status: PurchaseOrderStatus.cancelled,
      statusLabel: 'ملغى',
      orderDate: '2026-11-01',
    );
    const refusal = Failure.server(
      message: 'أقصى ما يمكن استرداده من هذه التكلفة 7.50',
      statusCode: 422,
    );

    setUp(() {
      repository = _MockPurchaseOrderRepository();
      cubit = PurchaseOrderDetailCubit(
        purchaseOrderId: 7,
        getOrder: GetPurchaseOrder(repository),
        changeStatus: ChangePurchaseOrderStatus(repository),
        receiveArrival: ReceivePurchaseOrderArrival(repository),
        reverseReceiptUseCase: ReverseReceipt(repository),
        refundCostUseCase: RefundCost(repository),
        reverseCostRefundUseCase: ReverseCostRefund(repository),
      );
      when(
        () => repository.purchaseOrder(7),
      ).thenAnswer((_) async => const Right(order));
    });

    tearDown(() => cubit.close());

    test('re-reads the order after a refund', () async {
      // Arrange
      await cubit.load();
      when(
        () => repository.refundCost(7, 5, amount: '20', reason: 'أعاده'),
      ).thenAnswer((_) async => const Right(order));

      // Act
      final failure = await cubit.refundCost(5, amount: '20', reason: 'أعاده');

      // Assert
      expect(failure, isNull);
      verify(() => repository.purchaseOrder(7)).called(2);
    });

    test('hands a refusal back to the sheet', () async {
      // Arrange
      await cubit.load();
      when(
        () => repository.refundCost(7, 5, amount: '20', reason: 'أعاده'),
      ).thenAnswer((_) async => const Left(refusal));

      // Act
      final failure = await cubit.refundCost(5, amount: '20', reason: 'أعاده');

      // Assert
      expect(failure, refusal);
    });
  });

  group('the button', () {
    Widget host(Widget child) => ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (_, _) => MaterialApp(
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(body: child),
        ),
      ),
    );

    Widget refunds(
      PurchaseOrderAdditionalCost cost, {
      bool canRefund = true,
      VoidCallback? onRefund,
      ValueChanged<PurchaseOrderCostRefund>? onReverse,
    }) => host(
      CostRefunds(
        cost: cost,
        canRefund: canRefund,
        onRefund: onRefund ?? () {},
        onReverse: onReverse ?? (_) {},
      ),
    );

    const live = PurchaseOrderCostRefund(
      id: 9,
      amount: '12.50',
      reason: 'أعاد السائق المبلغ',
    );

    testWidgets('is offered while money is left', (tester) async {
      // Arrange
      var tapped = false;
      await tester.pumpWidget(refunds(cost, onRefund: () => tapped = true));

      // Act
      await tester.tap(find.byKey(const ValueKey('cost-refund-5')));

      // Assert
      expect(tapped, isTrue);
    });

    testWidgets('is not offered without the grant, or the status', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(refunds(cost, canRefund: false));

      // Assert
      expect(find.byKey(const ValueKey('cost-refund-5')), findsNothing);
    });

    testWidgets('is not offered once nothing is left, and the refund stays', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(
        refunds(cost.copyWith(refundableAmount: '0.00', refunds: const [live])),
      );

      // Assert
      expect(find.byKey(const ValueKey('cost-refund-5')), findsNothing);
      expect(find.textContaining('أعاد السائق المبلغ'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('cost-refund-reverse-9')),
        findsOneWidget,
      );
    });

    testWidgets('a refund already taken back cannot be taken back again', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(
        refunds(
          cost.copyWith(
            refunds: [
              live.copyWith(isReversed: true, reversalReason: 'سُجّل بالخطأ'),
            ],
          ),
        ),
      );

      // Assert
      expect(find.byKey(const ValueKey('cost-refund-reverse-9')), findsNothing);
      expect(find.textContaining('سُجّل بالخطأ'), findsOneWidget);
    });
  });

  group('the sheet', () {
    Widget host(Future<Failure?> Function(String, String) onConfirm) =>
        ScreenUtilInit(
          designSize: const Size(390, 844),
          builder: (_, _) => MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showCostRefundSheet(
                    context: context,
                    cost: cost,
                    onConfirm: onConfirm,
                  ),
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        );

    Future<void> open(WidgetTester tester) async {
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
    }

    Future<void> confirm(WidgetTester tester) async {
      await tester.ensureVisible(find.byKey(const Key('cost-refund-confirm')));
      await tester.tap(find.byKey(const Key('cost-refund-confirm')));
      await tester.pumpAndSettle();
    }

    testWidgets('starts at everything left and asks for a reason', (
      tester,
    ) async {
      // Arrange
      String? sent;
      await tester.pumpWidget(
        host((amount, _) async {
          sent = amount;

          return null;
        }),
      );
      await open(tester);

      // Act — no reason yet
      await confirm(tester);

      // Assert
      expect(sent, isNull);
      expect(find.text('السبب مطلوب'), findsOneWidget);

      // Act
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('cost-refund-reason')),
          matching: find.byType(EditableText),
        ),
        'أعاد السائق المبلغ',
      );
      await confirm(tester);

      // Assert
      expect(sent, '20');
    });

    testWidgets('refuses more than is left before sending', (tester) async {
      // Arrange
      var calls = 0;
      await tester.pumpWidget(
        host((_, _) async {
          calls++;

          return null;
        }),
      );
      await open(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('cost-refund-amount')),
          matching: find.byType(EditableText),
        ),
        '21',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('cost-refund-reason')),
          matching: find.byType(EditableText),
        ),
        'أعاد السائق المبلغ',
      );

      // Act
      await confirm(tester);

      // Assert
      expect(calls, 0);
      expect(find.textContaining('أقصى ما يمكن استرداده'), findsOneWidget);
    });

    testWidgets('stays open to print a refusal', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          (_, _) async => const Failure.server(
            message: 'لم يبقَ ما يُسترد',
            statusCode: 422,
          ),
        ),
      );
      await open(tester);
      await tester.enterText(
        find.descendant(
          of: find.byKey(const Key('cost-refund-reason')),
          matching: find.byType(EditableText),
        ),
        'أعاد السائق المبلغ',
      );

      // Act
      await confirm(tester);

      // Assert
      expect(find.byKey(const Key('cost-refund-refusal')), findsOneWidget);
      expect(find.text('لم يبقَ ما يُسترد'), findsOneWidget);
    });
  });
}
