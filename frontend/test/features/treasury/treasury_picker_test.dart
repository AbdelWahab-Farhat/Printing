import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/presentation/widgets/transition_field_input.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_picker.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// منتقي «الحساب» على نماذج الدفع: يسأل من جديد حين تتغيّر الطريقة، ويُسقط جواباً متأخراً،
/// ويقول فشله تحت الحقل بزرّ «إعادة المحاولة». TREASURY-DESIGN §٥.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository repository;

  const cashOptions = AccountOptions(
    accounts: [
      AccountOption(id: 1, name: 'الخزنة الرئيسية', kindLabel: 'خزنة', isDefault: true),
      AccountOption(id: 9, name: 'خزنة فرع مصراتة', kindLabel: 'خزنة', isDefault: false),
    ],
    suggestedId: 1,
    suggestedName: 'الخزنة الرئيسية',
  );

  const bankOptions = AccountOptions(
    accounts: [
      AccountOption(id: 2, name: 'المصرف', kindLabel: 'مصرف', isDefault: true),
      AccountOption(id: 7, name: 'مصرف علي', kindLabel: 'مصرف', isDefault: false),
    ],
    suggestedId: 7,
    suggestedName: 'مصرف علي',
  );

  setUp(() async {
    await sl.reset();
    repository = MockTreasuryRepository();
    sl
      ..registerLazySingleton<GetAccountOptions>(() => GetAccountOptions(repository))
      ..registerLazySingleton<GetTreasuryAccounts>(() => GetTreasuryAccounts(repository));
  });

  tearDown(() => sl.reset());

  Widget host(Widget child) => ScreenUtilInit(
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
        body: Directionality(
          textDirection: TextDirection.rtl,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  );

  /// المنتقي على طريقةٍ يغيّرها [method].
  Widget pickerFor(ValueNotifier<String> method) => host(
    ValueListenableBuilder<String>(
      valueListenable: method,
      builder: (context, current, _) =>
          TreasuryAccountPicker(method: current, value: null, onChanged: (_) {}),
    ),
  );

  testWidgets('it asks again when the method changes, and draws the new answer', (tester) async {
    // Arrange
    when(
      () => repository.accountOptions(method: 'cash', incoming: true),
    ).thenAnswer((_) async => const Right(cashOptions));
    when(
      () => repository.accountOptions(method: 'bank_transfer', incoming: true),
    ).thenAnswer((_) async => const Right(bankOptions));
    final method = ValueNotifier('cash');
    addTearDown(method.dispose);
    await tester.pumpWidget(pickerFor(method));
    await tester.pumpAndSettle();

    // Act
    method.value = 'bank_transfer';
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تلقائي — مصرف علي'), findsOneWidget);
    expect(find.text('تلقائي — الخزنة الرئيسية'), findsNothing);
    verify(() => repository.accountOptions(method: 'bank_transfer', incoming: true)).called(1);
  });

  testWidgets('a late answer to the old method is dropped', (tester) async {
    // Arrange — جوابُ الكاش ما زال في الطريق حين يصل جواب المصرف.
    final slowCash = Completer<Either<Failure, AccountOptions>>();
    when(
      () => repository.accountOptions(method: 'cash', incoming: true),
    ).thenAnswer((_) => slowCash.future);
    when(
      () => repository.accountOptions(method: 'bank_transfer', incoming: true),
    ).thenAnswer((_) async => const Right(bankOptions));
    final method = ValueNotifier('cash');
    addTearDown(method.dispose);
    await tester.pumpWidget(pickerFor(method));
    await tester.pump();
    method.value = 'bank_transfer';
    await tester.pumpAndSettle();

    // Act
    slowCash.complete(const Right(cashOptions));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تلقائي — مصرف علي'), findsOneWidget);
    expect(find.text('تلقائي — الخزنة الرئيسية'), findsNothing);
  });

  testWidgets('a failure is said under the field, and «إعادة المحاولة» asks again', (
    tester,
  ) async {
    // Arrange
    var calls = 0;
    when(() => repository.accountOptions(method: 'cash', incoming: false)).thenAnswer(
      (_) async => calls++ == 0
          ? const Left(Failure.network(message: FailureMessages.noConnection))
          : const Right(cashOptions),
    );
    await tester.pumpWidget(
      host(
        TreasuryAccountPicker(method: 'cash', incoming: false, value: null, onChanged: (_) {}),
      ),
    );
    await tester.pumpAndSettle();
    final failedOnScreen = find.text(FailureMessages.noConnection).evaluate().length;

    // Act
    await tester.tap(find.text('إعادة المحاولة'));
    await tester.pumpAndSettle();

    // Assert — والاسم يقول من أين خرج المال، بلا سطرٍ تحته.
    expect(failedOnScreen, 1);
    expect(find.text(FailureMessages.noConnection), findsNothing);
    expect(find.text('تلقائي — الخزنة الرئيسية'), findsOneWidget);
    expect(find.text('دُفع من'), findsOneWidget);
    expect(find.text('من أين خرج المال'), findsNothing);
  });

  testWidgets('a treasury refusal on the status screen is drawn under its account field', (
    tester,
  ) async {
    // Arrange
    const field = TransitionField(
      key: 'settlement_account_id',
      type: TransitionFieldType.treasuryAccount,
      label: 'استُلم المال في',
      options: [TransitionFieldOption(value: '2', label: 'المصرف')],
    );
    final input = TransitionFieldInput(
      field: field,
      value: null,
      customerId: 1,
      errorText: 'الحساب معطَّل',
      onChanged: (_) {},
    );

    // Act
    await tester.pumpWidget(host(input));
    await tester.pump();

    // Assert
    expect(find.text('الحساب معطَّل'), findsOneWidget);
  });
}
