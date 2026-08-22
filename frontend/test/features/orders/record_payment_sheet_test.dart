import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/orders/models/order_payment.dart';
import 'package:dayaa/features/orders/presentation/widgets/record_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// The form that takes money — and the receipt (الواصل) rules it asks about before the server
/// has to.
///
/// Fake picker only: the sheet, the source chooser and the pre-flight rules are all exercised
/// for real, and nothing reaches a platform channel that does not exist here.
///
/// Arrange - Act - Assert throughout.
class _FakePicker implements AttachmentPicker {
  List<PickedFile> answer = const [];
  AttachmentSource? asked;

  @override
  Future<List<PickedFile>> pick(AttachmentSource source) async {
    asked = source;

    return answer;
  }
}

void main() {
  late _FakePicker picker;

  setUp(() async {
    await Injector.reset();

    picker = _FakePicker();
    sl.registerSingleton<AttachmentPicker>(picker);
  });

  tearDown(Injector.reset);

  /// A screen with one button that opens the sheet and keeps whatever it came back with.
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

  /// Scrolls the target into the test surface first: the sheet grows past the harness's
  /// 600px the moment the receipt field appears, and a tap that lands off-screen passes
  /// vacuously instead of failing loudly.
  Future<void> tapInSheet(WidgetTester tester, String label) async {
    final target = find.text(label);
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// Opens the sheet and switches the method to «حوالة», which is what makes the receipt
  /// field appear.
  Future<void> openAsTransfer(WidgetTester tester) async {
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();

    await tapInSheet(tester, 'كاش');
    await tester.tap(find.text('حوالة').last);
    await tester.pumpAndSettle();
  }

  testWidgets('a photographed receipt is accepted and travels with the draft', (tester) async {
    // Arrange
    PaymentDraft? draft;
    picker.answer = const [
      PickedFile(path: '/tmp/waseel.jpg', name: 'waseel.jpg', sizeBytes: 2048),
    ];
    await tester.pumpWidget(host((closed) => draft = closed));
    await openAsTransfer(tester);

    // Act — through the same source sheet a design arrives through, from the photo library.
    await tapInSheet(tester, 'اختيار الواصل');
    await tapInSheet(tester, 'صور');
    await tapInSheet(tester, 'تسجيل الدفعة');

    // Assert
    expect(picker.asked, AttachmentSource.photos);
    expect(draft, isNotNull);
    expect(draft!.receipt?.name, 'waseel.jpg');
  });

  testWidgets('a file the server would refuse is refused before any upload', (tester) async {
    // Arrange
    picker.answer = const [PickedFile(path: '/tmp/a.docx', name: 'a.docx', sizeBytes: 1024)];
    await tester.pumpWidget(host((_) {}));
    await openAsTransfer(tester);

    // Act
    await tapInSheet(tester, 'اختيار الواصل');
    await tapInSheet(tester, 'مستندات');

    // Assert — the server's own words, and nothing attached.
    expect(find.text('الواصل يجب أن يكون بصيغة PDF أو JPG أو PNG أو WEBP'), findsOneWidget);
    expect(find.text('a.docx'), findsNothing);

    // Let the snackbar's own dismiss timer fire, or the binding reports it still pending.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('a transfer still cannot be saved without its receipt', (tester) async {
    // Arrange
    PaymentDraft? draft = const PaymentDraft(
      direction: PaymentDirection.incoming,
      amount: 'sentinel',
      method: PaymentMethod.cash,
    );
    var closed = false;
    await tester.pumpWidget(
      host((value) {
        closed = true;
        draft = value;
      }),
    );
    await openAsTransfer(tester);

    // Act
    await tapInSheet(tester, 'تسجيل الدفعة');

    // Assert — the sheet stays put and the empty file field is what lights up.
    expect(closed, isFalse);
    expect(draft?.amount, 'sentinel');
    expect(find.text('الواصل — مطلوب مع الحوالة'), findsOneWidget);
  });
}
