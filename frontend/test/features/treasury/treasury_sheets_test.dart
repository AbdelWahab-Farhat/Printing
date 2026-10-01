import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_operation_sheet.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// نموذجا العملية والحساب — الحقول وحدها بلا سطور شرح، ورفضُ الخادم تحت حقله، ومفتاحُ الطلب
/// نفسه مع كل محاولة.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository repository;

  setUp(() async {
    await sl.reset();
    repository = MockTreasuryRepository();
    sl.registerLazySingleton(() => GetExpenseCategories(repository));
  });

  tearDown(() => sl.reset());

  /// شاشةٌ بزرٍّ يفتح [open].
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

  Future<void> tapInSheet(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  group('نموذج العملية', () {
    testWidgets('a count asks what was found, with no sentence under the box', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(
          (context) => showTreasuryOperationSheet(
            context: context,
            kind: OperationKind.adjustment,
            accounts: const [cashBox],
            account: cashBox,
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
                }) async => null,
          ),
        ),
      );

      // Act
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Assert — رقم النظام على صفّ الحساب في القائمة أصلاً.
      expect(find.text('الرصيد المعدود فعلاً'), findsOneWidget);
      expect(find.textContaining('يُسجَّل الفرق وحده'), findsNothing);
    });

    testWidgets('a refusal lands under its field, and a retry carries the same token', (
      tester,
    ) async {
      // Arrange
      final tokens = <String?>[];
      await tester.pumpWidget(
        host(
          (context) => showTreasuryOperationSheet(
            context: context,
            kind: OperationKind.withdrawal,
            accounts: const [cashBox],
            account: cashBox,
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
                }) async {
                  tokens.add(clientToken);

                  return const Failure.server(
                    message: 'الرصيد لا يكفي',
                    statusCode: 422,
                    fieldErrors: {
                      'amount': ['الرصيد لا يكفي'],
                    },
                  );
                },
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(AppTextField).first, '900');
      await tester.enterText(find.byType(AppTextField).last, 'نثريات');
      await tester.pump();

      // Act
      await tapInSheet(tester, find.text('تسجيل سحب'));
      await tapInSheet(tester, find.text('تسجيل سحب'));
      final amount = tester.widget<AppTextField>(find.byType(AppTextField).first);

      // Assert — بلا توست: الرفض الوحيد له مربّعه.
      expect(amount.errorText, 'الرصيد لا يكفي');
      expect(find.text('الرصيد لا يكفي'), findsOneWidget);
      expect(tokens, hasLength(2));
      expect(tokens.first, isNotNull);
      expect(tokens.first, tokens.last);
    });

    testWidgets('categories that fail to load say so, and «إعادة المحاولة» asks again', (
      tester,
    ) async {
      // Arrange
      var calls = 0;
      when(() => repository.expenseCategories()).thenAnswer(
        (_) async => calls++ == 0
            ? const Left(Failure.network(message: FailureMessages.noConnection))
            : const Right([
                ExpenseCategory(
                  id: 3,
                  name: 'إيجار',
                  requiresEmployee: false,
                  isActive: true,
                  isSystem: false,
                ),
              ]),
      );
      await tester.pumpWidget(
        host(
          (context) => showTreasuryOperationSheet(
            context: context,
            kind: OperationKind.expense,
            accounts: const [cashBox],
            account: cashBox,
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
                }) async => null,
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      final failedOnScreen = find.text(FailureMessages.noConnection).evaluate().length;

      // Act
      await tapInSheet(tester, find.text('إعادة المحاولة'));
      await tester.tap(find.byType(AppDropdown<ExpenseCategory>));
      await tester.pumpAndSettle();

      // Assert
      expect(failedOnScreen, 1);
      expect(find.text('إيجار'), findsWidgets);
    });
  });

  group('نموذج الحساب', () {
    const withNotes = TreasuryAccount(
      id: 5,
      name: 'مصرف علي',
      kind: AccountKind.bank,
      kindLabel: 'مصرف',
      isDefault: false,
      isActive: true,
      isSystem: false,
      isSpendable: true,
      notes: 'حساب علي الشخصي',
    );

    Widget sheetFor(TreasuryAccount account, void Function(String?) onNotes) => host(
      (context) => showTreasuryAccountSheet(
        context: context,
        account: account,
        onSubmit: ({required name, kind, isDefault, isActive, holderUserId, notes}) async {
          onNotes(notes);

          return null;
        },
      ),
    );

    testWidgets('clearing an account\'s notes sends them empty, so the server clears them', (
      tester,
    ) async {
      // Arrange
      String? sent = 'لم يُرسل شيء';
      await tester.pumpWidget(sheetFor(withNotes, (notes) => sent = notes));
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(find.byType(AppTextField).last, '');
      await tester.pump();
      await tapInSheet(tester, find.text('حفظ'));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Assert
      expect(sent, '');
    });

    testWidgets('notes nobody touched are not sent at all', (tester) async {
      // Arrange
      String? sent = 'لم يُرسل شيء';
      await tester.pumpWidget(sheetFor(alisBank, (notes) => sent = notes));
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Act
      await tapInSheet(tester, find.text('حفظ'));
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Assert
      expect(sent, isNull);
    });

    testWidgets('no switch and no fixed kind carries a sentence under it', (tester) async {
      // Arrange
      await tester.pumpWidget(sheetFor(withNotes, (_) {}));

      // Act
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      final subtitled = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .where((tile) => tile.subtitle != null)
          .length;

      // Assert
      expect(subtitled, 0);
      expect(find.text('نوع الحساب لا يتغيّر بعد إنشائه'), findsNothing);
      expect(find.text('مصرف'), findsOneWidget);
    });
  });
}
