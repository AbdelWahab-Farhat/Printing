import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/orders/models/transition_field.dart';
import 'package:printing/features/orders/presentation/widgets/transition_field_input.dart';

/// One field of a move, drawn from what the server said about it.
///
/// **The point of these tests is that nothing here is written per field.** «الوزن (كجم)» and
/// «الناقص من 30*30 (قطعة)» are the same widget with different words, and the words came down
/// the wire — so a field added to a path on the backend needs no change in this app.
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

  testWidgets('a required weight is asked for by its own name', (tester) async {
    // Arrange — exactly what the server sends for «جاهزة» on a kilo-priced order.
    const weight = TransitionField(
      key: 'weight_kg',
      type: TransitionFieldType.number,
      label: 'الوزن (كجم)',
      isRequired: true,
      hint: 'الطلبية مسعّرة بالكيلوغرام — الوزن هو ما تُحاسب عليه',
    );

    // Act
    await tester.pumpWidget(host(input(weight)));
    await tester.pump();

    // Assert — the label is the server's, and the hint under it too.
    expect(find.text('الوزن (كجم)'), findsOneWidget);
    expect(find.text('الطلبية مسعّرة بالكيلوغرام — الوزن هو ما تُحاسب عليه'), findsOneWidget);
  });

  testWidgets('an optional field says so, so nobody hunts for what is blocking them', (
    tester,
  ) async {
    // Arrange
    const weight = TransitionField(
      key: 'weight_kg',
      type: TransitionFieldType.number,
      label: 'الوزن (كجم)',
    );

    // Act
    await tester.pumpWidget(host(input(weight)));
    await tester.pump();

    // Assert
    expect(find.text('الوزن (كجم) (اختياري)'), findsOneWidget);
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
