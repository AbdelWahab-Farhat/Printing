import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/widgets/payment_entry_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// ما تنادي به البطاقةُ الصفحةَ، مسجَّلاً ليُسأل عنه بعد النقر.
class _Calls {
  final reviewed = <bool>[];
  var settled = 0;
  var unsettled = 0;
  var reversed = 0;
}

/// بطاقة الدفعة في «دفعات الطلبية» — التصميم «ب» من لوحة ٢٠٢٦-١٠-٠٨.
///
/// **المبلغ بإشارته ووحدته، ومهمّتا الدفعة في مربّعين، والتصحيحات خلف «⋯».** كل قرارٍ هنا قرارُ
/// الخادم (`can_review`، `can_settle`، `can_unsettle`، `is_reversible`)، والبطاقة ترسم ما قيل لها
/// فقط — فهذه الاختبارات تُمسكها بذلك.
///
/// Arrange - Act - Assert throughout.
void main() {
  Widget host(Widget child) {
    return ScreenUtilInit(
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }

  OrderPayment payment({
    OrderPaymentType type = OrderPaymentType.payment,
    String typeLabel = 'دفعة',
    String amount = '226.00',
    String excessAmount = '0.00',
    bool isReversed = false,
    bool isReversible = false,
    bool hasReceipt = false,
    OrderPaymentReversal? reversal,
    bool requiresReview = false,
    bool isReviewed = false,
    bool canReview = false,
    bool canUnreview = false,
    PaymentRecorder? reviewer,
    DateTime? reviewedAt,
    PaymentAccountRef? account,
    PaymentSettlement? settlement,
    bool canSettle = false,
    bool canUnsettle = false,
    String? unsettleBlockedReason,
  }) {
    return OrderPayment(
      id: 1,
      orderId: 7,
      type: type,
      typeLabel: typeLabel,
      amount: amount,
      excessAmount: excessAmount,
      isReversed: isReversed,
      isReversible: isReversible,
      hasReceipt: hasReceipt,
      method: PaymentMethod.cash,
      methodLabel: 'كاش',
      reversal: reversal,
      recordedBy: const PaymentRecorder(id: 4, name: 'فرحات'),
      paidAt: DateTime(2026, 10, 8, 12, 55),
      requiresReview: requiresReview,
      isReviewed: isReviewed,
      canReview: canReview,
      canUnreview: canUnreview,
      reviewedBy: reviewer,
      reviewedAt: reviewedAt,
      treasuryAccount: account,
      settlement: settlement,
      canSettle: canSettle,
      canUnsettle: canUnsettle,
      unsettleBlockedReason: unsettleBlockedReason,
    );
  }

  const office = PaymentAccountRef(id: 3, name: 'بريمولا قرجي', kind: 'cash');
  const nawris = PaymentAccountRef(id: 9, name: 'النورس', kind: 'custody');
  const bank = PaymentAccountRef(id: 2, name: 'المصرف', kind: 'bank');

  Future<_Calls> pumpCard(
    WidgetTester tester,
    OrderPayment entry, {
    bool mayReverse = true,
    bool isBusy = false,
  }) async {
    final calls = _Calls();
    await tester.pumpWidget(
      host(
        PaymentEntryCard(
          payment: entry,
          isBusy: isBusy,
          mayReverse: mayReverse,
          onReview: calls.reviewed.add,
          onSettle: () => calls.settled++,
          onUnsettle: () => calls.unsettled++,
          onReverse: () => calls.reversed++,
        ),
      ),
    );
    await tester.pump();

    return calls;
  }

  group('the money', () {
    testWidgets('a payment is signed and in dinars, the sign held beside its number', (tester) async {
      // Arrange
      final entry = payment();

      // Act
      await pumpCard(tester, entry);

      // Assert — «+ 226» في سطرٍ عربي كان يُرسم «226 +».
      final figure = tester.widget<Text>(find.text('+226'));
      expect(figure.textDirection, TextDirection.ltr);
      expect(find.text('د.ل'), findsOneWidget);
    });

    testWidgets('a refund is minus, and a write-off carries no sign at all', (tester) async {
      // Arrange
      final refund = payment(type: OrderPaymentType.refund, typeLabel: 'ردّ مبلغ', amount: '50.00');
      final writeOff = payment(type: OrderPaymentType.writeOff, typeLabel: 'شطب الفرق', amount: '5.00');

      // Act
      await pumpCard(tester, refund);
      final refundFigure = find.text('−50');
      final refundFound = refundFigure.evaluate().length;
      await pumpCard(tester, writeOff);
      final writeOffFound = find.text('5').evaluate().length;

      // Assert
      expect(refundFound, 1);
      expect(writeOffFound, 1);
      expect(find.text('+5'), findsNothing);
      expect(find.text('−5'), findsNothing);
    });

    testWidgets('a type this build does not know claims no direction', (tester) async {
      // Arrange — «سُدِّدت لدى الناقل»: مالٌ وصل الناقلَ لا الدرج، ولا تعرفه هذه النسخة.
      final entry = payment(type: OrderPaymentType.unknown, typeLabel: 'سُدِّدت لدى الناقل', amount: '20.00');

      // Act
      await pumpCard(tester, entry);

      // Assert
      expect(find.text('20'), findsOneWidget);
      expect(find.text('−20'), findsNothing);
      expect(find.text('+20'), findsNothing);
    });

    testWidgets('a reversal row is struck through and says money came back off', (tester) async {
      // Arrange
      final entry = payment(type: OrderPaymentType.reversal, typeLabel: 'إلغاء قيد', amount: '260.00');

      // Act
      await pumpCard(tester, entry);

      // Assert
      final figure = tester.widget<Text>(find.text('−260'));
      expect(figure.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('what was beyond the debt is said as revenue, on the payment that carried it', (
      tester,
    ) async {
      // Arrange
      final entry = payment(amount: '140.00', excessAmount: '5.00');

      // Act
      await pumpCard(tester, entry);

      // Assert
      expect(find.text('منها زائد 5 د.ل · إيراد'), findsOneWidget);
    });

    testWidgets('a refund carrying an old excess says nothing of it', (tester) async {
      // Arrange
      final entry = payment(
        type: OrderPaymentType.refund,
        typeLabel: 'ردّ مبلغ',
        amount: '5.00',
        excessAmount: '5.00',
      );

      // Act
      await pumpCard(tester, entry);

      // Assert
      expect(find.textContaining('زائد'), findsNothing);
    });
  });

  group('the review tile', () {
    testWidgets('unreviewed, for somebody who may review: the state and a button that reviews', (
      tester,
    ) async {
      // Arrange
      final calls = await pumpCard(tester, payment(requiresReview: true, canReview: true));

      // Act
      await tester.tap(find.byKey(const ValueKey('review-1')));
      await tester.pump();

      // Assert
      expect(find.text('المراجعة'), findsOneWidget);
      expect(find.text('غير مراجَعة'), findsOneWidget);
      expect(calls.reviewed, [true]);
    });

    testWidgets('reviewed: who vouched for it, and no button left on the tile', (tester) async {
      // Arrange
      final entry = payment(
        requiresReview: true,
        isReviewed: true,
        canUnreview: true,
        reviewer: const PaymentRecorder(id: 5, name: 'سارة'),
        reviewedAt: DateTime(2026, 10, 7, 10),
      );

      // Act
      await pumpCard(tester, entry);

      // Assert
      expect(find.text('تمت المراجعة'), findsOneWidget);
      expect(find.textContaining('سارة'), findsOneWidget);
      expect(find.byKey(const ValueKey('review-1')), findsNothing);
      expect(find.text('إلغاء المراجعة'), findsNothing);
    });

    testWidgets('a payment nobody is asked to check has no review tile', (tester) async {
      // Arrange
      final entry = payment();

      // Act
      await pumpCard(tester, entry);

      // Assert
      expect(find.text('المراجعة'), findsNothing);
    });

    testWidgets('while the page is busy the button says so instead of greying out', (tester) async {
      // Arrange
      final entry = payment(requiresReview: true, canReview: true);

      // Act
      await pumpCard(tester, entry, isBusy: true);

      // Assert
      final button = tester.widget<AppButton>(find.byKey(const ValueKey('review-1')));
      expect(button.isLoading, isTrue);
      expect(button.onPressed, isNotNull);
    });
  });

  group('the place tile', () {
    testWidgets('unsettled: the account the money sits in, and «تسوية» for somebody who may', (
      tester,
    ) async {
      // Arrange
      final calls = await pumpCard(tester, payment(account: office, canSettle: true));

      // Act
      await tester.tap(find.byKey(const ValueKey('settle-1')));
      await tester.pump();

      // Assert
      expect(find.text('المبلغ في'), findsOneWidget);
      expect(find.text('بريمولا قرجي'), findsOneWidget);
      expect(calls.settled, 1);
    });

    testWidgets('settled: the account it reached, where from, and what the carrier kept', (
      tester,
    ) async {
      // Arrange
      final entry = payment(
        amount: '251.00',
        account: nawris,
        settlement: PaymentSettlement(
          operationId: 31,
          toAccount: bank,
          fee: '10.00',
          received: '241.00',
          settledAt: DateTime(2026, 10, 7, 10),
          settledBy: const PaymentRecorder(id: 5, name: 'سارة'),
        ),
        canUnsettle: true,
      );

      // Act
      await pumpCard(tester, entry);

      // Assert
      expect(find.text('المصرف'), findsOneWidget);
      expect(find.text('سُوّيت من النورس'), findsOneWidget);
      expect(find.text('وصل 241 · الناقل 10'), findsOneWidget);
      expect(find.byKey(const ValueKey('settle-1')), findsNothing);
      expect(find.text('التراجع عن التسوية'), findsNothing);
    });

    testWidgets('money already in its final account says where, with nothing to press', (
      tester,
    ) async {
      // Arrange
      final entry = payment(account: bank);

      // Act
      await pumpCard(tester, entry);

      // Assert
      expect(find.text('المبلغ في'), findsOneWidget);
      expect(find.text('المصرف'), findsOneWidget);
      expect(find.byKey(const ValueKey('settle-1')), findsNothing);
    });

    testWidgets('a refund says which account the money left', (tester) async {
      // Arrange
      final entry = payment(
        type: OrderPaymentType.refund,
        typeLabel: 'ردّ مبلغ',
        amount: '50.00',
        account: office,
      );

      // Act
      await pumpCard(tester, entry);

      // Assert
      expect(find.text('خرج من'), findsOneWidget);
      expect(find.text('بريمولا قرجي'), findsOneWidget);
    });

    testWidgets('an entry that moved no money has no place tile', (tester) async {
      // Arrange
      final entry = payment(type: OrderPaymentType.writeOff, typeLabel: 'شطب الفرق', amount: '5.00');

      // Act
      await pumpCard(tester, entry);

      // Assert
      expect(find.text('المبلغ في'), findsNothing);
      expect(find.text('خرج من'), findsNothing);
    });
  });

  group('the corrections behind «⋯»', () {
    OrderPayment correctable() => payment(
      isReversible: true,
      requiresReview: true,
      isReviewed: true,
      canUnreview: true,
      account: office,
      settlement: const PaymentSettlement(operationId: 31, toAccount: bank),
      canUnsettle: true,
    );

    testWidgets('none of them sits on the card; «⋯» opens all three', (tester) async {
      // Arrange
      await pumpCard(tester, correctable());
      final onCard = find.text('إلغاء الدفعة').evaluate().length;

      // Act
      await tester.tap(find.byTooltip('خيارات الدفعة'));
      await tester.pumpAndSettle();

      // Assert
      expect(onCard, 0);
      expect(find.text('إلغاء المراجعة'), findsOneWidget);
      expect(find.text('التراجع عن التسوية'), findsOneWidget);
      expect(find.text('إلغاء الدفعة'), findsOneWidget);
    });

    testWidgets('«إلغاء الدفعة» hands the cancellation to the page', (tester) async {
      // Arrange
      final calls = await pumpCard(tester, correctable());
      await tester.tap(find.byTooltip('خيارات الدفعة'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('إلغاء الدفعة'));
      await tester.pumpAndSettle();

      // Assert
      expect(calls.reversed, 1);
      expect(find.text('التراجع عن التسوية'), findsNothing);
    });

    testWidgets('«إلغاء المراجعة» takes the review back', (tester) async {
      // Arrange
      final calls = await pumpCard(tester, correctable());
      await tester.tap(find.byTooltip('خيارات الدفعة'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('إلغاء المراجعة'));
      await tester.pumpAndSettle();

      // Assert
      expect(calls.reviewed, [false]);
    });

    testWidgets('«التراجع عن التسوية» hands the undo to the page', (tester) async {
      // Arrange
      final calls = await pumpCard(tester, correctable());
      await tester.tap(find.byTooltip('خيارات الدفعة'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('التراجع عن التسوية'));
      await tester.pumpAndSettle();

      // Assert
      expect(calls.unsettled, 1);
    });

    testWidgets('an undo the server refuses says why, and cannot be chosen', (tester) async {
      // Arrange
      const reason = 'الطلبية «تم التسوية» — تراجع عن تسوية الطلبية أولاً';
      final entry = payment(
        isReversible: true,
        account: office,
        settlement: const PaymentSettlement(operationId: 31, toAccount: bank),
        unsettleBlockedReason: reason,
      );
      final calls = await pumpCard(tester, entry);
      final onCard = find.text(reason).evaluate().length;
      await tester.tap(find.byTooltip('خيارات الدفعة'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.text('التراجع عن التسوية'));
      await tester.pumpAndSettle();

      // Assert
      expect(onCard, 0);
      expect(find.text(reason), findsOneWidget);
      expect(calls.unsettled, 0);
    });

    testWidgets('nothing to correct, no «⋯»', (tester) async {
      // Arrange — ردٌّ لم يُراجَع: لا يُلغى، ولا مراجعة تُسحب.
      final entry = payment(
        type: OrderPaymentType.refund,
        typeLabel: 'ردّ مبلغ',
        amount: '50.00',
        requiresReview: true,
        canReview: true,
      );

      // Act
      await pumpCard(tester, entry);

      // Assert
      expect(find.byTooltip('خيارات الدفعة'), findsNothing);
    });

    testWidgets('without the grant to cancel, a cancellable payment offers nothing', (tester) async {
      // Arrange
      final entry = payment(isReversible: true);

      // Act
      await pumpCard(tester, entry, mayReverse: false);

      // Assert
      expect(find.byTooltip('خيارات الدفعة'), findsNothing);
    });

    testWidgets('a write-off is cancelled as an entry, not as a payment', (tester) async {
      // Arrange
      final entry = payment(
        type: OrderPaymentType.writeOff,
        typeLabel: 'شطب الفرق',
        amount: '5.00',
        isReversible: true,
      );
      await pumpCard(tester, entry);

      // Act
      await tester.tap(find.byTooltip('خيارات القيد'));
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('إلغاء القيد'), findsOneWidget);
      expect(find.text('إلغاء الدفعة'), findsNothing);
    });
  });

  group('a cancelled payment', () {
    testWidgets('is struck through, says why, and keeps no tiles', (tester) async {
      // Arrange
      final entry = payment(
        amount: '260.00',
        isReversed: true,
        reversal: const OrderPaymentReversal(id: 12, reason: 'أُدخل المبلغ خطأ'),
        requiresReview: true,
        account: office,
      );

      // Act
      await pumpCard(tester, entry);

      // Assert
      final title = tester.widget<Text>(find.text('دفعة'));
      expect(title.style?.decoration, TextDecoration.lineThrough);
      expect(find.text('أُلغيت: أُدخل المبلغ خطأ'), findsOneWidget);
      expect(find.text('المبلغ في'), findsNothing);
      expect(find.text('المراجعة'), findsNothing);
      expect(find.byTooltip('خيارات الدفعة'), findsNothing);
    });
  });

  testWidgets('a receipt on file is offered on the card', (tester) async {
    // Arrange
    final entry = payment(hasReceipt: true);

    // Act
    await pumpCard(tester, entry);

    // Assert
    expect(find.text('الواصل مرفق'), findsOneWidget);
  });
}
