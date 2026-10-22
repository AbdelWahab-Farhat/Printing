import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investors/models/investor.dart';
import 'package:dayaa/features/investors/presentation/viewmodel/investor_detail_cubit.dart';
import 'package:dayaa/features/investors/presentation/widgets/wallet_entry_sheet.dart';
import 'package:dayaa/features/investors/repositories/investor_repository.dart';
import 'package:dayaa/features/investors/usecases/investor_usecases.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../treasury/treasury_fixtures.dart';

class _MockInvestorRepository extends Mock implements InvestorRepository {}

/// «الكل» على مبلغ حركة المحفظة — يضع رصيدَ الجيب الذي تأخذ منه الحركة، فلا يُكتب بيد.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository treasury;
  late _MockInvestorRepository investors;
  late InvestorDetailCubit cubit;

  const investor = Investor(
    id: 3,
    code: 'INV-3',
    name: 'عبدالرحمن',
    balances: InvestorBalances(wallet: WalletPots(capital: '4842.00', profit: '366.09')),
  );

  setUp(() async {
    await sl.reset();
    treasury = MockTreasuryRepository();
    investors = _MockInvestorRepository();

    when(
      () => treasury.accountOptions(
        method: any(named: 'method'),
        incoming: any(named: 'incoming'),
      ),
    ).thenAnswer((_) async => const Right(AccountOptions(accounts: [], suggestedId: null)));
    when(
      () => investors.investor(3),
    ).thenAnswer((_) async => const Left(Failure.server(message: 'لا يهمّ هنا')));

    sl
      ..registerLazySingleton(() => GetAccountOptions(treasury))
      ..registerLazySingleton(() => GetTreasuryAccounts(treasury));

    cubit = InvestorDetailCubit(
      getInvestor: GetInvestor(investors),
      recordWalletEntry: RecordWalletEntry(investors),
    );
  });

  tearDown(() async {
    await cubit.close();
    await sl.reset();
  });

  Widget host({Investor who = investor}) => ScreenUtilInit(
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
            child: ElevatedButton(
              onPressed: () => showWalletEntrySheet(context: context, cubit: cubit, investor: who),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );

  /// يفتح الورقة على «نوع الحركة» المطلوب.
  Future<void> openOn(WidgetTester tester, WalletAction action, {Investor who = investor}) async {
    await tester.pumpWidget(host(who: who));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    final field = find.byType(AppDropdown<WalletAction>);
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(action.label).last);
    await tester.pumpAndSettle();
  }

  Finder amountField() => find.widgetWithText(AppTextField, 'المبلغ');

  String amountText(WidgetTester tester) =>
      tester.widget<AppTextField>(amountField()).controller!.text;

  Future<void> tapAll(WidgetTester tester) async {
    final all = find.descendant(of: amountField(), matching: find.text('الكل'));
    await tester.ensureVisible(all);
    await tester.pumpAndSettle();
    await tester.tap(all);
    await tester.pumpAndSettle();
  }

  testWidgets('«الكل» on «تحويل أرباح إلى رأس مال» puts the profit in his wallet', (tester) async {
    // Arrange
    await openOn(tester, WalletAction.profitCapitalisation);

    // Act
    await tapAll(tester);

    // Assert
    expect(amountText(tester), '366.09');
  });

  testWidgets('«الكل» on «سحب أرباح» puts the same profit', (tester) async {
    // Arrange
    await openOn(tester, WalletAction.profitWithdrawal);

    // Act
    await tapAll(tester);

    // Assert
    expect(amountText(tester), '366.09');
  });

  testWidgets('«الكل» on «سحب رأس مال» puts the capital in his wallet', (tester) async {
    // Arrange
    await openOn(tester, WalletAction.withdrawal);

    // Act
    await tapAll(tester);

    // Assert
    expect(amountText(tester), '4842.00');
  });

  testWidgets('a deposit has no ceiling, so no «الكل»', (tester) async {
    // Arrange
    await openOn(tester, WalletAction.deposit);

    // Act
    final all = find.descendant(of: amountField(), matching: find.text('الكل'));

    // Assert
    expect(all, findsNothing);
  });

  testWidgets('an empty pot offers no «الكل»', (tester) async {
    // Arrange
    const broke = Investor(
      id: 3,
      code: 'INV-3',
      name: 'عبدالرحمن',
      balances: InvestorBalances(wallet: WalletPots(capital: '0.00', profit: '0.00')),
    );
    await openOn(tester, WalletAction.profitCapitalisation, who: broke);

    // Act
    final all = find.descendant(of: amountField(), matching: find.text('الكل'));

    // Assert
    expect(all, findsNothing);
  });

  testWidgets('the refusal under the amount goes once the amount is changed', (tester) async {
    // Arrange
    const refusal = 'المبلغ المطلوب 400.00 أكبر من الرصيد المتاح 366.09';
    when(
      () => investors.recordWalletEntry(
        investorId: any(named: 'investorId'),
        type: any(named: 'type'),
        amount: any(named: 'amount'),
        method: any(named: 'method'),
        notes: any(named: 'notes'),
        treasuryAccountId: any(named: 'treasuryAccountId'),
      ),
    ).thenAnswer(
      (_) async => const Left(
        Failure.server(
          message: refusal,
          statusCode: 422,
          fieldErrors: {
            'amount': [refusal],
          },
        ),
      ),
    );
    await openOn(tester, WalletAction.profitCapitalisation);
    await tester.enterText(amountField(), '400');
    await tester.pump();
    await tester.ensureVisible(find.text('تسجيل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();
    final before = find.text(refusal).evaluate().length;

    // Act
    await tapAll(tester);

    // Assert
    expect(before, 1);
    expect(find.text(refusal), findsNothing);
  });
}
