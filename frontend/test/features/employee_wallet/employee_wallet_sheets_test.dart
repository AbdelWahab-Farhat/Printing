import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/employee_wallet/models/employee_wallet_models.dart';
import 'package:dayaa/features/employee_wallet/presentation/viewmodel/credit_categories_cubit.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_deposit_sheet.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/employee_withdraw_sheet.dart';
import 'package:dayaa/features/employee_wallet/presentation/widgets/reverse_entry_sheet.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTreasury extends Mock implements TreasuryRepository {}

/// أوراق المحفظة، كما رُسمت على Claude Design ووافق عليها صاحب العمل ٢٠٢٦-١١-٠٦.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockTreasury treasury;

  const salary = ExpenseCategory(
    id: 1,
    name: 'رواتب',
    code: 'salary',
    requiresEmployee: false,
    isActive: true,
    isSystem: true,
  );
  const bonus = ExpenseCategory(
    id: 3,
    name: 'مكافآت',
    requiresEmployee: false,
    isActive: true,
    isSystem: false,
  );

  Finder field(String label) => find.widgetWithText(TextFormField, label);

  String typedIn(WidgetTester tester, String label) =>
      tester.widget<TextFormField>(field(label)).controller!.text;

  Finder button(String label) => find.widgetWithText(AppButton, label);

  /// يفتح الورقة من زرٍّ، ويحفظ ما أعادته حين تُغلق.
  Future<void> host(WidgetTester tester, Future<void> Function(BuildContext context) open) async {
    tester.view
      ..physicalSize = const Size(1290, 2796)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilInit(
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
              builder: (context) => TextButton(
                onPressed: () => open(context),
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    treasury = _MockTreasury();
    when(
      () => treasury.expenseCategories(activeOnly: true),
    ).thenAnswer((_) async => const Right([bonus, salary]));

    sl.registerFactory<CreditCategoriesCubit>(
      () => CreditCategoriesCubit(getCategories: GetExpenseCategories(treasury)),
    );
  });

  tearDown(() => sl.reset());

  group('ورقة الإيداع', () {
    late List<EmployeeMoneyDraft> money;
    late List<EmployeeCreditDraft> credits;
    late EmployeeDepositKind? closedWith;
    late Failure? refusal;

    Future<void> open(
      WidgetTester tester, {
      bool mayReceiveMoney = true,
      bool mayCredit = true,
      String? wage = '2500.00',
    }) async {
      money = [];
      credits = [];
      closedWith = null;
      refusal = null;

      await host(tester, (context) async {
        closedWith = await showEmployeeDepositSheet(
          context: context,
          mayReceiveMoney: mayReceiveMoney,
          mayCredit: mayCredit,
          salary: wage,
          onMoney: (draft) async {
            money.add(draft);

            return refusal;
          },
          onCredit: (draft) async {
            credits.add(draft);

            return refusal;
          },
        );
      });
    }

    testWidgets('زرٌّ واحد، والورقة تسأل أولاً: مال استلمناه أم مستحق', (tester) async {
      // Arrange & Act
      await open(tester);

      // Assert
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(SegmentedButton<EmployeeDepositKind>), findsOneWidget);
      expect(find.text('مال استلمناه'), findsOneWidget);
      expect(find.text('مستحق'), findsOneWidget);
      expect(find.text('الطريقة'), findsOneWidget);
      expect(find.text('التصنيف'), findsNothing);
    });

    testWidgets('من يملك استلام المال وحده لا يرى السؤال', (tester) async {
      // Arrange & Act
      await open(tester, mayCredit: false);

      // Assert
      expect(find.byType(SegmentedButton<EmployeeDepositKind>), findsNothing);
      expect(find.text('الطريقة'), findsOneWidget);
      verifyNever(() => treasury.expenseCategories(activeOnly: true));
    });

    testWidgets('من يملك المستحق وحده لا يرى السؤال ولا الطريقة', (tester) async {
      // Arrange & Act
      await open(tester, mayReceiveMoney: false);

      // Assert
      expect(find.byType(SegmentedButton<EmployeeDepositKind>), findsNothing);
      expect(find.text('التصنيف'), findsOneWidget);
      expect(find.text('الطريقة'), findsNothing);
      expect(button('تسجيل المستحق'), findsOneWidget);
    });

    testWidgets('«مستحق» يبدأ بـ«رواتب» ويكتب راتب الموظف', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.tap(find.text('مستحق'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('رواتب'), findsOneWidget);
      expect(typedIn(tester, 'المبلغ'), '2500');
    });

    testWidgets('المبلغ المقترح يتغيّر قبل الحفظ', (tester) async {
      // Arrange
      await open(tester, mayReceiveMoney: false);

      // Act
      await tester.enterText(field('المبلغ'), '2000');
      await tester.pump();
      await tester.tap(button('تسجيل المستحق'));
      await tester.pumpAndSettle();

      // Assert
      expect(credits.single.amount, '2000');
      expect(credits.single.categoryId, 1);
      expect(closedWith, EmployeeDepositKind.credit);
    });

    testWidgets('تصنيفٌ آخر يفرّغ المبلغ', (tester) async {
      // Arrange
      await open(tester, mayReceiveMoney: false);

      // Act
      await tester.tap(find.text('رواتب'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('مكافآت').last);
      await tester.pumpAndSettle();

      // Assert
      expect(typedIn(tester, 'المبلغ'), isEmpty);
    });

    testWidgets('من لا يرى الرواتب يكتب المبلغ بنفسه', (tester) async {
      // Arrange
      await open(tester, mayReceiveMoney: false, wage: null);

      // Act
      await tester.tap(button('تسجيل المستحق'));
      await tester.pumpAndSettle();

      // Assert
      expect(typedIn(tester, 'المبلغ'), isEmpty);
      expect(find.text('المبلغ مطلوب'), findsOneWidget);
      expect(credits, isEmpty);
    });

    testWidgets('فشل قراءة التصنيفات يُقال، وإعادة المحاولة تعيده', (tester) async {
      // Arrange
      var calls = 0;
      when(() => treasury.expenseCategories(activeOnly: true)).thenAnswer(
        (_) async => calls++ == 0
            ? const Left(Failure.network(message: FailureMessages.noConnection))
            : const Right([salary]),
      );
      await open(tester, mayReceiveMoney: false);

      // Act
      expect(find.text(FailureMessages.noConnection), findsOneWidget);
      await tester.tap(button('إعادة المحاولة'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text(FailureMessages.noConnection), findsNothing);
      expect(find.text('رواتب'), findsOneWidget);
    });

    testWidgets('بلا تصنيفٍ لا يُرسل شيء، ولو فشلت قراءتها', (tester) async {
      // Arrange
      when(() => treasury.expenseCategories(activeOnly: true)).thenAnswer(
        (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
      );
      await open(tester, mayReceiveMoney: false);
      await tester.enterText(field('المبلغ'), '100');
      await tester.pump();

      // Act
      await tester.tap(button('تسجيل المستحق'));
      await tester.pumpAndSettle();

      // Assert
      expect(tester.takeException(), isNull);
      expect(credits, isEmpty);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('المال يصل بأرقام غربية، والورقة تُغلق على القبول', (tester) async {
      // Arrange
      await open(tester, mayCredit: false);

      // Act
      await tester.enterText(field('المبلغ'), '٣٠٠');
      await tester.enterText(field('رقم المرجع'), 'R-7');
      await tester.pump();
      await tester.tap(button('إيداع'));
      await tester.pumpAndSettle();

      // Assert
      expect(money.single.amount, '300');
      expect(money.single.method, EmployeeWalletMethod.cash);
      expect(money.single.reference, 'R-7');
      expect(money.single.treasuryAccountId, isNull);
      expect(closedWith, EmployeeDepositKind.money);
      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('الحوالة بلا واصل لا تُرسل', (tester) async {
      // Arrange
      await open(tester, mayCredit: false);
      await tester.enterText(field('المبلغ'), '300');
      await tester.tap(find.text('كاش'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حوالة').last);
      await tester.pumpAndSettle();

      // Act
      await tester.tap(button('إيداع'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('الواصل — مطلوب مع الحوالة'), findsOneWidget);
      expect(money, isEmpty);
      expect(find.byType(BottomSheet), findsOneWidget);
    });

    testWidgets('رفض الخادم يُبقي الورقة مفتوحة وما كُتب فيها', (tester) async {
      // Arrange
      await open(tester, mayCredit: false);
      refusal = const Failure.server(message: 'التاريخ قبل آخر جرد للحساب');
      await tester.enterText(field('المبلغ'), '300');
      await tester.pump();

      // Act
      await tester.tap(button('إيداع'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Assert
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(typedIn(tester, 'المبلغ'), '300');
      expect(find.text('التاريخ قبل آخر جرد للحساب'), findsOneWidget);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    });
  });

  group('ورقة السحب', () {
    late List<EmployeeMoneyDraft> sent;
    late bool? closedWith;

    Future<void> open(WidgetTester tester, {String balance = '1500.00'}) async {
      sent = [];
      closedWith = null;

      await host(tester, (context) async {
        closedWith = await showEmployeeWithdrawSheet(
          context: context,
          balance: balance,
          onSubmit: (draft) async {
            sent.add(draft);

            return null;
          },
        );
      });
    }

    testWidgets('«الرصيد بعد السحب» يتبع كل حرف', (tester) async {
      // Arrange
      await open(tester);
      expect(find.text('الرصيد الحالي'), findsOneWidget);
      expect(find.text('1,500 د.ل'), findsOneWidget);

      // Act
      await tester.enterText(field('المبلغ'), '500');
      await tester.pump();

      // Assert
      expect(find.text('الرصيد بعد السحب'), findsOneWidget);
      expect(find.text('1,000 د.ل'), findsOneWidget);
    });

    testWidgets('فوق رصيد المحفظة يُرفض قبل الإرسال', (tester) async {
      // Arrange
      await open(tester);
      await tester.enterText(field('المبلغ'), '1800');
      await tester.pump();

      // Act
      await tester.tap(button('سحب'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('في المحفظة 1,500 د.ل فقط'), findsOneWidget);
      expect(sent, isEmpty);
    });

    testWidgets('يصرف الرصيد كله', (tester) async {
      // Arrange
      await open(tester);
      await tester.enterText(field('المبلغ'), '1500');
      await tester.pump();

      // Act
      await tester.tap(button('سحب'));
      await tester.pumpAndSettle();

      // Assert
      expect(sent.single.amount, '1500');
      expect(closedWith, isTrue);
    });

    testWidgets('الطرق الأربع كلها معروضة', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.tap(find.text('كاش'));
      await tester.pumpAndSettle();

      // Assert
      for (final method in EmployeeWalletMethod.values) {
        expect(find.text(method.label), findsWidgets);
      }
    });
  });

  group('ورقة إلغاء الحركة', () {
    late String? reason;

    Future<void> open(WidgetTester tester) async {
      reason = null;

      await host(tester, (context) async {
        reason = await askForReversalReason(context, title: 'إلغاء «سحب»');
      });
    }

    testWidgets('ورقةٌ من الأسفل لا حوار', (tester) async {
      // Arrange & Act
      await open(tester);

      // Assert
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('إلغاء «سحب»'), findsOneWidget);
      expect(button('رجوع'), findsOneWidget);
    });

    testWidgets('السبب إجباري', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.tap(button('إلغاء الحركة'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('السبب مطلوب'), findsOneWidget);
      expect(reason, isNull);
    });

    testWidgets('يعود بالسبب مقصوصاً', (tester) async {
      // Arrange
      await open(tester);
      await tester.enterText(field('السبب'), '  كُتبت لموظفٍ آخر  ');
      await tester.pump();

      // Act
      await tester.tap(button('إلغاء الحركة'));
      await tester.pumpAndSettle();

      // Assert
      expect(reason, 'كُتبت لموظفٍ آخر');
    });

    testWidgets('«رجوع» يترك الحركة كما هي', (tester) async {
      // Arrange
      await open(tester);

      // Act
      await tester.tap(button('رجوع'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.byType(BottomSheet), findsNothing);
      expect(reason, isNull);
    });
  });
}
