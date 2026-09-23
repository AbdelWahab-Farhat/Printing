import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/investment_fund/models/fund_breakdown.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_cash_page.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_goods_out_page.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_profit_owed_page.dart';
import 'package:dayaa/features/investment_fund/presentation/views/fund_shelf_page.dart';
import 'package:dayaa/features/investment_fund/repositories/fund_breakdown_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/fund_breakdown_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما وراء كلِّ بندٍ في لوحة الصندوق — أربعُ شاشاتٍ تُفتح من أرقامها.
///
/// **ما يُثبَّت هنا أن الشاشات لا تجمع ولا تطرح.** المجموعُ الذي فوق كلِّ قائمةٍ رقمُ اللوحة كما
/// قاله الخادم، والصفوفُ تحته كما وصلت: عميلٌ يعيد جمعها يصير تعريفاً ثانياً — ذاك الذي يخالف
/// اللوحةَ يوم تُعكس حركة.
///
/// Arrange - Act - Assert في كلٍّ منها.
class _FakeBreakdown implements FundBreakdownRepository {
  _FakeBreakdown({
    this.cashPage,
    this.shelfHeld,
    this.goodsHeld = const {},
    this.profitHeld,
    this.failure,
  });

  final Paginated<FundCashEntry>? cashPage;
  final FundShelf? shelfHeld;
  final Map<FundGoodsStage, FundGoodsOut> goodsHeld;
  final FundProfitOwed? profitHeld;
  final Failure? failure;

  FundGoodsStage? askedStage;

  Either<Failure, T> _answer<T>(T? value) =>
      failure != null ? Left(failure!) : Right(value as T);

  @override
  Future<Either<Failure, Paginated<FundCashEntry>>> cash({required int page}) async =>
      _answer(cashPage);

  @override
  Future<Either<Failure, FundShelf>> shelf() async => _answer(shelfHeld);

  @override
  Future<Either<Failure, FundGoodsOut>> goodsOut(FundGoodsStage stage) async {
    askedStage = stage;

    return _answer(goodsHeld[stage]);
  }

  @override
  Future<Either<Failure, FundProfitOwed>> profitOwed() async => _answer(profitHeld);
}

const _meta = PageMeta(currentPage: 1, perPage: 30, lastPage: 1, total: 2);

final _cash = Paginated<FundCashEntry>(
  items: [
    FundCashEntry(
      id: 3,
      type: 'sale_proceeds',
      typeLabel: 'تحصيل مبيعات',
      isInflow: true,
      signedAmount: '800.00',
      balanceAfter: '2800.00',
      occurredAt: DateTime(2026, 9, 23, 10),
      description: 'طلبية ORD-12 · محمد الساعدي',
      orderId: 12,
    ),
    FundCashEntry(
      id: 2,
      type: 'purchase',
      typeLabel: 'شراء بضاعة',
      isInflow: false,
      signedAmount: '-3000.00',
      balanceAfter: '2000.00',
      occurredAt: DateTime(2026, 9, 21, 10),
      description: 'أمر شراء #4 · مصنع الأكياس',
      purchaseOrderId: 4,
    ),
  ],
  meta: _meta,
  extraMeta: const {'current_page': 1, 'balance': '2800.00'},
);

const _bags = FundGoodsLine(
  stockItemId: 5,
  name: 'كيس 30×40',
  unitLabel: 'قطعة',
  quantity: '30.000',
  cost: '300.00',
);

