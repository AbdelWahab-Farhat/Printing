import 'dart:convert';
import 'dart:typed_data';

import 'package:dayaa/core/widgets/app_dropdown.dart';
import 'package:dayaa/features/treasury/models/exchange_figures.dart';
import 'package:dayaa/features/treasury/models/treasury_models.dart';
import 'package:dayaa/features/treasury/presentation/widgets/currency_exchange_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_account_sheet.dart';
import 'package:dayaa/features/treasury/presentation/widgets/treasury_widgets.dart';
import 'package:dayaa/features/treasury/repositories/treasury_repository_impl.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Dollar accounts and «صرف عملة» in the app — USD-ACCOUNTS.md §٣, phase 1.
///
/// Arrange - Act - Assert throughout.
class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter(this.answer);

  final Object? answer;
  Object? body;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final bytes = (await requestStream.toList()).expand((chunk) => chunk).toList();
      body = jsonDecode(utf8.decode(bytes));
    }

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

const _dinarBox = TreasuryAccount(
  id: 1,
  name: 'بريمولا قرجي',
  kind: AccountKind.cash,
  kindLabel: 'كاش',
  isDefault: true,
  isActive: true,
  isSystem: false,
  isSpendable: true,
  balance: '10000.00',
);

const _dollarBox = TreasuryAccount(
  id: 2,
  name: 'خزنة الدولار',
  kind: AccountKind.cash,
  kindLabel: 'كاش',
  isDefault: false,
  isActive: true,
  isSystem: false,
  isSpendable: true,
  balance: '500.00',
  currency: Currency.usd,
);

