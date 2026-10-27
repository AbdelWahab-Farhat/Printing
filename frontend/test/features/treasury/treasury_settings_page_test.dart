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
    name: 'الكاش الرئيسي',
    kind: AccountKind.cash,
    kindLabel: 'كاش',
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

    sl
      ..registerLazySingleton(() => GetTreasurySettings(repository))
      ..registerLazySingleton(() => SaveTreasurySettings(repository))
      ..registerLazySingleton(() => GetTreasuryAccounts(repository))
      ..registerLazySingleton(() => SaveTreasuryAccount(repository))
      ..registerLazySingleton(() => SetSettlesInto(repository));
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

  /// يمرّر حتى يُرى [finder] كاملاً على الشاشة: `scrollUntilVisible` يقف حين يُبنى الصفّ،
  /// وقد يكون حينها تحت حافّة الشاشة فتضيع الضغطة.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(finder, 200);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('the page is four cards: «الدفعة», «التسوية», «الحماية», and each default', (
    tester,
  ) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الدفعة'), findsOneWidget);
    expect(find.text('الافتراضي'), findsOneWidget);
    expect(find.text('كاش'), findsOneWidget);
    expect(find.text('الكاش الرئيسي'), findsWidgets);

    await reveal(tester, find.text('التسوية'));
    expect(find.text('التسوية'), findsOneWidget);

    await reveal(tester, find.text('تلقائي'));
    expect(find.text('النورس'), findsOneWidget);

    await reveal(tester, find.text('مقفل حتى'));
    expect(find.text('الحماية'), findsOneWidget);
    expect(find.text('لا شيء'), findsOneWidget);
  });

  testWidgets('«الحساب الشخصي أولاً» is the last row of «الدفعة» and says what it means', (
    tester,
  ) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await reveal(tester, find.text('الحساب الشخصي أولاً'));

    // Assert
    expect(
      find.text('تنزل الدفعة في حساب من سجّلها بدل الافتراضي، إن كان له حساب من نوعها'),
      findsOneWidget,
    );
    expect(
      tester.getTopLeft(find.text('الحساب الشخصي أولاً')).dy,
      greaterThan(tester.getTopLeft(find.text('ليبيانا')).dy),
    );
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
    await reveal(tester, find.text('منع الرصيد السالب'));

    // Act
    await tester.tap(find.text('منع الرصيد السالب'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.saveSettings(blockOverdraft: false)).called(1);
  });

  group('اجمع — §١٨', () {
    const collectingBanks = TreasurySettings(
      ownAccountFirst: true,
      blockOverdraft: true,
      withdrawalNeedsReason: true,
      askCarrierFee: true,
      collections: {AccountKind.bank: CollectionSetting(on: true)},
    );

    void withAlisBank() => when(() => repository.accounts()).thenAnswer(
      (_) async => const Right(
        TreasuryAccounts(
          accounts: [cashBox, bank, alisBank, nawris],
          total: '400.00',
          canViewAll: true,
        ),
      ),
    );

    testWidgets('switching a kind on saves that kind\'s switch alone', (tester) async {
      // Arrange
      when(
        () => repository.saveSettings(collectKind: AccountKind.bank, collectOn: true),
      ).thenAnswer((_) async => const Right(collectingBanks));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      await reveal(tester, find.text('اجمع الحوالات والبطاقات'));

      // Act
      await tester.tap(find.text('اجمع الحوالات والبطاقات'));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => repository.saveSettings(collectKind: AccountKind.bank, collectOn: true),
      ).called(1);
    });

    testWidgets('while on, «في:» names the account and «من:» lets another keep its money', (
      tester,
    ) async {
      // Arrange
      when(() => repository.settings()).thenAnswer((_) async => const Right(collectingBanks));
      withAlisBank();
      when(
        () => repository.saveAccount(id: 5, name: 'مصرف علي', isCollected: false),
      ).thenAnswer((_) async => const Right(alisBank));
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final into = find.byKey(const ValueKey('collect-into-bank'));
      final from = find.byKey(const ValueKey('collect-from-bank'));
      await reveal(tester, from);

      // Act
      await tester.tap(from);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('collected-5')));
      await tester.pumpAndSettle();

      // Assert
      expect(find.descendant(of: into, matching: find.text('المصرف')), findsOneWidget);
      expect(find.descendant(of: from, matching: find.text('الكل')), findsOneWidget);
      verify(
        () => repository.saveAccount(id: 5, name: 'مصرف علي', isCollected: false),
      ).called(1);
    });

    testWidgets('while off, «في:» and «من:» still show but do not open', (tester) async {
      // Arrange
      withAlisBank();
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final from = find.byKey(const ValueKey('collect-from-bank'));
      await reveal(tester, from);

      // Act
      await tester.tap(from, warnIfMissed: false);
      await tester.pumpAndSettle();

      // Assert
      expect(find.byKey(const ValueKey('collect-into-bank')), findsOneWidget);
      expect(find.byKey(const ValueKey('collected-5')), findsNothing);
    });
  });

  testWidgets('each pickup office shows by its short name, and picking a box links it — §١٩', (
    tester,
  ) async {
    // Arrange
    const misrataBox = TreasuryAccount(
      id: 9,
      name: 'كاش فرع مصراتة',
      kind: AccountKind.cash,
      kindLabel: 'كاش',
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
          pickupOffices: [PickupOffice(cityId: 40, name: 'إستلام مكتب(مصراتة)')],
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
      () => repository.saveAccount(id: 9, name: 'كاش فرع مصراتة', pickupCityId: 40),
    ).thenAnswer((_) async => const Right(misrataBox));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    expect(find.text('كاش المكتب عندما تكون الطلبية استلام مكتب'), findsOneWidget);

    // Act
    await tester.tap(find.text('مصراتة'));
    await tester.pumpAndSettle();
    expect(find.text('كاش «مصراتة»'), findsOneWidget);
    await tester.tap(find.text('كاش فرع مصراتة').last);
    await tester.pumpAndSettle();

    // Assert
    verify(
      () => repository.saveAccount(id: 9, name: 'كاش فرع مصراتة', pickupCityId: 40),
    ).called(1);
  });

  testWidgets('«إلى حساب المسوّي تلقائياً» starts off and saves alone — §٢٢', (tester) async {
    // Arrange
    when(() => repository.saveSettings(settleIntoSettler: true)).thenAnswer(
      (_) async => const Right(
        TreasurySettings(
          ownAccountFirst: true,
          blockOverdraft: true,
          withdrawalNeedsReason: true,
          askCarrierFee: true,
          settleIntoSettler: true,
        ),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('settle-into-settler'));
    await reveal(tester, tile);

    // Act
    final before = tester.widget<SwitchListTile>(
      find.descendant(of: tile, matching: find.byType(SwitchListTile)),
    );
    await tester.tap(find.text('إلى حساب المسوّي تلقائياً'));
    await tester.pumpAndSettle();

    // Assert
    expect(before.value, isFalse);
    verify(() => repository.saveSettings(settleIntoSettler: true)).called(1);
  });

  testWidgets('«اختيار الحساب عند التغيير لحالة التسوية» starts off and saves alone — §٢٤', (
    tester,
  ) async {
    // Arrange
    when(() => repository.saveSettings(pickSettlementAccounts: true)).thenAnswer(
      (_) async => const Right(
        TreasurySettings(
          ownAccountFirst: true,
          blockOverdraft: true,
          withdrawalNeedsReason: true,
          askCarrierFee: true,
          pickSettlementAccounts: true,
        ),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    final tile = find.byKey(const ValueKey('pick-settlement-accounts'));
    await reveal(tester, tile);

    // Act
    final before = tester.widget<SwitchListTile>(
      find.descendant(of: tile, matching: find.byType(SwitchListTile)),
    );
    await tester.tap(find.text('اختيار الحساب عند التغيير لحالة التسوية'));
    await tester.pumpAndSettle();

    // Assert
    expect(before.value, isFalse);
    verify(() => repository.saveSettings(pickSettlementAccounts: true)).called(1);
  });

  group('ⓘ — each one opens its own short explanation', () {
    testWidgets('«الدفعة» lists every case in order', (tester) async {
      // Arrange
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byTooltip('شرح: الدفعة'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('أين تنزل الدفعة؟'), findsOneWidget);
      expect(find.text('كاش ذلك المكتب'), findsOneWidget);
      expect(find.text('لا تدخل كاش المكتب'), findsOneWidget);
    });

    testWidgets('«إلى حساب المسوّي تلقائياً» says it follows the person, unlike «اجمع»', (
      tester,
    ) async {
      // Arrange
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final explain = find.byTooltip('ما معنى: إلى حساب المسوّي تلقائياً');
      await reveal(tester, explain);

      // Act
      await tester.tap(explain);
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('يتبع الشخص'), findsOneWidget);
      expect(find.text('حساب واحد ثابت'), findsOneWidget);
    });

    testWidgets('«التجميع» says its money goes to the one account in «في:»', (tester) async {
      // Arrange
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();
      final explain = find.byTooltip('ما معنى: التجميع');
      await reveal(tester, explain);

      // Act
      await tester.tap(explain);
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining('نفس الحساب مهما كان من يسوّي'), findsOneWidget);
    });
  });

  testWidgets('the online fee is a two-way choice that saves the other side', (tester) async {
    // Arrange
    when(() => repository.settings()).thenAnswer(
      (_) async => const Right(
        TreasurySettings(
          ownAccountFirst: true,
          blockOverdraft: true,
          withdrawalNeedsReason: true,
          askCarrierFee: true,
          onlineFeePayer: 'customer',
        ),
      ),
    );
    when(() => repository.saveSettings(onlineFeePayer: 'shop')).thenAnswer(
      (_) async => const Right(
        TreasurySettings(
          ownAccountFirst: true,
          blockOverdraft: true,
          withdrawalNeedsReason: true,
          askCarrierFee: true,
          onlineFeePayer: 'shop',
        ),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await reveal(tester, find.text('المحلّ'));

    // Act
    await tester.tap(find.text('المحلّ'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.saveSettings(onlineFeePayer: 'shop')).called(1);
  });

  testWidgets('«احتفظ به الناقل» is not asked about on this page', (tester) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await reveal(tester, find.text('مقفل حتى'));

    // Assert
    expect(find.textContaining('احتفظ به الناقل'), findsNothing);
  });

  testWidgets('the expense categories are not on this page — they have their own', (tester) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await reveal(tester, find.text('مقفل حتى'));

    // Assert
    expect(find.text('تصنيفات المصروفات'), findsNothing);
    expect(find.text('تصنيف جديد'), findsNothing);
    verifyNever(() => repository.expenseCategories(activeOnly: false));
  });

  testWidgets('the accounts are not on this page — they live in «الحسابات والكاش»', (tester) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await reveal(tester, find.text('مقفل حتى'));
    await tester.drag(find.byType(Scrollable).first, const Offset(0, -2000));
    await tester.pumpAndSettle();

    // Assert — الإعداداتُ قواعد تُضبط؛ الحساباتُ تُفتح وتُضاف من صفحتها.
    expect(find.text('الحسابات'), findsNothing);
    expect(find.text('حساب جديد'), findsNothing);
  });
}
