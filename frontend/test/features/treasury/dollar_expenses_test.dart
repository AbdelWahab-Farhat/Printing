import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_operation_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// An expense out of a dollar account — USD-ACCOUNTS.md §٨, phase 5: in dollars, with the rate
/// «المصاريف» counts it at in dinars.
///
/// Arrange - Act - Assert throughout.
const _dollarBox = TreasuryAccount(
  id: 2,
  name: 'خزنة الدولار',
  kind: AccountKind.cash,
  kindLabel: 'كاش',
  isDefault: false,
  isActive: true,
  isSystem: false,
  isSpendable: true,
  balance: '500.00',
  currency: Currency.usd,
);

void main() {
  late MockTreasuryRepository repository;

  setUp(() async {
    await sl.reset();
    repository = MockTreasuryRepository();
    when(() => repository.expenseCategories()).thenAnswer(
      (_) async => const Right([
        ExpenseCategory(
          id: 3,
          name: 'شحن',
          requiresEmployee: false,
          isActive: true,
          isSystem: false,
        ),
      ]),
    );
    sl.registerLazySingleton(() => GetExpenseCategories(repository));
  });

  tearDown(() => sl.reset());

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

  Finder field(String key) =>
      find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText));

  /// Opens the expense sheet on [account], and returns what was sent.
  Future<List<String?>> openExpense(
    WidgetTester tester,
    TreasuryAccount account, {
    String? systemRate,
  }) async {
    final sent = <String?>[];

    await tester.pumpWidget(
      host(
        (context) => showTreasuryOperationSheet(
          context: context,
          kind: OperationKind.expense,
          accounts: [cashBox, account],
          account: account,
          systemRate: systemRate,
          onSubmit:
              ({
                required kind,
                amount,
                fromAccountId,
                toAccountId,
                categoryId,
                employeeId,
                countedBalance,
                notes,
                clientToken,
                rate,
              }) async {
                sent
                  ..add(amount)
                  ..add(rate);

                return null;
              },
        ),
      ),
    );
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    return sent;
  }

  Future<void> fillAndSend(WidgetTester tester, String amount) async {
    await tester.tap(find.byType(AppDropdown<ExpenseCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('شحن').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(AppTextField).first, amount);
    await tester.pump();
    final button = find.text('تسجيل مصروف');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  }

  testWidgets('from dollars the sheet asks the rate, opens it on the system rate and sends it', (
    tester,
  ) async {
    // Arrange
    final sent = await openExpense(tester, _dollarBox, systemRate: '7.1500');

    // Act
    await fillAndSend(tester, '40');

    // Assert
    expect(sent, ['40', '7.15']);
  });

  testWidgets('it says what the dollars come to in dinars', (tester) async {
    // Arrange
    await openExpense(tester, _dollarBox, systemRate: '7');

    // Act
    await tester.enterText(find.byType(AppTextField).first, '40');
    await tester.pump();

    // Assert
    expect(tester.widget<EditableText>(field('expense-rate')).controller.text, '7');
    expect(find.text('يُحسب في «المصاريف» بـ 280 د.ل'), findsOneWidget);
  });

  testWidgets('a dinar expense asks no rate and sends none', (tester) async {
    // Arrange
    final sent = await openExpense(tester, cashBox, systemRate: '7');

    // Act
    await fillAndSend(tester, '100');

    // Assert
    expect(find.byKey(const ValueKey('expense-rate')), findsNothing);
    expect(sent, ['100', null]);
  });

  test('a line of «المصاريف» knows its account\'s currency and its dinars', () {
    // Act
    final line = TreasuryMovement.fromJson({
      'id': 9,
      'kind': 'expense',
      'kind_label': 'مصروف',
      'direction': 'out',
      'signed_amount': '-40.00',
      'dinar_amount': '280.00',
      'account': {'id': 2, 'name': 'خزنة الدولار', 'kind': 'cash', 'currency': 'USD'},
    });

    // Assert — and it keeps them once reversed.
    expect(line.accountCurrency, Currency.usd);
    expect(line.dinarAmount, '280.00');
    expect(line.markedReversed().dinarAmount, '280.00');
  });

  testWidgets('a dollar line is written in dollars, with its dinars under it', (tester) async {
    // Arrange
    final line = TreasuryMovement.fromJson({
      'id': 9,
      'kind': 'expense',
      'kind_label': 'مصروف',
      'direction': 'out',
      'signed_amount': '-40.00',
      'dinar_amount': '280.00',
      'account': {'id': 2, 'name': 'خزنة الدولار', 'kind': 'cash', 'currency': 'USD'},
    });

    // Act
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(430, 932),
        builder: (context, _) => MaterialApp(
          home: Scaffold(body: TreasuryMovementRow(movement: line)),
        ),
      ),
    );

    // Assert
    expect(
      find.text(treasuryMoney('-40.00', signed: true, currency: Currency.usd)),
      findsOneWidget,
    );
    expect(find.text('≈ 280 د.ل'), findsOneWidget);
  });
}
