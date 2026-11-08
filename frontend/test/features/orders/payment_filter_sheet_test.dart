import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/widgets/filter_option_chip.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/models/payment_settlement.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_queue_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// ورقة «تصفية متقدمة» في «مراجعة وتسوية الدفعات» — طلب صاحب العمل ٢٠٢٦-١١-٠٧.
///
/// **«نوع الدفعة» أزرارٌ بلغة المحلّ**: «حوالة» طريقة دفع، و«كاش نورس» و«مكتب قرجي» حسابان، فيُرسل
/// كلُّ زرٍّ ما يحمله. وبقية الحسابات خلف «حساب آخر». وتحتها مَن سجّل والمبلغ؛ و«مسوّاة» وحدها تسأل
/// إلى أين ذهبت ومَن سوّاها.
///
/// Arrange - Act - Assert throughout.
void main() {
  const options = PaymentFilterOptions(
    kinds: [
      PaymentKind(label: 'حوالة', method: PaymentMethod.bankTransfer),
      PaymentKind(label: 'كاش نورس', accountId: 4),
      PaymentKind(label: 'مكتب قرجي', accountId: 1),
      PaymentKind(label: 'مكتب ولي العهد', accountId: 5),
      PaymentKind(label: 'ليبيانا', method: PaymentMethod.libyana),
      PaymentKind(label: 'بطاقة مصرفية', method: PaymentMethod.bankCard),
    ],
    accounts: [
      SettlementAccount(id: 4, name: 'النورس'),
      SettlementAccount(id: 1, name: 'بريمولا قرجي'),
      SettlementAccount(id: 6, name: 'حساب فرحات'),
    ],
    recorders: [PaymentPerson(id: 21, name: 'سالم')],
    settlers: [PaymentPerson(id: 22, name: 'مريم')],
  );

  group('the options as the server sends them', () {
    test('each button carries a method or an account, and the lists are names', () {
      // Act
      final parsed = PaymentFilterOptions.fromJson(const {
        'kinds': [
          {'label': 'حوالة', 'method': 'bank_transfer', 'account_id': null},
          {'label': 'كاش نورس', 'method': null, 'account_id': 4},
        ],
        'accounts': [
          {'id': 4, 'name': 'النورس', 'kind': 'custody'},
        ],
        'recorders': [
          {'id': 21, 'name': 'سالم'},
        ],
        'settlers': [
          {'id': 22, 'name': 'مريم'},
        ],
      });

      // Assert
      expect(parsed.kinds.first.method, PaymentMethod.bankTransfer);
      expect(parsed.kinds.first.accountId, isNull);
      expect(parsed.kinds.last.method, isNull);
      expect(parsed.kinds.last.accountId, 4);
      expect(parsed.accounts.single.name, 'النورس');
      expect(parsed.recorders.single, const PaymentPerson(id: 21, name: 'سالم'));
      expect(parsed.settlers.single.id, 22);
    });

    test('a button for a method this build does not know is dropped, not shown as «الكل»', () {
      // Act
      final parsed = PaymentFilterOptions.fromJson(const {
        'kinds': [
          {'label': 'شيك', 'method': 'cheque', 'account_id': null},
        ],
      });

      // Assert
      expect(parsed.kinds, isEmpty);
    });
  });

  group('what is sent', () {
    test('only what is set reaches the query', () {
      // Arrange
      const detail = PaymentDetailFilter(
        method: PaymentMethod.bankTransfer,
        recordedBy: 21,
        minAmount: '100',
        maxAmount: '250.5',
        toAccountId: 2,
        settledBy: 22,
      );

      // Act
      final query = detail.toQuery();

      // Assert
      expect(query, {
        'method': 'bank_transfer',
        'recorded_by': 21,
        'amount_min': '100',
        'amount_max': '250.5',
        'to_account_id': 2,
        'settled_by': 22,
      });
      expect(const PaymentDetailFilter().toQuery(), isEmpty);
    });

    test('two filters with the same answers are the same filter', () {
      // Assert
      expect(
        const PaymentDetailFilter(method: PaymentMethod.libyana, minAmount: '5'),
        const PaymentDetailFilter(method: PaymentMethod.libyana, minAmount: '5'),
      );
      expect(const PaymentDetailFilter().isEmpty, isTrue);
      expect(const PaymentDetailFilter(minAmount: '5').isEmpty, isFalse);
    });
  });

  group('the sheet', () {
    late PaymentAdvancedFilter? chosen;

    Future<void> open(
      WidgetTester tester, {
      PaymentAdvancedFilter current = const PaymentAdvancedFilter(),
      PaymentFilterOptions shown = options,
      bool offersType = false,
      bool offersSettled = false,
      Size screen = const Size(430, 932),
    }) async {
      chosen = null;
      tester.view.physicalSize = screen;
      tester.view.devicePixelRatio = 1;
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
                  onPressed: () async {
                    chosen = await showPaymentAdvancedFilter(
                      context: context,
                      current: current,
                      options: shown,
                      offersType: offersType,
                      offersSettled: offersSettled,
                    );
                  },
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

    Future<void> tapChip(WidgetTester tester, String label) async {
      final chip = find.widgetWithText(FilterOptionChip, label);
      await tester.ensureVisible(chip);
      await tester.pumpAndSettle();
      await tester.tap(chip);
      await tester.pumpAndSettle();
    }

    Future<void> apply(WidgetTester tester) async {
      await tester.tap(find.byKey(const ValueKey('apply-advanced')));
      await tester.pumpAndSettle();
    }

    Future<void> type(WidgetTester tester, String key, String text) async {
      final field = find.descendant(of: find.byKey(ValueKey(key)), matching: find.byType(EditableText));
      await tester.ensureVisible(field);
      await tester.pumpAndSettle();
      await tester.enterText(field, text);
      await tester.pump();
    }

    bool isPicked(WidgetTester tester, String label) =>
        tester.widget<FilterOptionChip>(find.widgetWithText(FilterOptionChip, label)).isSelected;

    group('«نوع الدفعة»', () {
      testWidgets('the buttons keep the server\'s order, «الكل» first and picked, «حساب آخر» last', (tester) async {
        // Act
        await open(tester);

        // Assert
        expect(find.text('نوع الدفعة'), findsOneWidget);
        final labels = find
            .descendant(of: find.byKey(const ValueKey('payment-kinds')), matching: find.byType(FilterOptionChip))
            .evaluate()
            .map((chip) => (chip.widget as FilterOptionChip).label)
            .toList();
        expect(labels, [
          'الكل',
          'حوالة',
          'كاش نورس',
          'مكتب قرجي',
          'مكتب ولي العهد',
          'ليبيانا',
          'بطاقة مصرفية',
          'حساب آخر',
        ]);
        expect(isPicked(tester, 'الكل'), isTrue);
      });

      testWidgets('«حوالة» answers with the method and no account', (tester) async {
        // Arrange
        await open(tester);

        // Act
        await tapChip(tester, 'حوالة');
        await apply(tester);

        // Assert
        expect(chosen?.detail.method, PaymentMethod.bankTransfer);
        expect(chosen?.accountId, isNull);
      });

      testWidgets('«مكتب قرجي» answers with the account and no method', (tester) async {
        // Arrange
        await open(tester);

        // Act
        await tapChip(tester, 'مكتب قرجي');
        await apply(tester);

        // Assert
        expect(chosen?.accountId, 1);
        expect(chosen?.detail.method, isNull);
      });

      testWidgets('a button replaces the one before it, whichever kind it was', (tester) async {
        // Arrange
        await open(tester);
        await tapChip(tester, 'حوالة');

        // Act
        await tapChip(tester, 'كاش نورس');

        // Assert
        expect(isPicked(tester, 'كاش نورس'), isTrue);
        expect(isPicked(tester, 'حوالة'), isFalse);
        await apply(tester);
        expect(chosen?.accountId, 4);
        expect(chosen?.detail.method, isNull);
      });

      testWidgets('«الكل» takes the choice back', (tester) async {
        // Arrange
        await open(tester, current: const PaymentAdvancedFilter(accountId: 1));

        // Act
        await tapChip(tester, 'الكل');
        await apply(tester);

        // Assert
        expect(chosen?.accountId, isNull);
        expect(chosen?.detail.method, isNull);
      });

      testWidgets('«حساب آخر» opens the accounts, and the button then wears the name picked', (tester) async {
        // Arrange
        await open(tester);

        // Act
        await tapChip(tester, 'حساب آخر');
        await tester.tap(find.byKey(const ValueKey('account-option-6')));
        await tester.pumpAndSettle();

        // Assert
        expect(find.widgetWithText(FilterOptionChip, 'حساب آخر'), findsNothing);
        expect(isPicked(tester, 'حساب فرحات'), isTrue);
        await apply(tester);
        expect(chosen?.accountId, 6);
      });

      testWidgets('it reopens on what was picked: a button, or an account behind «حساب آخر»', (tester) async {
        // Act
        await open(tester, current: const PaymentAdvancedFilter(accountId: 6));

        // Assert
        expect(isPicked(tester, 'حساب فرحات'), isTrue);
        expect(isPicked(tester, 'الكل'), isFalse);
      });

      testWidgets('with no options the section is left out rather than drawn empty', (tester) async {
        // Act
        await open(tester, shown: const PaymentFilterOptions());

        // Assert
        expect(find.text('نوع الدفعة'), findsNothing);
        expect(find.text('مَن سجّل'), findsNothing);
      });
    });

    group('the other questions', () {
      testWidgets('amounts typed in Arabic digits answer in the digits the server reads', (tester) async {
        // Arrange
        await open(tester);

        // Act
        await type(tester, 'amount-min', '١٠٠');
        await type(tester, 'amount-max', '٢٥٠٫٥');
        await apply(tester);

        // Assert
        expect(chosen?.detail.minAmount, '100');
        expect(chosen?.detail.maxAmount, '250.5');
      });

      testWidgets('a floor above the ceiling is read as the two swapped, not refused', (tester) async {
        // Arrange
        await open(tester);

        // Act
        await type(tester, 'amount-min', '900');
        await type(tester, 'amount-max', '100');
        await apply(tester);

        // Assert
        expect(chosen?.detail.minAmount, '100');
        expect(chosen?.detail.maxAmount, '900');
      });

      testWidgets('it does not ask for a reference — the owner saw no use in one', (tester) async {
        // Act
        await open(tester);

        // Assert
        expect(find.text('رقم المرجع'), findsNothing);
      });

      testWidgets('it reopens on what was typed', (tester) async {
        // Act
        await open(
          tester,
          current: const PaymentAdvancedFilter(
            detail: PaymentDetailFilter(minAmount: '100'),
          ),
        );

        // Assert
        expect(find.text('100'), findsOneWidget);
      });

      testWidgets('«مسح الفلاتر» clears the typed fields with the rest', (tester) async {
        // Arrange
        await open(
          tester,
          current: const PaymentAdvancedFilter(
            accountId: 1,
            detail: PaymentDetailFilter(recordedBy: 21, minAmount: '100'),
          ),
        );

        // Act
        await tester.tap(find.text('مسح الفلاتر'));
        await tester.pumpAndSettle();
        await apply(tester);

        // Assert
        expect(chosen?.accountId, isNull);
        expect(chosen?.detail.isEmpty, isTrue);
      });

      testWidgets('«مسح الفلاتر» takes both people back to «الكل» on screen, not only in the answer', (tester) async {
        // Arrange
        await open(
          tester,
          offersSettled: true,
          current: const PaymentAdvancedFilter(
            detail: PaymentDetailFilter(recordedBy: 21, settledBy: 22),
          ),
        );
        expect(find.text('سالم'), findsOneWidget);
        expect(find.text('مريم'), findsOneWidget);

        // Act
        await tester.tap(find.text('مسح الفلاتر'));
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('سالم'), findsNothing);
        expect(find.text('مريم'), findsNothing);
      });

      testWidgets('«مسح الفلاتر» appears as soon as something is typed', (tester) async {
        // Arrange
        await open(tester);
        expect(find.text('مسح الفلاتر'), findsNothing);

        // Act
        await type(tester, 'amount-min', '5');

        // Assert
        expect(find.text('مسح الفلاتر'), findsOneWidget);
      });

      testWidgets('swiping the sheet away answers nothing, and is not a clear', (tester) async {
        // Arrange
        await open(tester, current: const PaymentAdvancedFilter(accountId: 1));

        // Act
        await tester.tapAt(const Offset(215, 10));
        await tester.pumpAndSettle();

        // Assert
        expect(chosen, isNull);
      });
    });

    group('which list asks what', () {
      testWidgets('the review list asks payment or refund', (tester) async {
        // Arrange
        await open(tester, offersType: true);

        // Act
        await tapChip(tester, 'ردود');
        await apply(tester);

        // Assert
        expect(chosen?.type, OrderPaymentType.refund);
      });

      testWidgets('the settlement lists do not ask payment or refund', (tester) async {
        // Act
        await open(tester);

        // Assert
        expect(find.text('دفعة أو ردّ'), findsNothing);
      });

      testWidgets('«مسوّاة» asks where it went and who settled', (tester) async {
        // Act
        await open(tester, offersSettled: true);

        // Assert
        expect(find.text('سُوّيت إلى'), findsOneWidget);
        expect(find.text('مَن سوّى'), findsOneWidget);
      });

      testWidgets('the waiting list does not ask where it went or who settled', (tester) async {
        // Act
        await open(tester);

        // Assert
        expect(find.text('سُوّيت إلى'), findsNothing);
        expect(find.text('مَن سوّى'), findsNothing);
      });

      testWidgets('where it went is picked from the accounts', (tester) async {
        // Arrange
        await open(tester, offersSettled: true);
        final field = find.byKey(const ValueKey('settled-to-none'));
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();

        // Act
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('account-option-6')));
        await tester.pumpAndSettle();
        await apply(tester);

        // Assert
        expect(chosen?.detail.toAccountId, 6);
      });
    });

    group('the layout', () {
      testWidgets('«تطبيق» stays on screen however long the sheet grows', (tester) async {
        // Arrange
        const screen = Size(430, 640);

        // Act
        await open(tester, offersSettled: true, screen: screen);

        // Assert — لا تمرير: الزرّ ثابتٌ تحت ما يتمرّر.
        final bottom = tester.getBottomRight(find.byKey(const ValueKey('apply-advanced'))).dy;
        expect(bottom, lessThanOrEqualTo(screen.height));
      });

      testWidgets('a picked day gives the calendar icon\'s room to the date, which was cut off', (tester) async {
        // Act
        await open(tester, current: PaymentAdvancedFilter(from: DateTime(2026, 10, 12)));

        // Assert — حقل «إلى» الفارغ وحده يبقى بأيقونته.
        expect(find.byIcon(AppIcons.today), findsOneWidget);
      });

      testWidgets('the title lines up with the sections under it', (tester) async {
        // Act
        await open(tester);

        // Assert
        final title = tester.getTopRight(find.text('تصفية متقدمة')).dx;
        final section = tester.getTopRight(find.text('الفترة')).dx;
        expect(title, section);
      });

      testWidgets('nothing overflows on a small phone', (tester) async {
        // Act
        await open(tester, offersType: true, offersSettled: true, screen: const Size(360, 640));

        // Assert
        expect(tester.takeException(), isNull);
      });
    });
  });
}
