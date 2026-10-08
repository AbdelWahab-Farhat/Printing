import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/payment_settlement_cubit.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_settlement_line.dart';
import 'package:dayaa/features/orders/presentation/widgets/settle_payments_sheet.dart';
import 'package:dayaa/features/orders/presentation/widgets/settlement_account_picker.dart';
import 'package:dayaa/features/orders/repositories/order_payment_repository.dart';
import 'package:dayaa/features/orders/usecases/manage_order_payments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderPaymentRepository extends Mock implements OrderPaymentRepository {}

/// «تسوية دفعة» — the page's filters, the line on a payment, and the sheet. TREASURY-DESIGN §٢٣.
///
/// **Every decision is the server's**: whether a payment may be settled or taken back, and where
/// its money goes when nobody picks. These tests hold the screen to drawing what it was told and
/// asking the server the question the chips say.
///
/// Arrange - Act - Assert throughout.
void main() {
  setUpAll(() {
    registerFallbackValue(SettlementState.pending);
    registerFallbackValue(<SettleRow>[]);
  });

  Widget host(Widget child) {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Directionality(textDirection: TextDirection.rtl, child: child),
        ),
      ),
    );
  }

  OrderPayment payment({
    int id = 1,
    String amount = '250.00',
    bool canSettle = false,
    bool canUnsettle = false,
    String? unsettleBlockedReason,
    PaymentAccountRef? account = const PaymentAccountRef(id: 9, name: 'النورس', kind: 'custody'),
    PaymentAccountRef? target = const PaymentAccountRef(id: 2, name: 'المصرف'),
    PaymentSettlement? settlement,
  }) {
    return OrderPayment(
      id: id,
      orderId: 7,
      type: OrderPaymentType.payment,
      typeLabel: 'دفعة',
      amount: amount,
      method: PaymentMethod.cash,
      methodLabel: 'كاش',
      order: PaymentOrderRef(id: 7, code: 'A-$id'),
      treasuryAccount: account,
      settlementTarget: target,
      canSettle: canSettle,
      canUnsettle: canUnsettle,
      unsettleBlockedReason: unsettleBlockedReason,
      settlement: settlement,
    );
  }

  group('the period', () {
    test('the week starts on Saturday', () {
      // Arrange — Tuesday 6 October 2026, Saturday 3rd, Friday 9th
      final tuesday = DateTime(2026, 10, 6, 15);
      final saturday = DateTime(2026, 10, 3, 9);
      final friday = DateTime(2026, 10, 9, 22);

      // Act
      final fromTuesday = SettlementPeriod.thisWeek.rangeAt(tuesday);
      final fromSaturday = SettlementPeriod.thisWeek.rangeAt(saturday);
      final fromFriday = SettlementPeriod.thisWeek.rangeAt(friday);

      // Assert
      expect(fromTuesday, (from: DateTime(2026, 10, 3), to: DateTime(2026, 10, 6)));
      expect(fromSaturday, (from: DateTime(2026, 10, 3), to: DateTime(2026, 10, 3)));
      expect(fromFriday, (from: DateTime(2026, 10, 3), to: DateTime(2026, 10, 9)));
    });

    test('today and this month are plain days; all and a custom range carry none here', () {
      // Arrange
      final now = DateTime(2026, 10, 7, 13, 30);

      // Act & Assert
      expect(SettlementPeriod.today.rangeAt(now), (from: DateTime(2026, 10, 7), to: DateTime(2026, 10, 7)));
      expect(SettlementPeriod.thisMonth.rangeAt(now), (from: DateTime(2026, 10), to: DateTime(2026, 10, 7)));
      expect(SettlementPeriod.all.rangeAt(now), isNull);
      expect(SettlementPeriod.custom.rangeAt(now), isNull);
    });
  });

  group('the payment as the server sends it', () {
    test('a settled payment carries where it went, what the carrier kept, and the undo', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 4,
        'order_id': 7,
        'type': 'payment',
        'type_label': 'دفعة',
        'amount': '250.00',
        'treasury_account': {'id': 9, 'name': 'النورس', 'kind': 'custody'},
        'settlement': {
          'operation_id': 31,
          'to_account': {'id': 2, 'name': 'المصرف'},
          'fee': '15.00',
          'received': '235.00',
          'settled_at': '2026-10-07T10:00:00+02:00',
          'settled_by': {'id': 3, 'name': 'سارة'},
        },
        'can_settle': false,
        'can_unsettle': true,
        'settlement_target': null,
      };

      // Act
      final parsed = OrderPayment.fromJson(json);

      // Assert
      expect(parsed.isSettled, isTrue);
      expect(parsed.isHeldByCarrier, isTrue);
      expect(parsed.settlement?.toAccount?.name, 'المصرف');
      expect(parsed.settlement?.hasFee, isTrue);
      expect(parsed.settlement?.settledBy?.name, 'سارة');
      expect(parsed.canUnsettle, isTrue);
    });

    test('a payment from a server that predates settling reads as nothing to settle', () {
      // Arrange
      final json = <String, dynamic>{
        'id': 4,
        'order_id': 7,
        'type': 'payment',
        'type_label': 'دفعة',
        'amount': '250.00',
      };

      // Act
      final parsed = OrderPayment.fromJson(json);

      // Assert
      expect(parsed.isSettled, isFalse);
      expect(parsed.canSettle, isFalse);
      expect(parsed.canUnsettle, isFalse);
    });
  });

  group('the line on a payment', () {
    testWidgets('a payment the server allows offers «تسوية» and says where it goes', (tester) async {
      // Arrange
      var settled = false;
      await tester.pumpWidget(
        host(
          PaymentSettlementLine(
            payment: payment(canSettle: true),
            isBusy: false,
            onSettle: () => settled = true,
            onUnsettle: () {},
          ),
        ),
      );

      // Act
      await tester.tap(find.text('تسوية'));

      // Assert
      expect(find.text('في النورس — تُسوّى إلى المصرف'), findsOneWidget);
      expect(settled, isTrue);
    });

    testWidgets('a settled payment names where it went and offers «تراجع»', (tester) async {
      // Arrange
      var undone = false;
      await tester.pumpWidget(
        host(
          PaymentSettlementLine(
            payment: payment(
              canUnsettle: true,
              settlement: const PaymentSettlement(
                operationId: 31,
                toAccount: PaymentAccountRef(id: 2, name: 'المصرف'),
                fee: '15.00',
                received: '235.00',
                settledBy: PaymentRecorder(id: 3, name: 'سارة'),
              ),
            ),
            isBusy: false,
            onSettle: () {},
            onUnsettle: () => undone = true,
          ),
        ),
      );

      // Act
      await tester.tap(find.text('تراجع'));

      // Assert
      expect(find.text('سُوّيت إلى المصرف · سارة'), findsOneWidget);
      expect(find.textContaining('احتفظ الناقل'), findsOneWidget);
      expect(undone, isTrue);
    });

    testWidgets('a settled payment on a settled order says why there is no «تراجع»', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          PaymentSettlementLine(
            payment: payment(
              unsettleBlockedReason: 'الطلبية «تم التسوية» — تراجع عن تسوية الطلبية أولاً',
              settlement: const PaymentSettlement(operationId: 31),
            ),
            isBusy: false,
            onSettle: () {},
            onUnsettle: () {},
          ),
        ),
      );

      // Assert
      expect(find.text('تراجع'), findsNothing);
      expect(find.text('الطلبية «تم التسوية» — تراجع عن تسوية الطلبية أولاً'), findsOneWidget);
    });

    testWidgets('nothing at all on a payment the server will not settle', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(PaymentSettlementLine(payment: payment(), isBusy: false, onSettle: () {}, onUnsettle: () {})),
      );

      // Assert
      expect(find.text('تسوية'), findsNothing);
      expect(find.textContaining('سُوّيت'), findsNothing);
    });
  });

  group('the sheet', () {
    Future<void> open(
      WidgetTester tester, {
      required List<OrderPayment> payments,
      required Future<Failure?> Function(List<SettleRow> rows, int? accountId) onSubmit,
    }) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showSettlePaymentsSheet(
                context: context,
                payments: payments,
                destinations: const [
                  SettlementAccount(id: 2, name: 'المصرف', kind: 'bank'),
                  SettlementAccount(id: 5, name: 'الخزنة', kind: 'cash'),
                ],
                onSubmit: onSubmit,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('a carrier\'s payment takes a fee, and «تلقائي» sends no account', (tester) async {
      // Arrange
      List<SettleRow>? sent;
      int? sentAccount = -1;
      await open(
        tester,
        payments: [payment(canSettle: true)],
        onSubmit: (rows, accountId) async {
          sent = rows;
          sentAccount = accountId;

          return null;
        },
      );

      // Act
      await tester.enterText(find.byKey(const ValueKey('settle-fee-1')), '15');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('settle-submit')));
      await tester.pumpAndSettle();

      // Assert
      expect(sent?.single.paymentId, 1);
      expect(sent?.single.fee, '15');
      expect(sentAccount, isNull);
      expect(find.byKey(const ValueKey('settle-submit')), findsNothing);
    });

    testWidgets('money in no carrier\'s hands has no fee box', (tester) async {
      // Arrange
      await open(
        tester,
        payments: [
          payment(canSettle: true, account: const PaymentAccountRef(id: 4, name: 'مصرف علي', kind: 'bank')),
        ],
        onSubmit: (_, _) async => null,
      );

      // Assert
      expect(find.byKey(const ValueKey('settle-fee-1')), findsNothing);
      expect(find.text('تلقائي — المصرف'), findsOneWidget);
    });

    testWidgets('a payment already in its place must be given an account', (tester) async {
      // Arrange
      var asked = false;
      await open(
        tester,
        payments: [payment(canSettle: true, target: null)],
        onSubmit: (_, _) async {
          asked = true;

          return null;
        },
      );

      // Act
      await tester.tap(find.byKey(const ValueKey('settle-submit')));
      await tester.pumpAndSettle();

      // Assert
      expect(asked, isFalse);
      expect(find.text('اختر الحساب الذي وصل إليه المال'), findsOneWidget);
    });

    testWidgets('a refusal keeps the sheet open with the server\'s sentence on the row', (tester) async {
      // Arrange
      await open(
        tester,
        payments: [payment(canSettle: true)],
        onSubmit: (_, _) async => const Failure.server(
          message: 'هذه الدفعة سُوّيت من قبل',
          statusCode: 422,
          fieldErrors: {
            'payments.0.payment_id': ['هذه الدفعة سُوّيت من قبل'],
          },
        ),
      );

      // Act
      await tester.tap(find.byKey(const ValueKey('settle-submit')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const ValueKey('settle-submit')), findsOneWidget);
      expect(find.text('هذه الدفعة سُوّيت من قبل'), findsOneWidget);
    });
  });

  group('the account picker', () {
    const accounts = [
      SettlementAccount(id: 9, name: 'النورس'),
      SettlementAccount(id: 4, name: 'مصرف علي'),
      SettlementAccount(id: 6, name: 'كاش فرع مصراتة'),
    ];

    /// Opens the picker; [onAnswer] receives what it closed with.
    Future<void> open(
      WidgetTester tester, {
      int? selectedId,
      void Function(AccountChoice? answer)? onAnswer,
    }) async {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final answer = await showSettlementAccountPicker(
                  context: context,
                  accounts: accounts,
                  selectedId: selectedId,
                );
                onAnswer?.call(answer);
              },
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('typing narrows the list to the accounts that match', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.enterText(
        find.descendant(
          of: find.byKey(const ValueKey('account-picker-search')),
          matching: find.byType(TextField),
        ),
        'مصرف',
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('مصرف علي'), findsOneWidget);
      expect(find.text('النورس'), findsNothing);
      expect(find.text('كل الحسابات'), findsNothing);
    });

    testWidgets('a tapped account is the answer', (tester) async {
      // Arrange
      AccountChoice? answer;
      await open(tester, onAnswer: (value) => answer = value);

      // Act
      await tester.tap(find.byKey(const ValueKey('account-option-9')));
      await tester.pumpAndSettle();

      // Assert
      expect(answer, (accountId: 9));
    });

    testWidgets('«كل الحسابات» answers with no account, which is not the same as closing', (tester) async {
      // Arrange
      AccountChoice? answer;
      await open(tester, selectedId: 9, onAnswer: (value) => answer = value);

      // Act
      await tester.tap(find.text('كل الحسابات'));
      await tester.pumpAndSettle();

      // Assert
      expect(answer, isNotNull);
      expect(answer?.accountId, isNull);
    });
  });

  group('the page', () {
    late _MockOrderPaymentRepository repository;
    late PaymentSettlementCubit cubit;

    Paginated<OrderPayment> pageOf(List<OrderPayment> items, {String total = '0.00'}) =>
        Paginated<OrderPayment>(
          items: items,
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: items.length),
          extraMeta: {'amount_total': total},
        );

    setUp(() {
      repository = _MockOrderPaymentRepository();
      cubit = PaymentSettlementCubit(
        getQueue: GetPaymentSettlementQueue(repository),
        getAccounts: GetSettlementAccounts(repository),
        settlePayments: SettleOrderPayments(repository),
        unsettlePayment: UnsettleOrderPayment(repository),
        now: () => DateTime(2026, 10, 6, 15),
      );
      when(
        () => repository.settlementQueue(
          page: any(named: 'page'),
          state: any(named: 'state'),
          from: any(named: 'from'),
          to: any(named: 'to'),
          accountId: any(named: 'accountId'),
          search: any(named: 'search'),
        ),
      ).thenAnswer((_) async => Right(pageOf([payment(canSettle: true)], total: '250.00')));
      when(() => repository.settlementAccounts()).thenAnswer(
        (_) async => const Right(
          SettlementAccounts(
            sources: [SettlementAccount(id: 9, name: 'النورس')],
            destinations: [SettlementAccount(id: 2, name: 'المصرف')],
          ),
        ),
      );
    });

    tearDown(() => cubit.close());

    test('it opens on every waiting payment — «الكل», the owner\'s default — with the accounts', () async {
      // Act
      await cubit.start();

      // Assert
      verify(() => repository.settlementQueue(page: 1, state: SettlementState.pending)).called(1);
      expect(cubit.period, SettlementPeriod.all);
      expect(cubit.count, 1);
      expect(cubit.accounts.value?.sources.single.name, 'النورس');
    });

    test('the advanced filter takes an open «إلى» and an account', () async {
      // Arrange
      await cubit.load();

      // Act
      await cubit.applyAdvanced(to: DateTime(2026, 10, 4), accountId: 9);

      // Assert
      verify(
        () => repository.settlementQueue(
          page: 1,
          state: SettlementState.pending,
          to: DateTime(2026, 10, 4),
          accountId: 9,
        ),
      ).called(1);
      expect(cubit.period, SettlementPeriod.custom);
      expect(cubit.hasAdvanced, isTrue);
    });

    test('a chip after the advanced dates forgets them and keeps the account', () async {
      // Arrange
      await cubit.applyAdvanced(from: DateTime(2026, 10, 1), accountId: 9);

      // Act
      await cubit.showPeriod(SettlementPeriod.today);

      // Assert
      verify(
        () => repository.settlementQueue(
          page: 1,
          state: SettlementState.pending,
          from: DateTime(2026, 10, 6),
          to: DateTime(2026, 10, 6),
          accountId: 9,
        ),
      ).called(1);
      expect(cubit.customRange, isNull);
      expect(cubit.hasAdvanced, isTrue);
    });

    test('«هذا الأسبوع» asks from Saturday to today', () async {
      // Arrange
      await cubit.load();

      // Act
      await cubit.showPeriod(SettlementPeriod.thisWeek);

      // Assert
      verify(
        () => repository.settlementQueue(
          page: 1,
          state: SettlementState.pending,
          from: DateTime(2026, 10, 3),
          to: DateTime(2026, 10, 6),
        ),
      ).called(1);
    });

    test('the settled tab\'s own Cubit asks for the settled list, and an account narrows it', () async {
      // Arrange — each tab of the page owns a Cubit fixed to its list
      final settled = PaymentSettlementCubit(
        getQueue: GetPaymentSettlementQueue(repository),
        getAccounts: GetSettlementAccounts(repository),
        settlePayments: SettleOrderPayments(repository),
        unsettlePayment: UnsettleOrderPayment(repository),
        tab: SettlementState.settled,
        now: () => DateTime(2026, 10, 6, 15),
      );
      addTearDown(settled.close);
      await settled.load();

      // Act
      await settled.applyAdvanced(accountId: 9);

      // Assert
      verify(() => repository.settlementQueue(page: 1, state: SettlementState.settled)).called(1);
      verify(
        () => repository.settlementQueue(page: 1, state: SettlementState.settled, accountId: 9),
      ).called(1);
    });

    test('settling re-reads the list; a refusal is handed back untouched', () async {
      // Arrange
      await cubit.load();
      when(() => repository.settle(any(), accountId: any(named: 'accountId'))).thenAnswer(
        (_) async => Right([payment()]),
      );

      // Act
      final ok = await cubit.settle(const [SettleRow(paymentId: 1, fee: '١٥')], accountId: 2);

      // Assert
      expect(ok, isNull);
      final sent = verify(() => repository.settle(captureAny(), accountId: 2)).captured.single
          as List<SettleRow>;
      expect(sent.single.fee, '15');
      verify(() => repository.settlementQueue(page: 1, state: SettlementState.pending)).called(2);
    });

    test('an undo goes to the payment\'s own order, with the reason', () async {
      // Arrange
      await cubit.load();
      when(() => repository.unsettle(7, 1, reason: 'خطأ')).thenAnswer(
        (_) async => const Left(Failure.server(message: 'الطلبية «تم التسوية»', statusCode: 422)),
      );

      // Act
      final failure = await cubit.unsettle(payment(), reason: ' خطأ ');

      // Assert
      expect(failure?.message, 'الطلبية «تم التسوية»');
    });
  });
}
