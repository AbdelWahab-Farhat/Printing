import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/views/investor_detail_page.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetInvestor extends Mock implements GetInvestor {}

class _MockRecordWalletEntry extends Mock implements RecordWalletEntry {}

class _MockSetAutoReinvest extends Mock implements SetAutoReinvest {}

/// زرُّ «إعادة استثمار الأرباح تلقائياً» على صفحة المستثمر — CONTINUOUS-FUND-DESIGN §١٤.
///
/// Arrange - Act - Assert في كلٍّ منها.
void main() {
  late _MockGetInvestor getInvestor;
  late _MockSetAutoReinvest setAutoReinvest;

  void register(List<String> permissions) {
    sl
      ..registerSingleton<Session>(
        Session()..adopt(
          AuthUser(id: 1, name: 'عبدالوهاب', phone: '0911234567', permissions: permissions),
        ),
      )
      ..registerFactory<InvestorDetailCubit>(
        () => InvestorDetailCubit(
          getInvestor: getInvestor,
          recordWalletEntry: _MockRecordWalletEntry(),
          setAutoReinvest: setAutoReinvest,
        ),
      );
  }

  setUp(() async {
    await sl.reset();
    getInvestor = _MockGetInvestor();
    setAutoReinvest = _MockSetAutoReinvest();
  });

  tearDown(() async => sl.reset());

  Investor investor({bool on = false, DateTime? since, String walletProfit = '0.00'}) {
    return Investor(
      id: 7,
      code: 'I7',
      name: 'أحمد',
      autoReinvestProfit: on,
      autoReinvestSince: since,
      balances: InvestorBalances(
        wallet: WalletPots(capital: '0.00', profit: walletProfit),
        deals: const <DealPots>[],
      ),
    );
  }

  Future<void> open(WidgetTester tester, Investor shown) async {
    when(() => getInvestor(7)).thenAnswer((_) async => Right(shown));

    tester.view.physicalSize = const Size(1290, 4200);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => const MaterialApp(
          locale: Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: InvestorDetailPage(investorId: 7),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  SwitchListTile tile(WidgetTester tester) => tester.widget<SwitchListTile>(
    find.widgetWithText(SwitchListTile, 'إعادة استثمار الأرباح تلقائياً'),
  );

  testWidgets('off by default, and says the profit stays withdrawable', (tester) async {
    // Arrange
    register(['investors.view', 'investors.manage']);

    // Act
    await open(tester, investor());

    // Assert
    expect(tile(tester).value, isFalse);
    expect(find.text('أرباحه تبقى متاحة للسحب'), findsOneWidget);
  });

  testWidgets('turning it on asks first, names the waiting profit, then shows since when', (
    tester,
  ) async {
    // Arrange
    register(['investors.view', 'investors.manage']);
    final since = DateTime(2026, 11, 2, 10);
    when(
      () => setAutoReinvest(investorId: 7, enabled: true),
    ).thenAnswer((_) async => Right(investor(on: true, since: since)));
    await open(tester, investor(walletProfit: '1500.00'));

    // Act
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    // Assert — التأكيدُ يذكر ما سيُعاد أوّلاً، ولم يُرسَل شيءٌ بعد.
    expect(find.textContaining('(1,500 د.ل)'), findsOneWidget);
    verifyNever(() => setAutoReinvest(investorId: 7, enabled: true));

    // Act
    await tester.tap(find.text('تشغيل'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => setAutoReinvest(investorId: 7, enabled: true)).called(1);
    expect(tile(tester).value, isTrue);
    expect(find.textContaining('مفعّلة منذ'), findsOneWidget);
  });

  testWidgets('cancelling the confirmation sends nothing', (tester) async {
    // Arrange
    register(['investors.view', 'investors.manage']);
    await open(tester, investor());

    // Act
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // Assert
    verifyNever(() => setAutoReinvest(investorId: any(named: 'investorId'), enabled: true));
    expect(tile(tester).value, isFalse);
  });

  testWidgets('a reader without investors.manage sees the state but cannot flip it', (
    tester,
  ) async {
    // Arrange
    register(['investors.view']);

    // Act
    await open(tester, investor(on: true, since: DateTime(2026, 11, 2)));

    // Assert
    expect(tile(tester).value, isTrue);
    expect(tile(tester).onChanged, isNull);
  });
}
