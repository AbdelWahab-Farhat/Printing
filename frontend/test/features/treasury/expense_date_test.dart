import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_operation_sheet.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// The expense's own day, and the warning when it falls before the account's latest count.
///
/// Arrange - Act - Assert throughout.
const _warning = 'جُرد «الكاش الرئيسي» في 2026-11-05 23:59، وهذا المصروف بتاريخٍ قبله.';

/// One send from the sheet, as the screen received it.
typedef _Sent = ({String? clientToken, String? occurredAt, bool? confirmBeforeCount});

void main() {
  late MockTreasuryRepository repository;

  setUp(() async {
    await sl.reset();
    repository = MockTreasuryRepository();
    when(() => repository.expenseCategories()).thenAnswer(
      (_) async => const Right([
        ExpenseCategory(
          id: 3,
          name: 'وقود',
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

  /// Opens the sheet for [kind]; every send lands in the returned list. [warnUntilConfirmed]
  /// answers like the server for an expense dated before the latest count.
  Future<List<_Sent>> open(
    WidgetTester tester, {
    OperationKind kind = OperationKind.expense,
    bool warnUntilConfirmed = false,
  }) async {
    final sent = <_Sent>[];

    await tester.pumpWidget(
      host(
        (context) => showTreasuryOperationSheet(
          context: context,
          kind: kind,
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
                rate,
                occurredAt,
                confirmBeforeCount,
              }) async {
                sent.add((
                  clientToken: clientToken,
                  occurredAt: occurredAt,
                  confirmBeforeCount: confirmBeforeCount,
                ));

                if (warnUntilConfirmed && confirmBeforeCount != true) {
                  return const Failure.server(
                    message: _warning,
                    statusCode: 422,
                    fieldErrors: {
                      'confirm_before_count': [_warning],
                    },
                  );
                }

                return null;
              },
        ),
      ),
    );
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    return sent;
  }

  Future<void> fillAndSend(WidgetTester tester) async {
    await tester.tap(find.byType(AppDropdown<ExpenseCategory>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('وقود').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(AppTextField).first, '300');
    await tester.pump();
    final button = find.text('تسجيل مصروف');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  String day(DateTime at) =>
      '${at.year.toString().padLeft(4, '0')}-${at.month.toString().padLeft(2, '0')}-'
      '${at.day.toString().padLeft(2, '0')}';

  testWidgets('an expense shows its date, opens on today, and today sends no date', (tester) async {
    // Arrange
    final sent = await open(tester);

    // Act
    final row = find.byKey(const ValueKey('expense-date'));
    final shown = find
        .descendant(of: row, matching: find.text(day(DateTime.now())))
        .evaluate()
        .length;
    await fillAndSend(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert — the server stamps the moment it is written.
    expect(shown, 1);
    expect(sent, hasLength(1));
    expect(sent.single.occurredAt, isNull);
    expect(sent.single.confirmBeforeCount, isNull);
  });

  testWidgets('a deposit asks no date', (tester) async {
    // Arrange
    await open(tester, kind: OperationKind.deposit);

    // Act
    final row = find.byKey(const ValueKey('expense-date'));

    // Assert
    expect(row, findsNothing);
  });

  testWidgets('before the latest count it asks first, and «سجّل رغم ذلك» sends it again', (
    tester,
  ) async {
    // Arrange
    final sent = await open(tester, warnUntilConfirmed: true);
    await fillAndSend(tester);
    final warned = find.text(_warning).evaluate().length;

    // Act
    await tester.tap(find.byKey(const ValueKey('confirm-before-count')));
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert — the same token, so a lost reply cannot write it twice; the sheet closed.
    expect(warned, 1);
    expect(sent, hasLength(2));
    expect(sent.first.confirmBeforeCount, isNull);
    expect(sent.last.confirmBeforeCount, isTrue);
    expect(sent.last.clientToken, sent.first.clientToken);
    expect(find.text('تسجيل مصروف'), findsNothing);
  });

  testWidgets('«تراجع» writes nothing and leaves the sheet open, with no error left behind', (
    tester,
  ) async {
    // Arrange
    final sent = await open(tester, warnUntilConfirmed: true);
    await fillAndSend(tester);

    // Act
    await tester.tap(find.text('تراجع'));
    await tester.pumpAndSettle();

    // Assert
    expect(sent, hasLength(1));
    expect(find.text('تسجيل مصروف'), findsOneWidget);
    expect(find.text(_warning), findsNothing);
  });
}
