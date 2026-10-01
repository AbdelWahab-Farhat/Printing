import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/views/treasury_settings_page.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTreasuryRepository extends Mock implements TreasuryRepository {}

/// «إعدادات المالية» — TREASURY-DESIGN §١٦.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockTreasuryRepository repository;

  const cashBox = TreasuryAccount(
    id: 1,
    name: 'الخزنة الرئيسية',
    kind: AccountKind.cash,
    kindLabel: 'خزنة',
    isDefault: true,
    isActive: true,
    isSystem: false,
    isSpendable: true,
    balance: '100.00',
  );
  const bank = TreasuryAccount(
    id: 2,
    name: 'المصرف',
    kind: AccountKind.bank,
    kindLabel: 'مصرف',
    isDefault: true,
    isActive: true,
    isSystem: false,
    isSpendable: true,
    balance: '0.00',
  );
  const nawris = TreasuryAccount(
    id: 4,
    name: 'النورس',
    kind: AccountKind.custody,
    kindLabel: 'عهدة',
    isDefault: false,
    isActive: true,
    isSystem: true,
    isSpendable: false,
    balance: '0.00',
  );

  const settings = TreasurySettings(
    ownAccountFirst: true,
    blockOverdraft: true,
    withdrawalNeedsReason: true,
    askCarrierFee: true,
  );

  setUp(() async {
    await sl.reset();
    repository = _MockTreasuryRepository();

    when(() => repository.settings()).thenAnswer((_) async => const Right(settings));
    when(() => repository.accounts()).thenAnswer(
      (_) async => const Right(
        TreasuryAccounts(accounts: [cashBox, bank, nawris], total: '100.00', canViewAll: true),
      ),
    );
    when(() => repository.expenseCategories(activeOnly: false)).thenAnswer(
      (_) async => const Right([
        ExpenseCategory(id: 1, name: 'رسوم شركة التوصيل', requiresEmployee: false, isActive: true, isSystem: true),
        ExpenseCategory(id: 3, name: 'إيجار', requiresEmployee: false, isActive: true, isSystem: false),
      ]),
    );

    sl
      ..registerLazySingleton(() => GetTreasurySettings(repository))
      ..registerLazySingleton(() => SaveTreasurySettings(repository))
      ..registerLazySingleton(() => GetTreasuryAccounts(repository))
      ..registerLazySingleton(() => SaveTreasuryAccount(repository))
      ..registerLazySingleton(() => SetSettlesInto(repository))
      ..registerLazySingleton(() => GetExpenseCategories(repository))
      ..registerLazySingleton(() => SaveExpenseCategory(repository));
  });

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
      home: TreasurySettingsPage(),
    ),
  );

  testWidgets('the page shows the switches, each method\'s default, and where Nawris settles', (
    tester,
  ) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الحساب الشخصي أولاً'), findsOneWidget);
    expect(find.text('منع الرصيد السالب في العمليات اليدوية'), findsOneWidget);
    expect(find.text('مقفل حتى تاريخ'), findsOneWidget);
    expect(find.text('كاش'), findsOneWidget);
    expect(find.text('الخزنة الرئيسية'), findsWidgets);

    await tester.scrollUntilVisible(find.text('القاعدة الافتراضية'), 200);
    expect(find.text('القاعدة الافتراضية'), findsOneWidget);
  });

  testWidgets('switching a rule off saves only that switch', (tester) async {
    // Arrange
    when(() => repository.saveSettings(blockOverdraft: false)).thenAnswer(
      (_) async => const Right(
        TreasurySettings(
          ownAccountFirst: true,
          blockOverdraft: false,
          withdrawalNeedsReason: true,
          askCarrierFee: true,
        ),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('منع الرصيد السالب في العمليات اليدوية'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.saveSettings(blockOverdraft: false)).called(1);
  });

  group('التجميع عند التسوية — §١٨', () {
    const alisBank = TreasuryAccount(
      id: 5,
      name: 'مصرف علي',
      kind: AccountKind.bank,
      kindLabel: 'مصرف',
      isDefault: false,
      isActive: true,
      isSystem: false,
      isSpendable: true,
      balance: '300.00',
    );
    const collectingBanks = TreasurySettings(
      ownAccountFirst: true,
      blockOverdraft: true,
      withdrawalNeedsReason: true,
      askCarrierFee: true,
      collections: {AccountKind.bank: CollectionSetting(on: true)},
    );

    testWidgets('switching a kind on saves that kind\'s switch alone', (tester) async {
      // Arrange
      when(
        () => repository.saveSettings(collectKind: AccountKind.bank, collectOn: true),
      ).thenAnswer((_) async => const Right(collectingBanks));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('تجميع المصارف'), 200);

      // Act
      await tester.tap(find.text('تجميع المصارف'));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => repository.saveSettings(collectKind: AccountKind.bank, collectOn: true),
      ).called(1);
    });

    testWidgets('while on, it names the account and lets another keep its money', (tester) async {
      // Arrange
      when(() => repository.settings()).thenAnswer((_) async => const Right(collectingBanks));
      when(() => repository.accounts()).thenAnswer(
        (_) async => const Right(
          TreasuryAccounts(
            accounts: [cashBox, bank, alisBank, nawris],
            total: '400.00',
            canViewAll: true,
          ),
        ),
      );
      when(
        () => repository.saveAccount(id: 5, name: 'مصرف علي', isCollected: false),
      ).thenAnswer((_) async => const Right(alisBank));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('الافتراضي (المصرف)'), 200);

      // Act
      await tester.scrollUntilVisible(find.byKey(const ValueKey('collected-5')), 200);
      await tester.ensureVisible(find.byKey(const ValueKey('collected-5')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('collected-5')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('يُجمع مال الطلبية في «المصرف» عند التسوية'), findsOneWidget);
      verify(
        () => repository.saveAccount(id: 5, name: 'مصرف علي', isCollected: false),
      ).called(1);
    });
  });

  testWidgets('each pickup branch shows its box, and picking one links it — §١٩', (tester) async {
    // Arrange
    const misrataBox = TreasuryAccount(
      id: 9,
      name: 'خزنة فرع مصراتة',
      kind: AccountKind.cash,
      kindLabel: 'خزنة',
      isDefault: false,
      isActive: true,
      isSystem: false,
      isSpendable: true,
      balance: '0.00',
    );
    when(() => repository.settings()).thenAnswer(
      (_) async => const Right(
        TreasurySettings(
          ownAccountFirst: true,
          blockOverdraft: true,
          withdrawalNeedsReason: true,
          askCarrierFee: true,
          pickupOffices: [PickupOffice(cityId: 40, name: 'استلام مكتب مصراتة')],
        ),
      ),
    );
    when(() => repository.accounts()).thenAnswer(
      (_) async => const Right(
        TreasuryAccounts(
          accounts: [cashBox, bank, misrataBox, nawris],
          total: '100.00',
          canViewAll: true,
        ),
      ),
    );
    when(
      () => repository.saveAccount(id: 9, name: 'خزنة فرع مصراتة', pickupCityId: 40),
    ).thenAnswer((_) async => const Right(misrataBox));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('استلام مكتب مصراتة'), 200);

    // Act
    await tester.tap(find.text('استلام مكتب مصراتة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('خزنة فرع مصراتة').last);
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('القاعدة العادية'), findsWidgets);
    verify(
      () => repository.saveAccount(id: 9, name: 'خزنة فرع مصراتة', pickupCityId: 40),
    ).called(1);
  });

  testWidgets('a category the system relies on cannot be switched off', (tester) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('رسوم شركة التوصيل'), 200);

    // Assert
    final tile = tester.widget<SwitchListTile>(
      find.ancestor(of: find.text('رسوم شركة التوصيل'), matching: find.byType(SwitchListTile)),
    );
    expect(tile.onChanged, isNull);
  });
}
