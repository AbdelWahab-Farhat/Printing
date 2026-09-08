import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/purchase_orders/models/purchase_order.dart';
import 'package:dayaa/features/purchase_orders/presentation/widgets/reverse_receipt_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The sheet that undoes a receipt.
///
/// **What is worth pinning here is that it does not close on a refusal.** Every other sheet in
/// this feature collects something and hands it back; this one sends, because the five refusals
/// the endpoint returns are instructions to do something else — usually a stocktake adjustment
/// — and that sentence has to reach somebody who is still holding the decision rather than a
/// snackbar behind a sheet that already closed.
///
/// Arrange - Act - Assert throughout.
void main() {
  const order = PurchaseOrder(
    id: 412,
    vendorId: 3,
    status: PurchaseOrderStatus.completed,
    statusLabel: 'مكتمل',
    orderDate: '2026-09-06',
    canReverseReceipt: true,
  );

  const refusal = Failure.server(
    message: 'صُرف من الدفعة بعد استلامها — الصواب تسوية جرد لا إلغاء استلام',
    statusCode: 422,
  );

  /// Opens the sheet over a button, and records what it eventually answered.
  Widget host({
    required Future<Failure?> Function(String reason) onConfirm,
    required void Function(bool? result) onClosed,
  }) {
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
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => onClosed(
                await showReverseReceiptSheet(
                  context: context,
                  order: order,
                  onConfirm: onConfirm,
                ),
              ),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('will not send until a reason has been typed', (tester) async {
    // Arrange — client-side, because a round trip to learn that a reason is required is a round
    // trip spent on a rule that never changes.
    var sent = 0;

    await tester.pumpWidget(
      host(
        onConfirm: (_) async {
          sent++;

          return null;
        },
        onClosed: (_) {},
      ),
    );

    // Act
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('reverse-receipt-confirm')));
    await tester.pumpAndSettle();

    // Assert — the sheet is still up, saying what is missing, and nothing was posted.
    expect(sent, 0);
    expect(find.text('سبب التراجع مطلوب'), findsOneWidget);
    expect(find.byKey(const Key('reverse-receipt-reason')), findsOneWidget);
  });

  testWidgets('a refusal is printed in the sheet, which stays open', (tester) async {
    // Arrange — the API deliberately does not publish whether a batch has been drawn on, so the
    // button is offered on receipts that turn out to be un-reversible. This is that case.
    bool? closedWith;
    var closed = false;

    await tester.pumpWidget(
      host(
        onConfirm: (_) async => refusal,
        onClosed: (result) {
          closed = true;
          closedWith = result;
        },
      ),
    );

    // Act
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reverse-receipt-reason')),
      'سُجّلت الكمية خطأً',
    );
    await tester.tap(find.byKey(const Key('reverse-receipt-confirm')));
    await tester.pumpAndSettle();

    // Assert — the server's own sentence, unedited, above the button the person is still
    // looking at. Re-wording it would drop the instruction it carries.
    expect(closed, isFalse);
    expect(closedWith, isNull);
    expect(find.byKey(const Key('reverse-receipt-refusal')), findsOneWidget);
    expect(find.text(refusal.message), findsOneWidget);
  });

  testWidgets('closes with true once the server accepts it', (tester) async {
    // Arrange
    String? reasonSent;
    bool? closedWith;

    await tester.pumpWidget(
      host(
        onConfirm: (reason) async {
          reasonSent = reason;

          return null;
        },
        onClosed: (result) => closedWith = result,
      ),
    );

    // Act
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('reverse-receipt-reason')),
      '  سُجّلت الكمية خطأً  ',
    );
    await tester.tap(find.byKey(const Key('reverse-receipt-confirm')));
    await tester.pumpAndSettle();

    // Assert — dismissed only on success, and the screen behind is told so it can say what
    // happened to the stock.
    expect(reasonSent, 'سُجّلت الكمية خطأً');
    expect(closedWith, isTrue);
    expect(find.byKey(const Key('reverse-receipt-confirm')), findsNothing);
  });

  testWidgets('says what will happen before it asks', (tester) async {
    // Arrange — this takes real stock off a real shelf and reopens paperwork somebody already
    // closed. «هل أنت متأكد؟» is not enough to authorise that.
    await tester.pumpWidget(
      host(onConfirm: (_) async => null, onClosed: (_) {}),
    );

    // Act
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    // Assert
    expect(
      find.textContaining('سيُسحب ما استُلم من الرف'),
      findsOneWidget,
    );
    expect(
      find.textContaining('يعود الأمر إلى «قيد الاستلام»'),
      findsOneWidget,
    );
    expect(find.textContaining('تبقى الشحنة في السجل'), findsOneWidget);
  });
}
