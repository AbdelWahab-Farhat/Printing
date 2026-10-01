import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/widgets/record_payment_sheet.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../treasury/treasury_fixtures.dart';

class _NoPicker implements AttachmentPicker {
  @override
  Future<List<PickedFile>> pick(
    AttachmentSource source, {
    List<String> extensions = AttachmentPicker.defaultExtensions,
  }) async => const [];
}

/// «استُلم في» على نموذج الدفعة: الحساب المختار لطريقةٍ لا يسافر مع طريقةٍ أخرى.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository treasury;

  const options = AccountOptions(
    accounts: [
      AccountOption(id: 1, name: 'الخزنة الرئيسية', kindLabel: 'خزنة', isDefault: true),
      AccountOption(id: 9, name: 'خزنة فرع مصراتة', kindLabel: 'خزنة', isDefault: false),
    ],
    suggestedId: 1,
    suggestedName: 'الخزنة الرئيسية',
  );

  setUp(() async {
    await Injector.reset();
    treasury = MockTreasuryRepository();

    when(
      () => treasury.accountOptions(
        method: any(named: 'method'),
        incoming: any(named: 'incoming'),
        orderId: any(named: 'orderId'),
      ),
    ).thenAnswer((_) async => const Right(options));

    sl
      ..registerSingleton<AttachmentPicker>(_NoPicker())
      ..registerLazySingleton(() => GetAccountOptions(treasury))
      ..registerLazySingleton(() => GetTreasuryAccounts(treasury));
  });

  tearDown(Injector.reset);

  Widget host(void Function(PaymentDraft?) onClosed) => ScreenUtilInit(
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
              onPressed: () async {
                final draft = await showRecordPaymentSheet(
                  context: context,
                  direction: PaymentDirection.incoming,
                  remainingAmount: '450.00',
                  paidAmount: '0.00',
                  orderId: 12,
                );

                onClosed(draft);
              },
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> choose(WidgetTester tester, Finder field, String label) async {
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> save(WidgetTester tester) async {
    final button = find.text('تسجيل الدفعة');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('the box picked for cash travels with a cash payment', (tester) async {
    // Arrange
    PaymentDraft? draft;
    await tester.pumpWidget(host((closed) => draft = closed));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    await choose(tester, find.byType(AppDropdown<AccountOption>), 'خزنة فرع مصراتة');

    // Act
    await save(tester);

    // Assert
    expect(draft?.accountId, 9);
  });

  testWidgets('switching the method clears the account picked for the old one', (tester) async {
    // Arrange
    PaymentDraft? draft;
    await tester.pumpWidget(host((closed) => draft = closed));
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    await choose(tester, find.byType(AppDropdown<AccountOption>), 'خزنة فرع مصراتة');

    // Act — البطاقة لا تنزل في خزنة نقد.
    await choose(tester, find.byType(AppDropdown<PaymentMethod>), PaymentMethod.bankCard.label);
    await save(tester);

    // Assert
    expect(draft, isNotNull);
    expect(draft!.accountId, isNull);
  });
}
