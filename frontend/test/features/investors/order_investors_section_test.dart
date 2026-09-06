import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/features/investors/models/order_investor_share.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/order_investor_shares_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/order_investors_section.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «هذه الطلبية — من أخذ منها، وكم، وهل أخذه فعلاً» on the order screen.
///
/// The two roads read differently on purpose: a `plain_sale` was paid before the parcel moved
/// and its money is inside the order's cost, while an `order_profit` waits for «تم الاستلام» and
/// comes out of the order's profit. The section must never let the two be read as one column.
///
/// Arrange - Act - Assert throughout.
class _MockRepository extends Mock implements InvestorRepository {}

void main() {
  late _MockRepository repository;

  OrderInvestorShare shareOf({
    required String kind,
    String? goodsAmount,
    String profit = '2100.00',
    String investorsShare = '336.00',
    String companyShare = '1764.00',
    bool isPaid = true,
    String? paidAmount = '336.00',
  }) => OrderInvestorShare(
    dealId: 22,
    dealCode: 'D22',
    kind: kind,
    kindLabel: kind == 'plain_sale' ? 'بيع السادة للمطبعة' : 'حصة من ربح الطلبية',
    goodsAmount: goodsAmount,
    profit: profit,
    investorsShare: investorsShare,
    companyShare: companyShare,
    isPaid: isPaid,
    paidAmount: paidAmount,
  );

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
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(body: OrderInvestorsSection(orderId: 7)),
      ),
    ),
  );

  setUp(() async {
    await Injector.reset();
    repository = _MockRepository();
    sl.registerFactory<OrderInvestorSharesCubit>(
      () => OrderInvestorSharesCubit(getShares: GetOrderInvestorShares(repository)),
    );
  });

  tearDown(Injector.reset);

  testWidgets('a deal the press bought from is shown paid, with what it paid for the goods', (
    tester,
  ) async {
    // Arrange
    when(() => repository.orderInvestorShares(7)).thenAnswer(
      (_) async => Right([shareOf(kind: 'plain_sale', goodsAmount: '9600.00')]),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the road, the two halves of the margin, and the plain word that answers «هل أخذ
    // منها مالاً».
    expect(find.text('D22 · بيع السادة للمطبعة'), findsOneWidget);
    expect(find.text('مدفوع'), findsOneWidget);
    expect(find.text('336 د.ل'), findsOneWidget);
    expect(find.text('1,764 د.ل'), findsOneWidget);
    expect(
      find.text('اشترت المطبعة السادة بـ 9,600 د.ل · ربح 2,100 د.ل · عند خروج البضاعة من المخزن'),
      findsOneWidget,
    );
  });

  testWidgets('a deal still riding the sale says so, and that nothing has been taken yet', (
    tester,
  ) async {
    // Arrange — the old road: nothing is paid until the parcel reaches the customer.
    when(() => repository.orderInvestorShares(7)).thenAnswer(
      (_) async => Right([
        shareOf(
          kind: 'order_profit',
          profit: '10500.00',
          investorsShare: '840.00',
          companyShare: '9660.00',
          isPaid: false,
          paidAmount: null,
        ),
      ]),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the figure it *will* be is shown, and it is labelled as not yet taken. Hiding the
    // row until payment would read as «لا مستثمر في هذه الطلبية».
    expect(find.text('D22 · حصة من ربح الطلبية'), findsOneWidget);
    expect(find.text('لم يُدفع بعد'), findsOneWidget);
    expect(find.text('840 د.ل'), findsOneWidget);
    expect(
      find.text('نصيب الصفقة من ربح الطلبية 10,500 د.ل · يُدفع عند «تم الاستلام»'),
      findsOneWidget,
    );
  });

  testWidgets('an order that touched no deal draws nothing at all', (tester) async {
    // Arrange — most orders.
    when(() => repository.orderInvestorShares(7))
        .thenAnswer((_) async => const Right(<OrderInvestorShare>[]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — not an empty card under a heading, which would ask a question the absence
    // already answers.
    expect(find.byType(Container), findsNothing);
  });
}
