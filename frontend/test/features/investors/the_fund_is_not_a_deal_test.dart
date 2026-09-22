import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/investors/models/investor_deal.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/deal_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/deal_detail_page.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/viewmodel/purchase_order_detail_cubit.dart';
import 'package:dayaa/features/purchase_orders/presentation/views/purchase_order_detail_page.dart';
import 'package:dayaa/features/purchase_orders/repositories/purchase_order_repository.dart';
import 'package:dayaa/features/purchase_orders/usecases/purchase_order_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// الصندوقُ صفٌّ في جدول الصفقات، ولا يجوز أن يكون صفقةً على الشاشة.
///
/// **وقع الضررُ فعلاً**: أُغلق صندوقُ سيرفر التجربة من شاشة الصفقة في ٢٢ سبتمبر ٢٠٢٦، فعادت
/// ١٧٬٠٠٠ من رأس مال ثلاثة مستثمرين إلى محافظهم ووحداتُهم قائمة. والخادمُ صار يرفض الضغطة —
/// وما يُثبَّت هنا أن الشاشة لا تَعِد بها أصلاً، وأن آخرَ بابٍ إليها لم يعد يفتحها.
///
/// Arrange - Act - Assert في كلٍّ منها.
class _MockInvestorRepository extends Mock implements InvestorRepository {}

class _MockPurchaseOrderRepository extends Mock implements PurchaseOrderRepository {}

void main() {
  /// الصندوقُ كما يصل من الخادم: مفتوحٌ أبداً، و`isFund` هي ما يفرّقه عن دفعةِ شراء.
  InvestorDeal fund() => const InvestorDeal(
    id: 1,
    code: 'FUND',
    status: 'open',
    statusLabel: 'مفتوحة',
    isFund: true,
    investorProfitSharePercent: '50.00',
    balances: DealBalances(capital: '17000.00', profit: '-250.00'),
  );

  /// دفعةُ شراءٍ حقيقية — تُغلق، والزرُّ حقُّها.
  InvestorDeal lot() => const InvestorDeal(
    id: 2,
    code: 'D2',
    status: 'open',
    statusLabel: 'مفتوحة',
    investorProfitSharePercent: '50.00',
    balances: DealBalances(capital: '30000.00', profit: '1500.00'),
  );

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

  Future<_MockInvestorRepository> registerDeal(InvestorDeal deal) async {
    await Injector.reset();
    final repository = _MockInvestorRepository();

    sl
      ..registerSingleton<Session>(Session())
      ..registerFactory<DealDetailCubit>(
        () => DealDetailCubit(
          getDeal: GetInvestorDeal(repository),
          changeState: ChangeDealState(repository),
          recordExpense: RecordDealExpense(repository),
        ),
      );

    // صلاحيةٌ كاملة: ما يُخفي الزرَّ يجب أن يكون كونَه صندوقاً، لا نقصَ صلاحية.
    sl<Session>().adopt(
      const AuthUser(
        id: 1,
        name: 'مدير',
        phone: '0910000000',
        permissions: ['investors.manage'],
      ),
    );

    when(() => repository.deal(deal.id)).thenAnswer((_) async => Right(deal));

    return repository;
  }

  tearDown(Injector.reset);

  testWidgets('the fund offers no close button, however it is reached', (tester) async {
    // Arrange — الخادمُ يرفض الإغلاق؛ وزرٌّ يَعِد بما يُرفض أسوأ من غيابه.
    await registerDeal(fund());

    // Act
    await tester.pumpWidget(host(const InvestorDealDetailPage(dealId: 1)));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('إغلاق وتسوية الحسابات'), findsNothing);
  });

  testWidgets('a real purchase lot still offers it', (tester) async {
    // Arrange — الحارسُ على الصندوق وحده، لا على كل صفقة.
    await registerDeal(lot());

    // Act
    await tester.pumpWidget(host(const InvestorDealDetailPage(dealId: 2)));
    await tester.pumpAndSettle();

    // Assert — خلف القرص، فيُفتح أولاً.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    expect(find.text('إغلاق وتسوية الحسابات'), findsOneWidget);
  });

  testWidgets('a lorry the fund bought says so, and opens the fund', (tester) async {
    // Arrange — «تمويل FUND» كان يعرض حالةَ صفقةٍ ويفتح صفحتَها بزرِّ إغلاقها، وهو آخرُ بابٍ
    // بقي إليها. والصندوقُ لا ممولين فيه ولا نسبٌ جُمّدت: السؤالُ الوحيد ما الذي اشتراه.
    await Injector.reset();
    final repository = _MockPurchaseOrderRepository();

    const order = PurchaseOrder(
      id: 10,
      vendorId: 3,
      status: PurchaseOrderStatus.fresh,
      statusLabel: 'جديد',
      orderDate: '2026-09-22',
      investorFunding: [
        PurchaseOrderFunding(
          dealId: 1,
          code: 'FUND',
          isFund: true,
          status: 'open',
          statusLabel: 'مفتوحة',
          investorProfitSharePercent: '50.00',
          stockItemIds: [7],
        ),
      ],
    );

    sl
      ..registerSingleton<Session>(Session())
      ..registerFactoryParam<PurchaseOrderDetailCubit, int, void>(
        (id, _) => PurchaseOrderDetailCubit(
          purchaseOrderId: id,
          getOrder: GetPurchaseOrder(repository),
          changeStatus: ChangePurchaseOrderStatus(repository),
          receiveArrival: ReceivePurchaseOrderArrival(repository),
          reverseReceiptUseCase: ReverseReceipt(repository),
        ),
      );

    when(() => repository.purchaseOrder(10)).thenAnswer((_) async => const Right(order));

    // Act
    await tester.pumpWidget(host(const PurchaseOrderDetailPage(purchaseOrderId: 10)));
    await tester.pumpAndSettle();

    // Assert — لا رمزَ محجوز على الشاشة، ولا حالةُ صفقة، والبابُ يقود إلى لوحة الصندوق.
    expect(find.text('شراء بمال الصندوق'), findsOneWidget);
    expect(find.text('تمويل FUND'), findsNothing);
    expect(find.text('مفتوحة'), findsNothing);

    final door = find.ancestor(
      of: find.text('اشتراه الصندوق بماله كلِّه'),
      matching: find.byType(InkWell),
    );

    expect(door, findsOneWidget);
    expect(Routes.investmentFund, '/investment');
  });
}
