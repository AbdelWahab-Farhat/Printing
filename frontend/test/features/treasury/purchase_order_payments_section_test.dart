import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/presentation/widgets/purchase_order_payments_section.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// «المدفوع للمورد» على أمر الشراء — TREASURY-DESIGN §٨.
///
/// Arrange - Act - Assert throughout.
void main() {
  late MockTreasuryRepository repository;

  const paid = VendorPayment(
    id: 5,
    type: 'payment',
    typeLabel: 'دفعة',
    amount: '400.00',
    isReversed: false,
    isReversible: true,
    methodLabel: 'حوالة',
    accountName: 'المصرف',
  );

  const summary = PurchaseOrderPayments(
    total: '1000.00',
    paid: '400.00',
    remaining: '600.00',
    predatesTreasury: true,
    payments: [paid],
  );

  const options = AccountOptions(
    accounts: [
      AccountOption(id: 2, name: 'المصرف', kindLabel: 'مصرف', isDefault: true),
      AccountOption(id: 5, name: 'مصرف علي', kindLabel: 'مصرف', isDefault: false),
    ],
    suggestedId: 2,
    suggestedName: 'المصرف',
  );

  const recorded = VendorPayment(
    id: 6,
    type: 'payment',
    typeLabel: 'دفعة',
    amount: '600.00',
    isReversed: false,
    isReversible: true,
  );

  setUp(() async {
    await sl.reset();
    repository = MockTreasuryRepository();

    when(() => repository.purchaseOrderPayments(4)).thenAnswer((_) async => const Right(summary));
    when(
      () => repository.accountOptions(
        method: any(named: 'method'),
        incoming: any(named: 'incoming'),
      ),
    ).thenAnswer((_) async => const Right(options));

    sl
      ..registerSingleton<Session>(
        Session()..adopt(
          const AuthUser(
            id: 1,
            name: 'عبدالوهاب',
            phone: '0911234567',
            permissions: [
              'vendors.payments.view',
              'vendors.payments.record',
              'vendors.payments.reverse',
            ],
          ),
        ),
      )
      ..registerLazySingleton(() => GetPurchaseOrderPayments(repository))
      ..registerLazySingleton(() => PayVendor(repository))
      ..registerLazySingleton(() => ReverseVendorPayment(repository))
      ..registerLazySingleton(() => GetAccountOptions(repository))
      ..registerLazySingleton(() => GetTreasuryAccounts(repository));
  });

  tearDown(() => sl.reset());

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
      home: Scaffold(
        body: SingleChildScrollView(
          child: PurchaseOrderPaymentsSection(purchaseOrderId: 4, vendorId: 9),
        ),
      ),
    ),
  );

  void answerPayment(Either<Failure, VendorPayment> answer) => when(
    () => repository.payVendor(
      vendorId: any(named: 'vendorId'),
      purchaseOrderId: any(named: 'purchaseOrderId'),
      amount: any(named: 'amount'),
      method: any(named: 'method'),
      accountId: any(named: 'accountId'),
      clientToken: any(named: 'clientToken'),
    ),
  ).thenAnswer((_) async => answer);

  List<Object?> sentPayments({required String field}) => verify(
    () => repository.payVendor(
      vendorId: any(named: 'vendorId'),
      purchaseOrderId: any(named: 'purchaseOrderId'),
      amount: any(named: 'amount'),
      method: any(named: 'method'),
      accountId: field == 'accountId' ? captureAny(named: 'accountId') : any(named: 'accountId'),
      clientToken: field == 'clientToken'
          ? captureAny(named: 'clientToken')
          : any(named: 'clientToken'),
    ),
  ).captured;

  Future<void> choose(WidgetTester tester, Finder field, String label) async {
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> openPayForm(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.text('دفعة للمورد'));
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester) async {
    final button = find.text('تسجيل الدفعة');
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('switching the method clears the drawer picked for the old one', (tester) async {
    // Arrange
    answerPayment(const Right(recorded));
    await openPayForm(tester);
    await choose(tester, find.byType(AppDropdown<AccountOption>), 'مصرف علي');

    // Act
    await choose(tester, find.byType(AppDropdown<PaymentMethod>), PaymentMethod.cash.label);
    await submit(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert
    expect(sentPayments(field: 'accountId'), [null]);
  });

  testWidgets('a retry after a dropped connection carries the same client token', (
    tester,
  ) async {
    // Arrange
    answerPayment(const Left(Failure.network(message: FailureMessages.timeout)));
    await openPayForm(tester);
    await submit(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Act
    answerPayment(const Right(recorded));
    await submit(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert — ورقةٌ واحدة، مفتاحٌ واحد، ومحاولتان.
    final tokens = sentPayments(field: 'clientToken');
    expect(tokens, hasLength(2));
    expect(tokens.first, isNotEmpty);
    expect(tokens.first, tokens.last);
  });

  testWidgets('a recorded payment lands on top, and the remainder follows it', (tester) async {
    // Arrange
    answerPayment(const Right(recorded));
    await openPayForm(tester);

    // Act
    await submit(tester);
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert — بلا قراءةٍ ثانية للقسم.
    expect(find.text('−600 د.ل'), findsOneWidget);
    expect(find.text('0 د.ل'), findsOneWidget);
    verify(() => repository.purchaseOrderPayments(4)).called(1);
  });

  testWidgets('reversing lives behind «...», asks a reason, and strikes the row', (tester) async {
    // Arrange
    when(
      () => repository.reverseVendorPayment(vendorId: 9, paymentId: 5, reason: 'سُجّلت مرتين'),
    ).thenAnswer(
      (_) async => const Right(
        VendorPayment(
          id: 7,
          type: 'reversal',
          typeLabel: 'عكس دفعة',
          amount: '400.00',
          isReversed: false,
          isReversible: false,
          reversesPaymentId: 5,
        ),
      ),
    );
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byTooltip('خيارات الدفعة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('عكس الدفعة').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(AppTextField), 'سُجّلت مرتين');
    await tester.pump();
    await tester.tap(find.widgetWithText(TextButton, 'عكس الدفعة'));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    // Assert
    final original = tester.widget<Text>(find.text('دفعة'));
    expect(find.text('عكس دفعة'), findsOneWidget);
    expect(original.style?.decoration, TextDecoration.lineThrough);
    expect(find.byTooltip('خيارات الدفعة'), findsNothing);
  });

  testWidgets('an order from before the treasury carries no sentence about it', (tester) async {
    // Arrange
    final section = host();

    // Act
    await tester.pumpWidget(section);
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('سابق لنظام الحسابات'), findsNothing);
  });
}
