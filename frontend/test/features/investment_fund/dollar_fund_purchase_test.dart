import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_fund/models/fund_standing.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_purchase_page.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Funding a dollar purchase order from the fund — USD-ACCOUNTS.md §٥, the owner's decision of
/// 2026-11-10: the screen asks a rate, «سعر النظام» unless changed, and the fund pays in dinars at
/// it. A difference from the arrival rate is said on the order, never booked.
///
/// Arrange - Act - Assert throughout.
class _MockFundRepository extends Mock implements InvestmentFundRepository {}

/// A dollar order: 500 kg of bags for $1,000, maybe already funded at [fundingRate].
PurchaseOrder _order({String? fundingRate, String? systemRate = '7.0000'}) =>
    PurchaseOrder.fromJson({
      'id': 12,
      'vendor_id': 3,
      'status': 'new',
      'status_label': 'جديد',
      'order_date': '2026-11-10',
      'currency': 'USD',
      'system_usd_rate': ?systemRate,
      'funding_rate': ?fundingRate,
      'items': [
        {
          'id': 1,
          'stock_item_id': 4,
          'quantity_ordered': '500.000',
          'quantity_received': '0.000',
          'quantity_remaining': '500.000',
          'base_total_cost': '1000.00',
          'final_total_cost': '1000.00',
          'unit': 'piece',
          'unit_label': 'قطعة',
        },
      ],
    });

void main() {
  late _MockFundRepository fund;

  setUp(() async {
    await Injector.reset();
    fund = _MockFundRepository();

    when(() => fund.standing()).thenAnswer(
      (_) async => const Right(
        FundStanding(
          valuation: FundValuation(
            cash: '20000.00',
            stockOnShelf: '0.00',
            goodsInFlight: '0.00',
            receivablesAtCost: '0.00',
            profitOwed: '0.00',
            total: '20000.00',
          ),
        ),
      ),
    );
    when(
      () => fund.buyPurchaseOrder(
        purchaseOrderId: any(named: 'purchaseOrderId'),
        stockItemIds: any(named: 'stockItemIds'),
        printingSalePrices: any(named: 'printingSalePrices'),
        rate: any(named: 'rate'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    sl
      ..registerLazySingleton<GetFundStanding>(() => GetFundStanding(fund))
      ..registerLazySingleton<BuyWithFund>(() => BuyWithFund(fund));
  });

  tearDown(Injector.reset);

  Widget host(PurchaseOrder order) => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => MaterialApp(
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: FundPurchasePage(order: order),
    ),
  );

  Finder rateField() => find.descendant(
    of: find.byKey(const ValueKey('funding-rate')),
    matching: find.byType(EditableText),
  );

  /// The button, not the app bar's title of the same words. Pumped short of the toast's three
  /// seconds so what it says can be read; [settle] lets it go.
  Future<void> buy(WidgetTester tester, {bool settle = true}) async {
    final button = find.widgetWithText(AppButton, 'شراء بمال الصندوق');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump(const Duration(milliseconds: 500));

    if (settle) {
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    }
  }

  testWidgets('the rate opens on the system rate, and the cost is dinars at it', (tester) async {
    // Act
    await tester.pumpWidget(host(_order()));
    await tester.pumpAndSettle();

    // Assert — $1,000 at 7.
    expect(tester.widget<EditableText>(rateField()).controller.text, '7');
    expect(find.text('7,000 د.ل'), findsWidgets);
  });

  testWidgets('a changed rate changes the cost, and goes with the purchase', (tester) async {
    // Arrange
    await tester.pumpWidget(host(_order()));
    await tester.pumpAndSettle();

    // Act
    await tester.enterText(rateField(), '7.2');
    await tester.pump();
    expect(find.text('7,200 د.ل'), findsWidgets);
    await buy(tester);

    // Assert
    verify(
      () => fund.buyPurchaseOrder(
        purchaseOrderId: 12,
        stockItemIds: [4],
        printingSalePrices: any(named: 'printingSalePrices'),
        rate: '7.2',
      ),
    ).called(1);
  });

  testWidgets('with no system rate nothing is bought until one is written', (tester) async {
    // Arrange
    await tester.pumpWidget(host(_order(systemRate: null)));
    await tester.pumpAndSettle();

    // Act
    await buy(tester, settle: false);

    // Assert
    expect(find.text('اكتب سعر الصرف الذي يشتري به الصندوق'), findsOneWidget);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    verifyNever(
      () => fund.buyPurchaseOrder(
        purchaseOrderId: any(named: 'purchaseOrderId'),
        stockItemIds: any(named: 'stockItemIds'),
        printingSalePrices: any(named: 'printingSalePrices'),
        rate: any(named: 'rate'),
      ),
    );
  });

  testWidgets('an order funded before keeps its rate, shown and not sent', (tester) async {
    // Arrange — read before buying: a purchase closes the screen.
    await tester.pumpWidget(host(_order(fundingRate: '6.9000')));
    await tester.pumpAndSettle();
    final shown = tester.widget<EditableText>(rateField()).controller.text;
    final open = tester.widget<AppTextField>(find.byKey(const ValueKey('funding-rate'))).enabled;

    // Act
    await buy(tester);

    // Assert
    expect(shown, '6.9');
    expect(open, isFalse);
    verify(
      () => fund.buyPurchaseOrder(
        purchaseOrderId: 12,
        stockItemIds: [4],
        printingSalePrices: any(named: 'printingSalePrices'),
        rate: null,
      ),
    ).called(1);
  });

  test('the order reads the funding rate and the difference the server says', () {
    // Act
    final order = PurchaseOrder.fromJson({
      ..._order().toJson(),
      'funding_rate': '7.0000',
      'arrival_rate': '7.5000',
      'rate_difference': {
        'funding_rate': '7.0000',
        'arrival_rate': '7.5000',
        'per_dollar': '0.5000',
        'direction': 'higher',
        'funded_dollars': '1000.00',
        'dinars': '500.00',
      },
    });

    // Assert
    expect(order.fundingRate, '7.0000');
    expect(order.rateDifference?.isHigher, isTrue);
    expect(order.rateDifference?.dinars, '500.00');
  });
}
