import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/save_purchase_order_cubit.dart';
import 'package:dayaa/features/purchase_orders/presentation/views/purchase_order_form_page.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/additional_cost_row.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/receive_arrival_sheet.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository_impl.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Dollar purchase orders and the vendor's dollar «علينا» in the app — USD-ACCOUNTS.md §٤,
/// phase 2.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.answer);

  final Object? answer;
  Object? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final bytes = (await requestStream.toList()).expand((chunk) => chunk).toList();
      body = jsonDecode(utf8.decode(bytes));
    }

    return ResponseBody.fromString(
      jsonEncode({'status': true, 'message': 'تم', 'data': answer}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _MockPurchaseOrderRepository extends Mock implements PurchaseOrderRepository {}

class _MockFundRepository extends Mock implements InvestmentFundRepository {}

/// What the server sends for an order, in `currency`.
Map<String, dynamic> _orderJson({String? currency}) => {
  'id': 12,
  'vendor_id': 3,
  'status': 'new',
  'status_label': 'جديد',
  'order_date': '2026-11-09',
  'currency': ?currency,
  'total_amount': '1500.00',
  'vendor_amount': '1500.00',
};

void main() {
  group('what the server sends', () {
    test('an order says its currency, and an older server\'s is dinars', () {
      // Act
      final dollars = PurchaseOrder.fromJson(_orderJson(currency: 'USD'));
      final older = PurchaseOrder.fromJson(_orderJson());

      // Assert
      expect(dollars.currency, Currency.usd);
      expect(dollars.isDollar, isTrue);
      expect(older.currency, Currency.lyd);
      expect(older.isDollar, isFalse);
    });

    test('an order\'s payments are in its currency', () {
      // Act
      final payments = PurchaseOrderPayments.fromJson({
        'summary': {'currency': 'USD', 'total': '1500.00', 'paid': '0.00', 'remaining': '1500.00'},
        'payments': <Object>[],
      });

      // Assert
      expect(payments.currency, Currency.usd);
      expect(payments.isDollar, isTrue);
      // And it stays so once a row moves its figures.
      expect(
        payments
            .withPayment(
              const VendorPayment(
                id: 1,
                type: 'credit',
                typeLabel: 'خصم',
                amount: '100.00',
                isReversed: false,
                isReversible: true,
              ),
            )
            .currency,
        Currency.usd,
      );
    });

    test('a vendor owed dollars has a dollar side apart from the dinars', () {
      // Act
      final account = VendorAccount.fromJson({
        'summary': {'ordered': '7000.00', 'owed': '7000.00', 'paid': '0.00'},
        'treasury_account_id': 30,
        'usd_summary': {'ordered': '1500.00', 'owed': '1500.00'},
        'usd_treasury_account_id': 31,
        'payments': <Object>[],
      });

      // Assert
      expect(account.owed, '7000.00');
      expect(account.dollarsOwed, '1500.00');
      expect(account.dollarTreasuryAccountId, 31);
      expect(account.hasDollars, isTrue);
    });

    test('a vendor with no dollar order has no dollar side', () {
      // Act
      final account = VendorAccount.fromJson({
        'summary': {'owed': '7000.00'},
        'treasury_account_id': 30,
        'payments': <Object>[],
      });

      // Assert
      expect(account.hasDollars, isFalse);
      expect(account.dollarsOwed, '0.00');
    });

    test('what is owed in dollars rides beside «علينا» on both dashboard tabs', () {
      // Act
      final accounts = TreasuryAccounts.fromJson({
        'accounts': <Object>[],
        'total': '0.00',
        'payables_total': '1700.00',
        'usd_payables_total': '100.00',
        'usd_payables_total_in_lyd': '700.00',
        'usd_rate': '7.0000',
      });
      final ownership = TreasuryOwnership.fromJson({
        'total_held': '0.00',
        'investors': <Object>[],
        'investors_total': '0.00',
        'fund_cash': '0.00',
        'company_own': '-1700.00',
        'payables_total': '1700.00',
        'usd_payables': '100.00',
        'usd_payables_in_lyd': '700.00',
        'usd_rate': '7.0000',
      });

      // Assert
      expect(accounts.owedDollars.held, '100.00');
      expect(accounts.owedDollars.inLyd, '700.00');
      expect(ownership.owedDollars.held, '100.00');
      expect(ownership.owedDollars.inLyd, '700.00');
      expect(accounts.withAccounts(const []).owedDollars.held, '100.00');
    });
  });

  group('how it is written', () {
    test('a dollar debt says «علينا» in dollars, held left to right', () {
      // Act
      final label = owedLabel('1500.00', currency: Currency.usd);

      // Assert
      expect(label, 'علينا ${String.fromCharCode(0x2066)}\$1,500${String.fromCharCode(0x2069)}');
    });

    test('a vendor\'s dollar payable is said in dollars on its tile', () {
      // Arrange
      const payable = TreasuryAccount(
        id: 31,
        name: 'مصنع شنغهاي (دولار)',
        kind: AccountKind.payable,
        kindLabel: 'علينا',
        isDefault: false,
        isActive: true,
        isSystem: false,
        isSpendable: false,
        balance: '-1500.00',
        currency: Currency.usd,
      );

      // Act
      final label = treasuryBalanceLabel(payable);

      // Assert
      expect(label, contains('\$1,500'));
      expect(label, isNot(contains('د.ل')));
    });

    test('a figure already formatted takes its currency', () {
      // Assert
      expect(withCurrency('1,250', Currency.lyd), '1,250 د.ل');
      expect(
        withCurrency('1,250', Currency.usd),
        '${String.fromCharCode(0x2066)}\$1,250${String.fromCharCode(0x2069)}',
      );
    });
  });

  group('what the app puts on the wire', () {
    PurchaseOrderRepositoryImpl repositoryOver(_CapturingAdapter adapter) =>
        PurchaseOrderRepositoryImpl(
          Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
        );

    const line = PurchaseOrderLine(stockItemId: 4, quantity: '10', baseTotalCost: '1500');

    test('a new dollar order says its currency', () async {
      // Arrange
      final adapter = _CapturingAdapter(_orderJson(currency: 'USD'));

      // Act
      final result = await repositoryOver(adapter).create(
        vendorId: 3,
        warehouseId: 1,
        orderDate: '2026-11-09',
        items: const [line],
        currency: Currency.usd,
      );

      // Assert
      expect((adapter.body as Map)['currency'], 'USD');
      expect(result.getOrElse(() => throw StateError('failed')).isDollar, isTrue);
    });

    test('a dinar order sends no currency, as it always has', () async {
      // Arrange
      final adapter = _CapturingAdapter(_orderJson(currency: 'LYD'));

      // Act
      await repositoryOver(
        adapter,
      ).create(vendorId: 3, warehouseId: 1, orderDate: '2026-11-09', items: const [line]);

      // Assert
      expect((adapter.body as Map).containsKey('currency'), isFalse);
    });

    test('an edit never sends a currency', () async {
      // Arrange
      final adapter = _CapturingAdapter(_orderJson(currency: 'USD'));

      // Act
      await repositoryOver(
        adapter,
      ).update(12, vendorId: 3, warehouseId: 1, orderDate: '2026-11-09', items: const [line]);

      // Assert
      expect((adapter.body as Map).containsKey('currency'), isFalse);
    });
  });

  group('the form', () {
    late Session session;

    Widget host(Widget child) => ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(textDirection: TextDirection.rtl, child: child),
      ),
    );

    Future<void> register(List<String> permissions) async {
      await Injector.reset();
      session = Session()
        ..adopt(AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions));
      final fund = _MockFundRepository();

      sl
        ..registerSingleton<Session>(session)
        ..registerLazySingleton<GetFundStanding>(() => GetFundStanding(fund))
        ..registerFactory<SavePurchaseOrderCubit>(
          () => SavePurchaseOrderCubit(
            saveOrder: SavePurchaseOrder(_MockPurchaseOrderRepository()),
            buyWithFund: BuyWithFund(fund),
          ),
        );
    }

    tearDown(Injector.reset);

    testWidgets('a new order offers dinars and dollars, dinars first', (tester) async {
      // Arrange
      await register(['purchase_orders.manage']);

      // Act
      await tester.pumpWidget(host(const PurchaseOrderFormPage()));
      await tester.pumpAndSettle();

      // Assert
      final picker = tester.widget<SegmentedButton<Currency>>(
        find.byKey(const ValueKey('order-currency')),
      );
      expect(picker.selected, {Currency.lyd});
    });

    testWidgets('dollars drop the fund\'s row and say what waits', (tester) async {
      // Arrange — somebody who could fund the order in dinars.
      await register(['purchase_orders.manage', 'investors.manage']);
      await tester.pumpWidget(host(const PurchaseOrderFormPage()));
      await tester.pumpAndSettle();
      expect(find.text('يشتريه الصندوق بماله'), findsOneWidget);

      // Act
      await tester.tap(find.text('دولار'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('يشتريه الصندوق بماله'), findsNothing);
      expect(find.textContaining('على «علينا» الدولاري للمورد'), findsOneWidget);
    });

    testWidgets('an existing dollar order shows its currency, locked', (tester) async {
      // Arrange
      await register(['purchase_orders.manage']);

      // Act
      await tester.pumpWidget(
        host(PurchaseOrderFormPage(order: PurchaseOrder.fromJson(_orderJson(currency: 'USD')))),
      );
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const ValueKey('order-currency')), findsNothing);
      expect(find.text('العملة لا تتغيّر بعد إنشاء الأمر'), findsOneWidget);
    });

    Future<void> pumpRow(WidgetTester tester, AdditionalCostDraft cost) async {
      await tester.pumpWidget(
        host(
          Scaffold(
            body: AdditionalCostRow(cost: cost, onRemove: () {}, currency: Currency.usd),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a dollar order\'s cost on the vendor\'s bill is typed in dollars', (tester) async {
      // Arrange — somebody who names no drawer.
      await register(['purchase_orders.manage']);
      final cost = AdditionalCostDraft(name: 'شحن من الصين', amount: '200');
      addTearDown(cost.dispose);

      // Act
      await pumpRow(tester, cost);

      // Assert
      expect(find.text(r'القيمة ($)'), findsOneWidget);
      expect(find.byKey(const ValueKey('dollar-cost-on-bill')), findsOneWidget);
    });

    testWidgets('a dollar order\'s cost from a drawer is typed in the drawer\'s dinars', (
      tester,
    ) async {
      // Arrange — customs in Libya, out of a dinar drawer.
      await register(['purchase_orders.manage', 'treasury.record']);
      final cost = AdditionalCostDraft(name: 'جمارك', amount: '350', treasuryAccountId: 5);
      addTearDown(cost.dispose);

      // Act
      await pumpRow(tester, cost);

      // Assert
      expect(find.text('القيمة (د.ل)'), findsOneWidget);
      expect(find.byKey(const ValueKey('dollar-cost-on-bill')), findsNothing);
    });

    testWidgets('and out of a dollar drawer, in dollars', (tester) async {
      // Arrange — shipping from China, out of the dollar box (USD-ACCOUNTS §٧, phase 5).
      await register(['purchase_orders.manage', 'treasury.record']);
      final cost = AdditionalCostDraft(
        name: 'شحن',
        amount: '100',
        treasuryAccountId: 21,
        accountCurrency: Currency.usd,
      );
      addTearDown(cost.dispose);

      // Act
      await pumpRow(tester, cost);

      // Assert
      expect(find.text(r'القيمة ($)'), findsOneWidget);
    });

    test('a saved cost from a drawer remembers the drawer\'s currency', () {
      // Act
      final draft = AdditionalCostDraft.of(
        const PurchaseOrderAdditionalCost(
          id: 4,
          name: 'شحن',
          amount: '100.00',
          currencyCode: 'USD',
          treasuryAccountId: 21,
        ),
      );
      addTearDown(draft.dispose);

      // Assert
      expect(draft.accountCurrency, Currency.usd);
    });
  });

  group('receiving a dollar order', () {
    Widget host(Future<void> Function(BuildContext context) open) => ScreenUtilInit(
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
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(onPressed: () => open(context), child: const Text('افتح')),
            ),
          ),
        ),
      ),
    );

    PurchaseOrder order({String currency = 'USD', String? systemRate}) => PurchaseOrder.fromJson({
      ..._orderJson(currency: currency),
      'system_usd_rate': ?systemRate,
      'items': [
        {
          'id': 1,
          'stock_item_id': 4,
          'quantity_ordered': '10.000',
          'quantity_received': '0.000',
          'quantity_remaining': '10.000',
          'base_total_cost': '1500.00',
          'unit': 'piece',
          'unit_label': 'قطعة',
        },
      ],
    });

    Future<ReceivedShipment?> fillAndSend(WidgetTester tester, PurchaseOrder order) async {
      ReceivedShipment? shipment;
      await tester.pumpWidget(
        host(
          (context) async =>
              shipment = await showReceiveArrivalSheet(context: context, order: order),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(AppTextField).at(order.isDollar ? 1 : 0),
          matching: find.byType(EditableText),
        ),
        '10',
      );
      await tester.tap(find.text('تسجيل الشحنة'));
      await tester.pumpAndSettle();

      return shipment;
    }

    Finder rateField() => find.descendant(
      of: find.byKey(const ValueKey('arrival-rate')),
      matching: find.byType(EditableText),
    );

    testWidgets('the rate opens on the system rate and goes with the shipment', (tester) async {
      // Act
      final shipment = await fillAndSend(tester, order(systemRate: '7.1500'));

      // Assert
      expect(shipment?.arrivalRate, '7.15');
    });

    testWidgets('with no system rate the field opens empty and must be filled', (tester) async {
      // Act
      final shipment = await fillAndSend(tester, order());

      // Assert — the sheet stays open, asking.
      expect(shipment, isNull);
      expect(find.text('اكتب سعر الصرف'), findsOneWidget);
      expect(tester.widget<EditableText>(rateField()).controller.text, isEmpty);
    });

    testWidgets('a dinar order asks no rate', (tester) async {
      // Act
      final shipment = await fillAndSend(tester, order(currency: 'LYD'));

      // Assert
      expect(find.byKey(const ValueKey('arrival-rate')), findsNothing);
      expect(shipment?.arrivalRate, isNull);
      expect(shipment?.quantities, {4: '10'});
    });
  });

  group('what phase 4 reads and sends', () {
    test('an order says its arrival rate and the system rate; a cost says its currency', () {
      // Act
      final received = PurchaseOrder.fromJson({
        ..._orderJson(currency: 'USD'),
        'arrival_rate': '7.0000',
        'system_usd_rate': '7.1500',
        'additional_costs': [
          {
            'id': 1,
            'name': 'جمارك',
            'amount': '350.00',
            'currency': 'LYD',
            'treasury_account_id': 2,
          },
          {'id': 2, 'name': 'شحن', 'amount': '200.00', 'currency': 'USD'},
        ],
      });

      // Assert
      expect(received.arrivalRate, '7.0000');
      expect(received.systemUsdRate, '7.1500');
      expect(received.additionalCosts.map((cost) => cost.currency), [Currency.lyd, Currency.usd]);
    });

    test('the receipt sends the rate on a dollar order, and nothing on a dinar one', () async {
      // Arrange
      final dollars = _CapturingAdapter(<String, Object?>{'id': 1});
      final dinars = _CapturingAdapter(<String, Object?>{'id': 2});
      PurchaseOrderRepositoryImpl over(_CapturingAdapter adapter) => PurchaseOrderRepositoryImpl(
        Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
      );
      const line = ReceivedLine(stockItemId: 4, quantity: '10');

      // Act
      await over(dollars).receiveArrival(12, items: const [line], arrivalRate: '7.15');
      await over(dinars).receiveArrival(12, items: const [line]);

      // Assert
      expect((dollars.body as Map)['arrival_rate'], '7.15');
      expect((dinars.body as Map).containsKey('arrival_rate'), isFalse);
    });
  });
}
