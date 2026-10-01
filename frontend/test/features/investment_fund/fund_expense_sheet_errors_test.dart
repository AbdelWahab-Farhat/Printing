import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/investment_fund_cubit.dart';
import 'package:dayaa/features/investment_fund/presentation/widgets/fund_expense_sheet.dart';
import 'package:dayaa/features/investment_fund/repositories/investment_fund_repository.dart';
import 'package:dayaa/features/investment_fund/usecases/investment_fund_usecases.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFundRepository extends Mock implements InvestmentFundRepository {}

/// «مصروف على الصندوق» — رفضُ الخادم يُعلَّق تحت حقله، ولا يُقال مرةً ثانية في توست.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockFundRepository repository;
  late InvestmentFundCubit cubit;

  setUp(() async {
    await sl.reset();
    repository = _MockFundRepository();
    cubit = InvestmentFundCubit(
      getStanding: GetFundStanding(repository),
      openPeriod: OpenFundPeriod(repository),
      closePeriod: CloseFundPeriod(repository),
      deposit: DepositCapital(repository),
      withdraw: WithdrawCapital(repository),
      recordExpense: RecordFundExpense(repository),
    );
  });

  tearDown(() => cubit.close());

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
              onPressed: () => showFundExpenseSheet(context: context, cubit: cubit),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );

  void refuseWith(Map<String, List<String>> errors) => when(
    () => repository.recordExpense(
      kind: any(named: 'kind'),
      name: any(named: 'name'),
      amount: any(named: 'amount'),
      incurredOn: any(named: 'incurredOn'),
      notes: any(named: 'notes'),
      treasuryAccountId: any(named: 'treasuryAccountId'),
    ),
  ).thenAnswer(
    (_) async => Left(
      Failure.server(message: errors.values.first.first, statusCode: 422, fieldErrors: errors),
    ),
  );

  Future<void> fillAndSubmit(WidgetTester tester) async {
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(AppTextField).at(0), 'شحن حاوية');
    await tester.enterText(find.byType(AppTextField).at(1), '300');
    await tester.pump();
    final button = find.text('تسجيل المصروف');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('a locked date is said under the date, once', (tester) async {
    // Arrange
    refuseWith({
      'incurred_on': ['التاريخ داخل فترةٍ مقفلة'],
    });
    await tester.pumpWidget(host());

    // Act
    await fillAndSubmit(tester);
    final said = find.text('التاريخ داخل فترةٍ مقفلة').evaluate().length;
    final underTheDate = find
        .widgetWithText(TreasuryFieldError, 'التاريخ داخل فترةٍ مقفلة')
        .evaluate()
        .length;
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert — تحت التاريخ ولا مكان غيره: لا توست يعيده.
    expect(underTheDate, 1);
    expect(said, 1);
  });

  testWidgets('an amount the drawer cannot cover is said under the amount', (tester) async {
    // Arrange
    refuseWith({
      'amount': ['الرصيد لا يكفي'],
    });
    await tester.pumpWidget(host());

    // Act
    await fillAndSubmit(tester);
    final box = tester.widget<AppTextField>(find.byType(AppTextField).at(1));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert
    expect(box.errorText, 'الرصيد لا يكفي');
  });
}
