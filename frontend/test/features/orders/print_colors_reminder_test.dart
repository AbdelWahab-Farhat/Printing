import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/transition_field.dart';
import 'package:dayaa/features/orders/presentation/widgets/transition_field_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «ألوان الطباعة» on the way to the press, and on the order's own versions — PRINT-COLORS.md.
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
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );
  }

  /// Exactly what the server sends on the move into «قيد الطباعة».
  final reminderJson = <String, dynamic>{
    'key': 'print_colors_reminder',
    'type': 'print_colors',
    'label': 'ألوان الطباعة — النسخة 2 المعتمدة',
    'required': false,
    'hint':
        'طابِق الرمز لا لون الشاشة. تُقفل الألوان بعد الانتقال إلى «قيد الطباعة»',
    'colors': [
      {'name': 'أحمر الشعار', 'code': 'PANTONE 186 C', 'hex': '#E4002B'},
      {'name': 'أسود النص', 'code': 'PANTONE Black C', 'hex': null},
    ],
  };

  test('the reminder arrives as its own kind, carrying the inks', () {
    // Act
    final field = TransitionField.fromJson(reminderJson);

    // Assert
    expect(field.type, TransitionFieldType.printColors);
    expect(field.isRenderable, isTrue);
    expect(field.isRequired, isFalse);
    expect(field.colors, const [
      PrintColor(name: 'أحمر الشعار', code: 'PANTONE 186 C', hex: '#E4002B'),
      PrintColor(name: 'أسود النص', code: 'PANTONE Black C'),
    ]);
  });

  test('every other kind of field comes without colors', () {
    // Act — no `colors` key, which is how the server sends every other field.
    final field = TransitionField.fromJson(const {
      'key': 'reason',
      'type': 'text',
      'label': 'ملاحظة',
    });

    // Assert
    expect(field.colors, isEmpty);
  });

  testWidgets('the move screen reads the inks out, with nothing to fill in', (
    tester,
  ) async {
    // Arrange
    final field = TransitionField.fromJson(reminderJson);

    // Act
    await tester.pumpWidget(
      host(
        TransitionFieldInput(
          field: field,
          value: null,
          customerId: 5,
          onChanged: (_) {},
        ),
      ),
    );

    // Assert
    expect(find.text('ألوان الطباعة — النسخة 2 المعتمدة'), findsOneWidget);
    expect(find.text('أحمر الشعار'), findsOneWidget);
    expect(find.text('PANTONE 186 C'), findsOneWidget);
    expect(find.text('PANTONE Black C'), findsOneWidget);
    expect(find.textContaining('تُقفل الألوان'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  group('the colours asked on the move (PRINT-COLORS.md §12)', () {
    final askedJson = <String, dynamic>{
      'key': 'press_colors',
      'type': 'print_colors_input',
      'label': 'ألوان الطباعة — النسخة 1',
      'required': true,
      'hint': 'حدّد كم لوناً وما هو كل لون.',
      'colors': [
        {'name': 'أزرق', 'code': null, 'hex': null},
      ],
    };

    test('arrives as its own kind, opening on what the version has', () {
      // Act
      final field = TransitionField.fromJson(askedJson);

      // Assert
      expect(field.type, TransitionFieldType.printColorsInput);
      expect(field.isRequired, isTrue);
      expect(field.colors, const [PrintColor(name: 'أزرق')]);
    });

    testWidgets('says what is missing and offers the sheet', (tester) async {
      // Arrange
      final field = TransitionField.fromJson(askedJson);

      // Act
      await tester.pumpWidget(
        host(
          TransitionFieldInput(
            field: field,
            value: field.colors,
            customerId: 5,
            onChanged: (_) {},
          ),
        ),
      );

      // Assert — a name without its swatch is not enough.
      expect(find.text('مطلوب: لونٌ بلا عيّنة — اختر لون كل خانة'), findsOneWidget);
      expect(find.text('تعديل الألوان'), findsOneWidget);
    });

    testWidgets('the colours chosen in the sheet are the answer', (tester) async {
      // Arrange
      tester.view
        ..physicalSize = const Size(430 * 3, 932 * 3)
        ..devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      final field = TransitionField.fromJson({...askedJson, 'colors': <Object>[]});
      Object? answer;
      await tester.pumpWidget(
        host(
          TransitionFieldInput(
            field: field,
            value: null,
            customerId: 5,
            onChanged: (value) => answer = value,
          ),
        ),
      );

      // Act
      await tester.tap(find.text('تحديد ألوان الطباعة'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('أسود'));
      await tester.pump();
      await tester.tap(find.text('اعتماد الألوان'));
      await tester.pumpAndSettle();

      // Assert
      expect(answer, const [PrintColor(name: 'أسود', hex: '#000000')]);
    });

    testWidgets('a version with no colours yet says the move waits for them', (tester) async {
      // Arrange
      final field = TransitionField.fromJson({...askedJson, 'colors': <Object>[]});

      // Act
      await tester.pumpWidget(
        host(TransitionFieldInput(field: field, value: null, customerId: 5, onChanged: (_) {})),
      );

      // Assert
      expect(find.text('مطلوب: لا تنتقل الطلبية إلى «قيد الطباعة» دون ألوانها'), findsOneWidget);
    });
  });

  test('a version holds its own copy of the colors', () {
    // Act
    final version = OrderDesign.fromJson(const {
      'id': 4,
      'version': 2,
      'status': 'approved',
      'status_label': 'معتمد',
      'print_colors': [
        {'name': 'أحمر الشعار', 'code': 'PANTONE 186 C', 'hex': '#E4002B'},
      ],
    });

    // Assert
    expect(version.printColors.single.code, 'PANTONE 186 C');
  });

  test('a version from a server that predates the colors reads as none', () {
    // Act
    final version = OrderDesign.fromJson(const {
      'id': 4,
      'version': 1,
      'status': 'proposed',
      'status_label': 'مقترح',
    });

    // Assert
    expect(version.printColors, isEmpty);
  });
}