void main() {
  group('the third figure of an exchange', () {
    test('two amounts give the rate, to four places, rounded half up', () {
      // Act
      final rate = completeExchange(typed: {'lyd', 'usd'}, lyd: '7000', usd: '977', rate: null);

      // Assert — 7000 / 977 = 7.164790…
      expect(rate, '7.1648');
    });

    test('dinars and a rate give the dollars, to the cent', () {
      // Act
      final usd = completeExchange(typed: {'lyd', 'rate'}, lyd: '7300', usd: null, rate: '7.3');

      // Assert
      expect(usd, '1000.00');
    });

    test('dollars and a rate give the dinars, as the server rounds them', () {
      // Act — 333 × 7.1537 = 2382.1821
      final lyd = completeExchange(typed: {'usd', 'rate'}, lyd: null, usd: '333', rate: '7.1537');

      // Assert
      expect(lyd, '2382.18');
    });

    test('one figure, or one that is not a number, leaves the third empty', () {
      // Act / Assert
      expect(completeExchange(typed: {'lyd'}, lyd: '7150', usd: null, rate: null), isNull);
      expect(completeExchange(typed: {'lyd', 'usd'}, lyd: '7150', usd: 'abc', rate: null), isNull);
      expect(completeExchange(typed: {'lyd', 'rate'}, lyd: '0.01', usd: null, rate: '7'), isNull);
    });
  });

  group('how dollars are written', () {
    test('a dollar figure carries the sign before it, isolated left to right', () {
      // Act
      final text = treasuryMoney('-1250.00', currency: Currency.usd);

      // Assert
      expect(text, '${String.fromCharCode(0x2066)}−\$1,250${String.fromCharCode(0x2069)}');
    });

    test('dinars are written as they always were', () {
      // Act / Assert
      expect(treasuryMoney('1250.00'), '1,250 د.ل');
    });

    test('an account\'s balance is said in its own currency', () {
      // Act / Assert
      expect(treasuryBalanceLabel(_dollarBox), contains(r'$500'));
      expect(treasuryBalanceLabel(_dinarBox), '10,000 د.ل');
    });
  });

  group('what the server sends', () {
    test('an account without a currency is dinars, and a dollar one says so', () {
      // Act
      final old = TreasuryAccount.fromJson({'id': 1, 'name': 'كاش', 'kind': 'cash'});
      final usd = TreasuryAccount.fromJson({
        'id': 2,
        'name': 'دولار',
        'kind': 'cash',
        'currency': 'USD',
      });

      // Assert
      expect(old.currency, Currency.lyd);
      expect(usd.isDollar, isTrue);
    });

    test('the totals carry the dollars and their worth at the system rate', () {
      // Act
      final accounts = TreasuryAccounts.fromJson({
        'accounts': <Object>[],
        'total': '10050.00',
        'can_view_all': true,
        'usd_total': '1000.00',
        'usd_rate': '7.2000',
        'usd_total_in_lyd': '7200.00',
      });

      // Assert
      expect(accounts.dollars.held, '1000.00');
      expect(accounts.dollars.rate, '7.2000');
      expect(accounts.dollars.inLyd, '7200.00');
      expect(accounts.dollars.isEmpty, isFalse);
    });

    test('an older server says nothing about dollars', () {
      // Act
      final ownership = TreasuryOwnership.fromJson({'total_held': '500.00'});

      // Assert
      expect(ownership.dollars.isEmpty, isTrue);
    });
  });

  group('what the app puts on the wire', () {
    TreasuryRepositoryImpl repositoryOver(_CapturingAdapter adapter) => TreasuryRepositoryImpl(
      Dio(BaseOptions(baseUrl: 'http://localhost/api/v1'))..httpClientAdapter = adapter,
    );

    test('an exchange sends the two figures typed, by the names the server reads', () async {
      // Arrange
      final adapter = _CapturingAdapter({
        'id': 9,
        'type': 'exchange',
        'type_label': 'صرف عملة',
        'amount': '7150.00',
        'counter_amount': '1000.00',
        'rate': '7.1500',
      });

      // Act
      final result = await repositoryOver(adapter).recordOperation(
        kind: OperationKind.exchange,
        fromAccountId: 1,
        toAccountId: 2,
        amount: '7150',
        counterAmount: '1000',
      );

      // Assert
      expect(adapter.body, {
        'type': 'exchange',
        'amount': '7150',
        'counter_amount': '1000',
        'from_account_id': 1,
        'to_account_id': 2,
      });
      expect(result.getOrElse(() => throw StateError('failed')).rate, '7.1500');
    });

    test('a new dollar account says its currency', () async {
      // Arrange
      final adapter = _CapturingAdapter({
        'id': 2,
        'name': 'دولار',
        'kind': 'cash',
        'currency': 'USD',
      });

      // Act
      await repositoryOver(
        adapter,
      ).saveAccount(name: 'دولار', kind: 'cash', currency: Currency.usd);

      // Assert
      expect((adapter.body as Map)['currency'], 'USD');
    });

    test('the system rate is written, and cleared by sending it empty', () async {
      // Arrange
      final writing = _CapturingAdapter(<String, Object?>{});
      final clearing = _CapturingAdapter(<String, Object?>{});

      // Act
      await repositoryOver(writing).saveSettings(usdRate: '7.15');
      await repositoryOver(clearing).saveSettings(clearUsdRate: true);

      // Assert
      expect(writing.body, {'usd_rate': '7.15'});
      expect(clearing.body, {'usd_rate': null});
    });
  });

  group('the exchange sheet', () {
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

    Finder field(String figure) => find.descendant(
      of: find.byKey(ValueKey('exchange-$figure')),
      matching: find.byType(EditableText),
    );

    String shown(WidgetTester tester, String figure) =>
        tester.widget<EditableText>(field(figure)).controller.text;

    Future<void> submit(WidgetTester tester) async {
      final button = find.text('تسجيل صرف العملة');
      await tester.ensureVisible(button);
      await tester.pumpAndSettle();
      await tester.tap(button);
      // The success toast dismisses itself after three seconds.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    }

    testWidgets('buying dollars: two amounts typed, the rate shown, the two amounts sent', (
      tester,
    ) async {
      // Arrange
      Map<String, Object?>? sent;
      await tester.pumpWidget(
        host(
          (context) => showCurrencyExchangeSheet(
            context: context,
            accounts: const [_dinarBox, _dollarBox],
            account: _dinarBox,
            onSubmit:
                ({
                  required fromAccountId,
                  required toAccountId,
                  amount,
                  counterAmount,
                  rate,
                  notes,
                  clientToken,
                }) async {
                  sent = {
                    'from': fromAccountId,
                    'to': toAccountId,
                    'amount': amount,
                    'counter': counterAmount,
                    'rate': rate,
                  };

                  return null;
                },
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(field('lyd'), '7150');
      await tester.enterText(field('usd'), '1000');
      await tester.pump();
      final rate = shown(tester, 'rate');
      await submit(tester);

      // Assert
      expect(rate, '7.1500');
      expect(sent, {'from': 1, 'to': 2, 'amount': '7150', 'counter': '1000', 'rate': null});
    });

    testWidgets('selling dollars: turned round, the dollars leave and are the amount', (
      tester,
    ) async {
      // Arrange
      Map<String, Object?>? sent;
      await tester.pumpWidget(
        host(
          (context) => showCurrencyExchangeSheet(
            context: context,
            accounts: const [_dinarBox, _dollarBox],
            account: _dollarBox,
            onSubmit:
                ({
                  required fromAccountId,
                  required toAccountId,
                  amount,
                  counterAmount,
                  rate,
                  notes,
                  clientToken,
                }) async {
                  sent = {
                    'from': fromAccountId,
                    'to': toAccountId,
                    'amount': amount,
                    'counter': counterAmount,
                    'rate': rate,
                  };

                  return null;
                },
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byKey(const ValueKey('exchange-swap')));
      await tester.pump();
      await tester.enterText(field('usd'), '200');
      await tester.enterText(field('rate'), '7.2');
      await tester.pump();
      final lyd = shown(tester, 'lyd');
      await submit(tester);

      // Assert
      expect(lyd, '1440.00');
      expect(sent, {'from': 2, 'to': 1, 'amount': '200', 'counter': null, 'rate': '7.2'});
    });

    testWidgets('the system rate is offered only to whoever may change it', (tester) async {
      // Arrange
      Future<void> open(BuildContext context, {required bool mayChange}) =>
          showCurrencyExchangeSheet(
            context: context,
            accounts: const [_dinarBox, _dollarBox],
            account: _dinarBox,
            onUpdateSystemRate: mayChange ? (_) async => null : null,
            onSubmit:
                ({
                  required fromAccountId,
                  required toAccountId,
                  amount,
                  counterAmount,
                  rate,
                  notes,
                  clientToken,
                }) async => null,
          );

      // Act
      await tester.pumpWidget(host((context) => open(context, mayChange: false)));
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      final offeredToClerk = find
          .byKey(const ValueKey('exchange-update-rate'))
          .evaluate()
          .isNotEmpty;

      await tester.pumpWidget(Container());
      await tester.pumpWidget(host((context) => open(context, mayChange: true)));
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      final offeredToOwner = find
          .byKey(const ValueKey('exchange-update-rate'))
          .evaluate()
          .isNotEmpty;

      // Assert
      expect(offeredToClerk, isFalse);
      expect(offeredToOwner, isTrue);
    });
  });

  group('the account sheet', () {
    testWidgets('a new bank in dollars drops the default switch and sends its currency', (
      tester,
    ) async {
      // Arrange
      Currency? sent;
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
                builder: (context) => ElevatedButton(
                  onPressed: () => showTreasuryAccountSheet(
                    context: context,
                    onSubmit:
                        ({
                          required name,
                          kind,
                          isDefault,
                          isActive,
                          holderUserId,
                          notes,
                          currency,
                        }) async {
                          sent = currency;

                          return null;
                        },
                  ),
                  child: const Text('افتح'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Act — the sheet opens on a bank; pick dollars and save
      final picker = tester.widget<AppDropdown<Currency>>(
        find.byKey(const ValueKey('account-currency')),
      );
      final offeredDefaultInDinars = find.text('الحساب الافتراضي لنوعه').evaluate().isNotEmpty;
      picker.onChanged(Currency.usd);
      await tester.pump();
      final offeredDefaultInDollars = find.text('الحساب الافتراضي لنوعه').evaluate().isNotEmpty;
      await tester.enterText(find.byType(EditableText).first, 'مصرف الدولار');
      final save = find.text('حفظ');
      await tester.ensureVisible(save);
      await tester.pumpAndSettle();
      await tester.tap(save);
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();

      // Assert
      expect(offeredDefaultInDinars, isTrue);
      expect(offeredDefaultInDollars, isFalse);
      expect(sent, Currency.usd);
    });
  });
}