void main() {
  Future<_FakeBreakdown> register(_FakeBreakdown repository) async {
    await sl.reset();
    sl
      ..registerSingleton<Session>(Session())
      ..registerLazySingleton<GetFundCash>(() => GetFundCash(repository))
      ..registerLazySingleton<GetFundShelf>(() => GetFundShelf(repository))
      ..registerLazySingleton<GetFundGoodsOut>(() => GetFundGoodsOut(repository))
      ..registerLazySingleton<GetFundProfitOwed>(() => GetFundProfitOwed(repository));

    return repository;
  }

  Widget host(Widget page) {
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
        home: Directionality(textDirection: TextDirection.rtl, child: page),
      ),
    );
  }

  group('سجل الخزينة', () {
    testWidgets('opens on the treasury balance the dashboard showed', (tester) async {
      // Arrange — الرصيدُ من الخادم، لا جمعُ صفوف الصفحة الأولى.
      await register(_FakeBreakdown(cashPage: _cash));

      // Act
      await tester.pumpWidget(host(const FundCashPage()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('نقد في الخزينة'), findsOneWidget);
      expect(find.text('2,800 د.ل'), findsOneWidget);
    });

    testWidgets('says where each dinar came from, with its sign and what was left', (tester) async {
      // Arrange
      await register(_FakeBreakdown(cashPage: _cash));

      // Act
      await tester.pumpWidget(host(const FundCashPage()));
      await tester.pumpAndSettle();

      // Assert — الداخلُ بزائد والخارجُ بناقص، وتحت كلٍّ ما بقي في الخزينة بعده.
      expect(find.text('تحصيل مبيعات'), findsOneWidget);
      expect(find.text('طلبية ORD-12 · محمد الساعدي'), findsOneWidget);
      expect(find.text('+800 د.ل'), findsOneWidget);
      expect(find.text('الرصيد 2,800 د.ل'), findsOneWidget);
      expect(find.text('شراء بضاعة'), findsOneWidget);
      expect(find.text('أمر شراء #4 · مصنع الأكياس'), findsOneWidget);
      expect(find.text('−3,000 د.ل'), findsOneWidget);
      expect(find.text('الرصيد 2,000 د.ل'), findsOneWidget);
    });
  });

  group('بضاعة على الرفّ', () {
    testWidgets('lists each material with its quantity and what it cost', (tester) async {
      // Arrange
      await register(
        _FakeBreakdown(
          shelfHeld: const FundShelf(
            total: '6200.00',
            materials: [
              FundShelfMaterial(
                stockItemId: 5,
                code: 'B30',
                name: 'كيس 30×40',
                unitLabel: 'قطعة',
                quantity: '500.000',
                value: '5200.00',
                batches: 2,
              ),
              FundShelfMaterial(
                stockItemId: 6,
                name: 'رول نايلون',
                unitLabel: 'كجم',
                quantity: '50.000',
                value: '1000.00',
                batches: 1,
              ),
            ],
          ),
        ),
      );

      // Act
      await tester.pumpWidget(host(const FundShelfPage()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('6,200 د.ل'), findsOneWidget);
      expect(find.text('كيس 30×40'), findsOneWidget);
      expect(find.text('B30'), findsOneWidget);
      expect(find.text('500 قطعة'), findsOneWidget);
      expect(find.text('5,200 د.ل'), findsOneWidget);
      expect(find.text('رول نايلون'), findsOneWidget);
      expect(find.text('50 كجم'), findsOneWidget);
      expect(find.text('1,000 د.ل'), findsOneWidget);
    });

    testWidgets('an empty shelf says so instead of drawing a blank list', (tester) async {
      // Arrange
      await register(_FakeBreakdown(shelfHeld: const FundShelf(total: '0.00')));

      // Act
      await tester.pumpWidget(host(const FundShelfPage()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('لا بضاعة للصندوق على الرفّ'), findsOneWidget);
    });

    testWidgets('a failed read shows the server’s reason and a way to try again', (tester) async {
      // Arrange
      await register(_FakeBreakdown(failure: const Failure.server(message: 'انقطع الاتصال')));

      // Act
      await tester.pumpWidget(host(const FundShelfPage()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('انقطع الاتصال'), findsOneWidget);
      expect(find.text('إعادة المحاولة'), findsOneWidget);
    });
  });

  group('البضاعة الخارجة', () {
    testWidgets('goods in flight are listed by order with the goods each one took', (tester) async {
      // Arrange
      final repository = await register(
        _FakeBreakdown(
          goodsHeld: {
            FundGoodsStage.inFlight: FundGoodsOut(
              total: '300.00',
              orders: [
                FundGoodsOrder(
                  orderId: 12,
                  code: 'ORD-12',
                  status: 'out_for_delivery',
                  statusLabel: 'جاري التوصيل',
                  customerName: 'محمد الساعدي',
                  placedAt: DateTime(2026, 9, 21, 10),
                  grandTotal: '600.00',
                  paidAmount: '0.00',
                  remaining: '600.00',
                  cost: '300.00',
                  goods: const [_bags],
                ),
              ],
            ),
          },
        ),
      );

      // Act
      await tester.pumpWidget(host(const FundGoodsOutPage(stage: FundGoodsStage.inFlight)));
      await tester.pumpAndSettle();

      // Assert — العنوانُ عنوانُ البند في اللوحة، والمجموعُ رقمُه.
      expect(repository.askedStage, FundGoodsStage.inFlight);
      expect(find.text('بضاعة خرجت ولم تُسلَّم'), findsWidgets);
      expect(find.text('طلبية ORD-12'), findsOneWidget);
      expect(find.text('جاري التوصيل'), findsOneWidget);
      expect(find.text('كيس 30×40'), findsOneWidget);
      expect(find.text('30 قطعة'), findsOneWidget);
      expect(find.text('300 د.ل'), findsWidgets);
      expect(find.text('المتبقي على العميل'), findsNothing);
    });

    testWidgets('uncollected goods say what the customer still owes', (tester) async {
      // Arrange
      await register(
        _FakeBreakdown(
          goodsHeld: {
            FundGoodsStage.uncollected: FundGoodsOut(
              total: '200.00',
              orders: [
                FundGoodsOrder(
                  orderId: 9,
                  code: 'ORD-9',
                  status: 'delivered',
                  statusLabel: 'تم الاستلام',
                  deliveredAt: DateTime(2026, 9, 20, 10),
                  grandTotal: '500.00',
                  paidAmount: '100.00',
                  remaining: '400.00',
                  cost: '200.00',
                  goods: const [_bags],
                ),
              ],
            ),
          },
        ),
      );

      // Act
      await tester.pumpWidget(host(const FundGoodsOutPage(stage: FundGoodsStage.uncollected)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('سُلِّمت ولم تُحصَّل'), findsWidgets);
      expect(find.text('طلبية ORD-9'), findsOneWidget);
      expect(find.text('المتبقي على العميل'), findsOneWidget);
      expect(find.text('400 د.ل'), findsOneWidget);
    });

    testWidgets('nothing out there says so', (tester) async {
      // Arrange
      await register(
        _FakeBreakdown(goodsHeld: {FundGoodsStage.inFlight: const FundGoodsOut(total: '0.00')}),
      );

      // Act
      await tester.pumpWidget(host(const FundGoodsOutPage(stage: FundGoodsStage.inFlight)));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('لا طلبيات تحمل بضاعة الصندوق هنا'), findsOneWidget);
    });
  });

  group('الأرباح المستحقّة', () {
    testWidgets('splits what waits in wallets from what waits on its orders', (tester) async {
      // Arrange
      await register(
        _FakeBreakdown(
          profitHeld: const FundProfitOwed(
            total: '140.00',
            inWallets: FundWalletProfit(
              total: '50.00',
              investors: [PeriodInvestorShare(investorId: 1, name: 'عبدالرحمن', amount: '50.00')],
            ),
            unreleased: FundUnreleasedProfit(
              total: '90.00',
              orders: [
                PeriodOrder(
                  orderId: 12,
                  code: 'ORD-12',
                  status: 'delivered',
                  statusLabel: 'تم الاستلام',
                  grandTotal: '600.00',
                  investorsTotal: '100.00',
                  investors: [
                    PeriodInvestorShare(investorId: 2, name: 'أحمد', amount: '60.00'),
                    PeriodInvestorShare(investorId: 3, name: 'عمر', amount: '40.00'),
                  ],
                ),
              ],
              adjustments: [
                FundProfitAdjustment(kind: 'expense', label: 'مصروف: أجرة شاحنة', amount: '-10.00'),
              ],
            ),
          ),
        ),
      );

      // Act
      await tester.pumpWidget(host(const FundProfitOwedPage()));
      await tester.pumpAndSettle();

      // Assert — المجموعُ فوق، ثم نصفاه كلٌّ بمجموعه، ثم ما تحته.
      expect(find.text('140 د.ل'), findsOneWidget);
      expect(find.text('أُفرج عنها ولم تُسحب'), findsOneWidget);
      expect(find.text('عبدالرحمن'), findsOneWidget);
      expect(find.text('50 د.ل'), findsNWidgets(2));
      expect(find.text('لم يُفرج عنها بعد'), findsOneWidget);
      expect(find.text('90 د.ل'), findsOneWidget);
      expect(find.text('طلبية ORD-12'), findsOneWidget);
      expect(find.text('أحمد'), findsOneWidget);
      expect(find.text('60 د.ل'), findsOneWidget);
      expect(find.text('مصروف: أجرة شاحنة'), findsOneWidget);
      expect(find.text('-10 د.ل'), findsOneWidget);
    });

    testWidgets('nothing owed says so', (tester) async {
      // Arrange
      await register(_FakeBreakdown(profitHeld: const FundProfitOwed(total: '0.00')));

      // Act
      await tester.pumpWidget(host(const FundProfitOwedPage()));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('لا أرباح مستحقّة الآن'), findsOneWidget);
    });
  });
}
