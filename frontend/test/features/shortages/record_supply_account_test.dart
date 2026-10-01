import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/shortages/models/shortage.dart';
import 'package:dayaa/features/shortages/presentation/views/record_supply_page.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../treasury/treasury_fixtures.dart';

/// «دُفع من» على «تسجيل توفير»: الدرج المختار لطريقةٍ لا يسافر مع طريقةٍ أخرى.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository treasury;

  const options = AccountOptions(
    accounts: [
      AccountOption(id: 1, name: 'الكاش الرئيسي', kindLabel: 'خزنة', isDefault: true),
      AccountOption(id: 9, name: 'كاش فرع مصراتة', kindLabel: 'خزنة', isDefault: false),
    ],
    suggestedId: 1,
    suggestedName: 'الكاش الرئيسي',
  );

  const tape = Shortage(
    id: 41,
    code: 'N41',
    source: ShortageSource.order,
    sourceLabel: 'من طلبية',
    name: 'شريط لاصق عريض',
    unit: 'piece',
    unitLabel: 'قطعة',
    requiredQuantity: '30.000',
    suppliedQuantity: '20.000',
    remainingQuantity: '10.000',
    totalPaid: '500.00',
    status: ShortageStatus.searching,
    statusLabel: 'جاري البحث',
    isStockable: false,
  );

  setUp(() async {
    await sl.reset();
    treasury = MockTreasuryRepository();

    when(
      () => treasury.accountOptions(
        method: any(named: 'method'),
        incoming: any(named: 'incoming'),
      ),
    ).thenAnswer((_) async => const Right(options));

    sl
      ..registerLazySingleton(() => GetAccountOptions(treasury))
      ..registerLazySingleton(() => GetTreasuryAccounts(treasury));
  });

  tearDown(() => sl.reset());

  /// شاشةٌ بزرٍّ يفتح «تسجيل توفير» ويحفظ ما عادت به.
  Widget host(void Function(SupplyEntry?) onClosed) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async =>
                    onClosed(await context.push<SupplyEntry>('/supply')),
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
        GoRoute(path: '/supply', builder: (_, _) => const RecordSupplyPage(shortage: tape)),
      ],
    );

    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp.router(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        routerConfig: router,
      ),
    );
  }

  Future<void> choose(WidgetTester tester, Finder field, String label) async {
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// يفتح الصفحة، ويكتب الكمية والقيمة، ويختار «كاش فرع مصراتة».
  Future<void> fillAndPickBranchBox(WidgetTester tester) async {
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(AppTextField).at(0), '5');
    await tester.enterText(find.byType(AppTextField).at(1), '75');
    await tester.pump();
    await choose(tester, find.byType(AppDropdown<AccountOption>), 'كاش فرع مصراتة');
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.text('تسجيل');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('the drawer picked for cash travels with a cash purchase', (tester) async {
    // Arrange
    SupplyEntry? entry;
    await tester.pumpWidget(host((closed) => entry = closed));
    await fillAndPickBranchBox(tester);

    // Act
    await save(tester);

    // Assert
    expect(entry?.treasuryAccountId, 9);
  });

  testWidgets('switching the method clears the drawer picked for the old one', (tester) async {
    // Arrange
    SupplyEntry? entry;
    await tester.pumpWidget(host((closed) => entry = closed));
    await fillAndPickBranchBox(tester);

    // Act
    await choose(tester, find.byType(AppDropdown<PaymentMethod>), PaymentMethod.libyana.label);
    await save(tester);

    // Assert
    expect(entry, isNotNull);
    expect(entry!.treasuryAccountId, isNull);
  });
}
