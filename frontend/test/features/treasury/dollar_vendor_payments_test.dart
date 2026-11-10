import 'dart:convert';
import 'dart:typed_data';

import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/core/widgets/app_text_field.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/models/vendor_payment.dart';
import 'package:dayaa/features/treasury/presentation/widgets/purchase_order_payments_section.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository_impl.dart';
import 'package:dayaa/features/treasury/usecases/treasury_usecases.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'treasury_fixtures.dart';

/// Paying a vendor's dollar debt in the app — USD-ACCOUNTS.md §٦, phase 3. Each currency pays its
/// own: a dollar debt from a named dollar account, in dollars, no rate.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.answer);

  final Object? answer;
  Map<String, dynamic>? query;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    query = options.queryParameters;

    return ResponseBody.fromString(
      jsonEncode({'status': true, 'message': 'تم', 'data': answer}),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('what the server sends', () {
    test('a payment says its currency, and keeps it once reversed', () {
      // Act
      final payment = VendorPayment.fromJson({
        'id': 5,
        'type': 'payment',
        'type_label': 'دفعة',
        'amount': '600.00',
        'currency': 'USD',
        'is_reversible': true,
      });
      final older = VendorPayment.fromJson({'id': 6, 'type': 'payment', 'amount': '1.00'});

      // Assert
      expect(payment.currency, Currency.usd);
      expect(payment.markedReversed().currency, Currency.usd);
      expect(older.currency, Currency.lyd);
    });

    test('the vendor\'s dollar side carries the whole story in dollars', () {
      // Act
      final account = VendorAccount.fromJson({
        'summary': {'owed': '0.00'},
        'usd_summary': {
          'ordered': '1500.00',
          'opening_debt': '800.00',
          'paid': '1200.00',
          'credited': '100.00',
          'owed': '1000.00',
        },
        'usd_treasury_account_id': 31,
        'payments': <Object>[],
      });

      // Assert
      expect(account.dollars.ordered, '1500.00');
      expect(account.dollars.openingDebt, '800.00');
      expect(account.dollars.paid, '1200.00');
      expect(account.dollars.credited, '100.00');
      expect(account.dollarsOwed, '1000.00');
    });
  });

  group('what the app puts on the wire', () {
    TreasuryRepositoryImpl repositoryOver(_CapturingAdapter adapter) => TreasuryRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );

    test('the picker asks for dollar accounts by name, and dinars as it always has', () async {
      // Arrange
      final dollars = _CapturingAdapter({'accounts': <Object>[], 'suggested_id': null});
      final dinars = _CapturingAdapter({'accounts': <Object>[], 'suggested_id': 1});

      // Act
      final result = await repositoryOver(
        dollars,
      ).accountOptions(method: 'cash', incoming: false, currency: Currency.usd);
      await repositoryOver(dinars).accountOptions(method: 'cash', incoming: false);

      // Assert
      expect(dollars.query?['currency'], 'USD');
      expect(dinars.query?.containsKey('currency'), isFalse);
      expect(result.getOrElse(() => throw StateError('failed')).suggestedId, isNull);
    });
  });

  group('paying a dollar order', () {
    late MockTreasuryRepository repository;

    const dollarOrder = PurchaseOrderPayments(
      total: '1500.00',
      paid: '0.00',
      remaining: '1500.00',
      payableUpTo: '1500.00',
      predatesTreasury: false,
      payments: [],
      currency: Currency.usd,
    );

    const dollarDrawers = AccountOptions(
      accounts: [AccountOption(id: 21, name: 'خزنة الدولار', kindLabel: 'كاش', isDefault: false)],
      suggestedId: null,
    );

    setUp(() async {
      await sl.reset();
      repository = MockTreasuryRepository();

      when(
        () => repository.purchaseOrderPayments(4),
      ).thenAnswer((_) async => const Right(dollarOrder));
      when(
        () => repository.accountOptions(
          method: any(named: 'method'),
          incoming: any(named: 'incoming'),
          currency: Currency.usd,
        ),
      ).thenAnswer((_) async => const Right(dollarDrawers));
      when(
        () => repository.payVendor(
          vendorId: any(named: 'vendorId'),
          purchaseOrderId: any(named: 'purchaseOrderId'),
          amount: any(named: 'amount'),
          method: any(named: 'method'),
          accountId: any(named: 'accountId'),
          clientToken: any(named: 'clientToken'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          VendorPayment(
            id: 6,
            type: 'payment',
            typeLabel: 'دفعة',
            amount: '600.00',
            isReversed: false,
            isReversible: true,
            currency: Currency.usd,
          ),
        ),
      );

      sl
        ..registerSingleton<Session>(
          Session()..adopt(
            const AuthUser(
              id: 1,
              name: 'عبدالوهاب',
              phone: '0911234567',
              permissions: ['vendors.payments.view', 'vendors.payments.record'],
            ),
          ),
        )
        ..registerLazySingleton(() => GetPurchaseOrderPayments(repository))
        ..registerLazySingleton(() => PayVendor(repository))
        ..registerLazySingleton(() => ReverseVendorPayment(repository))
        ..registerLazySingleton(() => CreditVendor(repository))
        ..registerLazySingleton(() => CountOldOrderAsDebt(repository))
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

    testWidgets('the order\'s figures are dollars, and it may be paid and credited', (
      tester,
    ) async {
      // Act
      await tester.pumpWidget(host());
      await tester.pumpAndSettle();

      // Assert
      expect(find.textContaining(r'$1,500'), findsWidgets);
      expect(find.textContaining('د.ل'), findsNothing);
      expect(find.text('دفعة للمورد'), findsOneWidget);
      expect(find.text('خصم من المورد'), findsOneWidget);
    });

    testWidgets('the form asks in dollars, for a dollar drawer, by cash or transfer alone', (
      tester,
    ) async {
      // Act
      await openPayForm(tester);

      // Assert
      expect(find.text('المبلغ بالدولار'), findsOneWidget);
      verify(
        () => repository.accountOptions(
          method: any(named: 'method'),
          incoming: false,
          currency: Currency.usd,
        ),
      ).called(1);
      final methods = tester.widget<AppDropdown<PaymentMethod>>(
        find.byType(AppDropdown<PaymentMethod>),
      );
      expect(methods.items, [PaymentMethod.bankTransfer, PaymentMethod.cash]);
    });

    testWidgets('no drawer named, nothing sent — dollars have no «تلقائي»', (tester) async {
      // Arrange
      await openPayForm(tester);

      // Act
      await submit(tester);

      // Assert
      expect(find.text('اختر حساب الدولار الذي خرج منه المبلغ'), findsOneWidget);
      verifyNever(
        () => repository.payVendor(
          vendorId: any(named: 'vendorId'),
          purchaseOrderId: any(named: 'purchaseOrderId'),
          amount: any(named: 'amount'),
          method: any(named: 'method'),
          accountId: any(named: 'accountId'),
          clientToken: any(named: 'clientToken'),
        ),
      );
    });

    testWidgets('a dollar drawer named pays in dollars, and the row says so', (tester) async {
      // Arrange
      await openPayForm(tester);
      await tester.enterText(find.byType(AppTextField).first, '600');
      final drawer = find.byType(AppDropdown<AccountOption>);
      await tester.ensureVisible(drawer);
      await tester.pumpAndSettle();
      await tester.tap(drawer);
      await tester.pumpAndSettle();
      await tester.tap(find.text('خزنة الدولار').last);
      await tester.pumpAndSettle();

      // Act
      await submit(tester);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Assert
      verify(
        () => repository.payVendor(
          vendorId: 9,
          purchaseOrderId: 4,
          amount: '600',
          method: any(named: 'method'),
          accountId: 21,
          clientToken: any(named: 'clientToken'),
        ),
      ).called(1);
      expect(find.textContaining(r'$600'), findsWidgets);
    });
  });
}
