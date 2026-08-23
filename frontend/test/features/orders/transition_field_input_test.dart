import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/files/attachment_picker.dart';
import 'package:dayaa/core/files/picked_file.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/presentation/widgets/transition_field_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// One field of a move, drawn from what the server said about it.
///
/// **The point of these tests is that nothing here is written per field.** «المخصوم من 25*35
/// (كيلوغرام)» and «الناقص من 30*30 (قطعة)» are the same widget with different words, and the
/// words came down the wire — so a field added to a path on the backend needs no change in this
/// app. «الوزن (كجم)» was drawn by this same widget until the day it was deleted, and deleting
/// it took no Dart with it.
///
/// Arrange - Act - Assert throughout.
/// Hands back whatever it was told to, so the sheet and the picker can be driven from a test
/// with no platform channel behind them.
class _FakePicker implements AttachmentPicker {
  _FakePicker(this.result);

  final List<PickedFile> result;

  @override
  Future<List<PickedFile>> pick(AttachmentSource source) async => result;
}

void main() {
  setUp(() async {
    await sl.reset();
  });

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
            child: SingleChildScrollView(child: child),
          ),
        ),
      ),
    );
  }

  Widget input(TransitionField field, {ValueChanged<Object?>? onChanged}) {
    return TransitionFieldInput(
      field: field,
      value: null,
      customerId: 5,
      onChanged: onChanged ?? (_) {},
    );
  }

  testWidgets('a required quantity is asked for by its own name', (tester) async {
    // Arrange — exactly what the server sends for «جاهزة» on a line stocked in a unit it is
    // not sold in. The unit is in the label, because the person typing holds two figures.
    const measured = TransitionField(
      key: 'warehouse_quantity_31',
      type: TransitionFieldType.number,
      label: 'المخصوم من 25*35 (كيلوغرام)',
      isRequired: true,
      hint: 'المباع 500.000 قطعة — والمخزن يُنقص بالكيلوغرام',
    );

    // Act
    await tester.pumpWidget(host(input(measured)));
    await tester.pump();

    // Assert — the label is the server's, and the hint under it too.
    expect(find.text('المخصوم من 25*35 (كيلوغرام)'), findsOneWidget);
    expect(find.text('المباع 500.000 قطعة — والمخزن يُنقص بالكيلوغرام'), findsOneWidget);
  });

  testWidgets('an optional field says so, so nobody hunts for what is blocking them', (
    tester,
  ) async {
    // Arrange — the same box on an order whose stock has already left, where a second answer
    // would do nothing.
    const measured = TransitionField(
      key: 'warehouse_quantity_31',
      type: TransitionFieldType.number,
      label: 'المخصوم من 25*35 (كيلوغرام)',
    );

    // Act
    await tester.pumpWidget(host(input(measured)));
    await tester.pump();

    // Assert
    expect(find.text('المخصوم من 25*35 (كيلوغرام) (اختياري)'), findsOneWidget);
  });

  testWidgets('what is typed reaches the caller as typed', (tester) async {
    // Arrange — a shortage line, which is the same widget with the server's own words.
    const shortage = TransitionField(
      key: 'shortage_12',
      type: TransitionFieldType.number,
      label: 'الناقص من 30*30 (قطعة)',
      max: 100,
      hint: 'من أصل 100.000',
    );

    Object? reported;

    // Act
    await tester.pumpWidget(host(input(shortage, onChanged: (value) => reported = value)));
    await tester.enterText(find.byType(TextField), '40');
    await tester.pump();

    // Assert — the string, not a parsed number: a half-typed «12.» is not this app's to judge,
    // and the server parses what it is sent.
    expect(reported, '40');
  });

  testWidgets('the warehouse a run comes off is a picker, not a note', (tester) async {
    // Arrange — exactly what the server sends for «قيد الطباعة» on an order whose stock has
    // never left a shelf. This is the field that used to fall through to «unknown», which made
    // the commonest move in the app unmakeable.
    const store = TransitionField(
      key: 'warehouse_id',
      type: TransitionFieldType.warehouse,
      label: 'المخزن',
      isRequired: true,
      hint: 'يُخصم منه ما تستهلكه هذه الطلبية من المخزون',
    );

    // Act
    await tester.pumpWidget(host(input(store)));
    await tester.pump();

    // Assert — the label, the server's sentence under it, and something to press. Not the
    // «needs a newer build» note, which is the whole bug.
    expect(find.text('المخزن'), findsOneWidget);
    expect(find.text('يُخصم منه ما تستهلكه هذه الطلبية من المخزون'), findsOneWidget);
    expect(find.text('اختيار المخزن'), findsOneWidget);
    expect(find.textContaining('يحتاج نسخة أحدث'), findsNothing);
  });

  testWidgets('a reprint is offered the warehouse without being made to answer', (tester) async {
    // Arrange — stock already left a shelf for this order, so the server sends the field
    // unrequired and does nothing with a second answer.
    const store = TransitionField(
      key: 'warehouse_id',
      type: TransitionFieldType.warehouse,
      label: 'المخزن',
      hint: 'خُصم المخزون بالفعل من هذه الطلبية',
    );

    // Act
    await tester.pumpWidget(host(input(store)));
    await tester.pump();

    // Assert — «(اختياري)» is how every other optional field says so, so nobody hunts for what
    // is blocking them.
    expect(find.text('المخزن (اختياري)'), findsOneWidget);
  });

  testWidgets('the way money was handed over is a row of chips, in the server words', (
    tester,
  ) async {
    // Arrange — exactly what the server sends beside «المبلغ المقبوض» on «تم الاستلام». Three
    // methods, not the four the business uses: «حوالة» needs a receipt and this screen uploads
    // no files, so it never reaches the app at all.
    const method = TransitionField(
      key: 'payment_method',
      type: TransitionFieldType.paymentMethod,
      label: 'طريقة الدفع',
      hint: 'الحوالة تُسجَّل من شاشة الدفعات لأنها تتطلّب واصلاً',
      options: [
        TransitionFieldOption(value: 'cash', label: 'كاش'),
        TransitionFieldOption(value: 'bank_card', label: 'بطاقة مصرفية'),
        TransitionFieldOption(value: 'libyana', label: 'ليبيانا'),
      ],
    );

    // Act
    await tester.pumpWidget(host(input(method)));
    await tester.pump();

    // Assert — the labels are the server's, drawn as sent. Nothing here maps a wire value to an
    // Arabic word, which is why a fourth method needs no release.
    expect(find.text('كاش'), findsOneWidget);
    expect(find.text('بطاقة مصرفية'), findsOneWidget);
    expect(find.text('ليبيانا'), findsOneWidget);
    expect(find.text('حوالة'), findsNothing);
    expect(find.text('الحوالة تُسجَّل من شاشة الدفعات لأنها تتطلّب واصلاً'), findsOneWidget);
    expect(find.textContaining('يحتاج نسخة أحدث'), findsNothing);
  });

  testWidgets('picking a method reports its wire value, never its label', (tester) async {
    // Arrange
    const method = TransitionField(
      key: 'payment_method',
      type: TransitionFieldType.paymentMethod,
      label: 'طريقة الدفع',
      options: [
        TransitionFieldOption(value: 'cash', label: 'كاش'),
        TransitionFieldOption(value: 'libyana', label: 'ليبيانا'),
      ],
    );

    Object? reported;

    // Act
    await tester.pumpWidget(host(input(method, onChanged: (value) => reported = value)));
    await tester.tap(find.text('ليبيانا'));
    await tester.pump();

    // Assert — the Arabic is for the person; the endpoint is sent what it named the choice.
    expect(reported, 'libyana');
  });

  testWidgets('the method the server filled in opens already chosen', (tester) async {
    // Arrange — cash, because a counter takes cash: agreeing costs no taps.
    const method = TransitionField(
      key: 'payment_method',
      type: TransitionFieldType.paymentMethod,
      label: 'طريقة الدفع',
      value: 'cash',
      options: [
        TransitionFieldOption(value: 'cash', label: 'كاش'),
        TransitionFieldOption(value: 'bank_card', label: 'بطاقة مصرفية'),
      ],
    );

    // Act — the value the cubit seeded from `field.value`, handed back in as any other answer.
    await tester.pumpWidget(
      host(
        TransitionFieldInput(
          field: method,
          value: 'cash',
          customerId: 5,
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    // Assert
    final chosen = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('كاش'), matching: find.byType(ChoiceChip)),
    );
    final other = tester.widget<ChoiceChip>(
      find.ancestor(of: find.text('بطاقة مصرفية'), matching: find.byType(ChoiceChip)),
    );

    expect(chosen.selected, isTrue);
    expect(other.selected, isFalse);
  });

  testWidgets('a file field says what it wants and offers something to press', (tester) async {
    // Arrange — exactly what the server sends beside the money on «تم الاستلام».
    const receipt = TransitionField(
      key: 'payment_receipt',
      type: TransitionFieldType.file,
      label: 'الواصل',
      hint: 'مطلوب مع الحوالة، ويُقبل مع غيرها',
      extensions: ['pdf', 'jpg', 'jpeg', 'png', 'webp'],
      maxKilobytes: 10240,
    );

    // Act
    await tester.pumpWidget(host(input(receipt)));
    await tester.pump();

    // Assert
    expect(find.text('الواصل (اختياري)'), findsOneWidget);
    expect(find.text('مطلوب مع الحوالة، ويُقبل مع غيرها'), findsOneWidget);
    expect(find.text('اختيار الواصل'), findsOneWidget);
    expect(find.textContaining('يحتاج نسخة أحدث'), findsNothing);
  });

  testWidgets('a chosen file is named on screen and reported whole', (tester) async {
    // Arrange
    const receipt = TransitionField(
      key: 'payment_receipt',
      type: TransitionFieldType.file,
      label: 'الواصل',
      extensions: ['pdf'],
      maxKilobytes: 10240,
    );
    const file = PickedFile(path: '/tmp/waseel.pdf', name: 'waseel.pdf', sizeBytes: 2048);
    sl.registerSingleton<AttachmentPicker>(_FakePicker(const [file]));

    Object? reported;

    // Act
    await tester.pumpWidget(host(input(receipt, onChanged: (value) => reported = value)));
    await tester.tap(find.text('اختيار الواصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مستندات'));
    await tester.pumpAndSettle();

    // Assert — the whole [PickedFile], because the repository needs its path to stream from and
    // its name for what the server records as the original filename.
    expect(reported, file);
  });

  testWidgets('a file the endpoint would refuse never leaves the phone', (tester) async {
    // Arrange — the limits came down with the field, so nothing here restates config/media.php.
    const receipt = TransitionField(
      key: 'payment_receipt',
      type: TransitionFieldType.file,
      label: 'الواصل',
      extensions: ['pdf', 'jpg'],
      maxKilobytes: 10240,
    );
    sl.registerSingleton<AttachmentPicker>(
      _FakePicker(const [PickedFile(path: '/tmp/x.exe', name: 'x.exe', sizeBytes: 2048)]),
    );

    var reported = 0;

    // Act
    await tester.pumpWidget(host(input(receipt, onChanged: (_) => reported++)));
    await tester.tap(find.text('اختيار الواصل'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('مستندات'));
    await tester.pumpAndSettle();

    // Assert — refused here, in the server's own words, rather than after an upload the person
    // waited through on a mobile connection.
    expect(reported, 0);
    expect(find.textContaining('بصيغة PDF أو JPG'), findsOneWidget);

    // Let the snackbar's own dismiss timer fire, or the binding reports it still pending.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('a kind this build cannot draw says so instead of leaving a hole', (tester) async {
    // Arrange — what a field of a type added on the server after this release looks like.
    const future = TransitionField(
      key: 'collected_at',
      type: TransitionFieldType.unknown,
      label: 'تاريخ الاستلام',
      isRequired: true,
    );

    // Act
    await tester.pumpWidget(host(input(future)));
    await tester.pump();

    // Assert — a required field the screen never showed is a form that cannot be submitted
    // with nothing on screen to explain why.
    expect(find.textContaining('يحتاج نسخة أحدث'), findsOneWidget);
  });
}
