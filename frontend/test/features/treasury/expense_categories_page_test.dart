import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/views/expense_categories_page.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTreasuryRepository extends Mock implements TreasuryRepository {}

/// «تصنيفات المصروفات» — شاشةٌ وحدها تحت «المالية» بعد أن كانت قسماً في آخر «إعدادات المالية».
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockTreasuryRepository repository;

  const carrierFee = ExpenseCategory(
    id: 1,
    name: 'رسوم شركة التوصيل',
    requiresEmployee: false,
    isActive: true,
    isSystem: true,
  );
  const rent = ExpenseCategory(
    id: 3,
    name: 'إيجار',
    requiresEmployee: false,
    isActive: true,
    isSystem: false,
  );

  setUp(() async {
    await sl.reset();
    repository = _MockTreasuryRepository();

    when(
      () => repository.expenseCategories(activeOnly: false),
    ).thenAnswer((_) async => const Right([carrierFee, rent]));

    sl
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
      home: ExpenseCategoriesPage(),
    ),
  );

  SwitchListTile tileOf(WidgetTester tester, String name) => tester.widget<SwitchListTile>(
    find.ancestor(of: find.text(name), matching: find.byType(SwitchListTile)),
  );

  testWidgets('every category is listed, the switched-off ones included', (tester) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تصنيفات المصروفات'), findsOneWidget);
    expect(find.text('رسوم شركة التوصيل'), findsOneWidget);
    expect(find.text('إيجار'), findsOneWidget);
    verify(() => repository.expenseCategories(activeOnly: false)).called(1);
  });

  testWidgets('a category the system relies on cannot be switched off', (tester) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(tileOf(tester, 'رسوم شركة التوصيل').onChanged, isNull);
    expect(tileOf(tester, 'إيجار').onChanged, isNotNull);
  });

  testWidgets('switching one off saves it, and the row follows without a reload', (tester) async {
    // Arrange
    when(
      () => repository.saveExpenseCategory(id: 3, name: 'إيجار', isActive: false),
    ).thenAnswer(
      (_) async => const Right(
        ExpenseCategory(
          id: 3,
          name: 'إيجار',
          requiresEmployee: false,
          isActive: false,
          isSystem: false,
        ),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('إيجار'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.saveExpenseCategory(id: 3, name: 'إيجار', isActive: false)).called(1);
    expect(tileOf(tester, 'إيجار').value, isFalse);
    verify(() => repository.expenseCategories(activeOnly: false)).called(1);
  });

  testWidgets('a new category lands at the foot of the list', (tester) async {
    // Arrange
    when(() => repository.saveExpenseCategory(name: 'صيانة')).thenAnswer(
      (_) async => const Right(
        ExpenseCategory(
          id: 9,
          name: 'صيانة',
          requiresEmployee: false,
          isActive: true,
          isSystem: false,
        ),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('تصنيف جديد'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'صيانة');
    await tester.pump();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Assert
    verify(() => repository.saveExpenseCategory(name: 'صيانة')).called(1);
    expect(find.text('صيانة'), findsOneWidget);
  });
}
