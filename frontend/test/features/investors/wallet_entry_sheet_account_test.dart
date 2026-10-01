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
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../treasury/treasury_fixtures.dart';

class _MockInvestorRepository extends Mock implements InvestorRepository {}

/// «الحساب» على حركة محفظة المستثمر — الإيداع ينزل في حساب، والسحب يخرج من حساب، والحساب
/// المختار لا يسافر مع حركةٍ أو طريقةٍ أخرى. TREASURY-DESIGN §٧.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository treasury;
  late _MockInvestorRepository investors;
  late InvestorDetailCubit cubit;

  const investor = Investor(id: 3, code: 'INV-3', name: 'سالم');

  const options = AccountOptions(
    accounts: [
      AccountOption(id: 1, name: 'الخزنة الرئيسية', kindLabel: 'خزنة', isDefault: true),
      AccountOption(id: 9, name: 'خزنة فرع مصراتة', kindLabel: 'خزنة', isDefault: false),
    ],
    suggestedId: 1,
    suggestedName: 'الخزنة الرئيسية',
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
    ).thenAnswer((_) async => const Right(options));
    when(
      () => investors.recordWalletEntry(
        investorId: any(named: 'investorId'),
        type: any(named: 'type'),
        amount: any(named: 'amount'),
        method: any(named: 'method'),
        notes: any(named: 'notes'),
        treasuryAccountId: any(named: 'treasuryAccountId'),
      ),
    ).thenAnswer((_) async => const Right(unit));
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

  Widget host() => ScreenUtilInit(
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
              onPressed: () =>
                  showWalletEntrySheet(context: context, cubit: cubit, investor: investor),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> choose<T>(WidgetTester tester, Finder field, String label) async {
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  /// يفتح الورقة، ويختار «خزنة فرع مصراتة» حساباً للإيداع.
  Future<void> openAndPickBranchBox(WidgetTester tester) async {
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    await choose<AccountOption>(
      tester,
      find.byType(AppDropdown<AccountOption>),
      'خزنة فرع مصراتة',
    );
  }

  Future<int?> submitAndReadAccount(WidgetTester tester) async {
    await tester.enterText(find.byType(AppTextField).first, '500');
    await tester.pump();
    final button = find.text('تسجيل');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    return verify(
          () => investors.recordWalletEntry(
            investorId: any(named: 'investorId'),
            type: any(named: 'type'),
            amount: any(named: 'amount'),
            method: any(named: 'method'),
            notes: any(named: 'notes'),
            treasuryAccountId: captureAny(named: 'treasuryAccountId'),
          ),
        ).captured.single
        as int?;
  }

  testWidgets('a deposit left on its box sends the box it was given', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await openAndPickBranchBox(tester);

    // Act
    final sent = await submitAndReadAccount(tester);

    // Assert
    expect(sent, 9);
  });

  testWidgets('switching «نوع الحركة» clears the account — a deposit box is not a withdrawal\'s', (
    tester,
  ) async {
    // Arrange
    await tester.pumpWidget(host());
    await openAndPickBranchBox(tester);

    // Act
    await choose<WalletAction>(
      tester,
      find.byType(AppDropdown<WalletAction>),
      WalletAction.withdrawal.label,
    );
    final sent = await submitAndReadAccount(tester);

    // Assert
    expect(sent, isNull);
  });

  testWidgets('switching the method clears the account too', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await openAndPickBranchBox(tester);

    // Act
    await choose<PaymentMethod>(
      tester,
      find.byType(AppDropdown<PaymentMethod>),
      PaymentMethod.bankTransfer.label,
    );
    final sent = await submitAndReadAccount(tester);

    // Assert
    expect(sent, isNull);
  });

  testWidgets('a refusal about the drawer is said under the account field, not in a toast', (
    tester,
  ) async {
    // Arrange
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
          message: 'الحساب معطَّل',
          statusCode: 422,
          fieldErrors: {
            'treasury_account_id': ['الحساب معطَّل'],
          },
        ),
      ),
    );
    await tester.pumpWidget(host());
    await openAndPickBranchBox(tester);

    // Act
    await tester.enterText(find.byType(AppTextField).first, '500');
    await tester.pump();
    await tester.ensureVisible(find.text('تسجيل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('تسجيل'));
    await tester.pumpAndSettle();
    final field = tester.widget<AppDropdown<AccountOption>>(
      find.byType(AppDropdown<AccountOption>),
    );
    final said = find.text('الحساب معطَّل').evaluate().length;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert
    expect(field.errorText, 'الحساب معطَّل');
    expect(said, 1);
  });
}
