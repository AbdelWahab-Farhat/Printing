import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/core/print_colors/print_colors_editor.dart';
import 'package:dayaa/core/print_colors/print_colors_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// «ألوان الطباعة» — the model, the chips that read it and the field that writes it.
///
/// Arrange - Act - Assert throughout.
void main() {
  const red = PrintColor(
    name: 'أحمر الشعار',
    code: 'PANTONE 186 C',
    hex: '#E4002B',
  );
  const white = PrintColor(name: 'أبيض');

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

  group('PrintColor', () {
    test('reads the server shape and writes it back unchanged', () {
      // Arrange
      final json = <String, dynamic>{
        'name': 'أحمر الشعار',
        'code': 'PANTONE 186 C',
        'hex': '#E4002B',
      };

      // Act
      final color = PrintColor.fromJson(json);

      // Assert
      expect(color, red);
      expect(color.toJson(), json);
    });

    test('a blank code goes up as null, the form the server stores', () {
      // Arrange
      const color = PrintColor(name: 'أسود', code: '  ');

      // Act
      final json = color.toJson();

      // Assert
      expect(json['code'], isNull);
    });

    test('a swatch is six hex digits or nothing', () {
      // Act / Assert
      expect(PrintColor.parseHex('#E4002B'), const Color(0xFFE4002B));
      expect(PrintColor.parseHex('#e4002b'), const Color(0xFFE4002B));
      expect(PrintColor.parseHex('red'), isNull);
      expect(PrintColor.parseHex('#FFF'), isNull);
      expect(PrintColor.parseHex(null), isNull);
    });

    test('a colour goes back out as upper-case #RRGGBB', () {
      // Act / Assert
      expect(PrintColor.toHex(const Color(0xFF0033A0)), '#0033A0');
      expect(PrintColor.toHex(const Color(0xFF000000)), '#000000');
    });

    test(
      'a list tolerates null and stray entries rather than failing the whole record',
      () {
        // Act / Assert
        expect(PrintColor.listFromJson(null), isEmpty);
        expect(PrintColor.listFromJson('nonsense'), isEmpty);
        expect(
          PrintColor.listFromJson([
            {'name': 'أبيض'},
            42,
          ]),
          [white],
        );
      },
    );
  });

  group('PrintColorsView', () {
    testWidgets('each ink shows its name and its code', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(
        host(const PrintColorsView(colors: [red, white])),
      );

      // Assert
      expect(find.text('أحمر الشعار'), findsOneWidget);
      expect(find.text('PANTONE 186 C'), findsOneWidget);
      expect(find.text('أبيض'), findsOneWidget);
    });

    testWidgets('the code is laid out left to right inside an Arabic screen', (
      tester,
    ) async {
      // Arrange — «C 186 PANTONE» is what a right-to-left line makes of it.
      await tester.pumpWidget(host(const PrintColorsView(colors: [red])));

      // Act
      final code = tester.widget<Text>(find.text('PANTONE 186 C'));

      // Assert
      expect(code.textDirection, TextDirection.ltr);
    });
  });

  group('PrintColorsField', () {
    testWidgets('a colour is added through the dialog with its name and code', (
      tester,
    ) async {
      // Arrange
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [],
            onChanged: (colors) => changed = colors,
          ),
        ),
      );

      // Act
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'اسم اللون'),
        'أحمر الشعار',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'رمز اللون'),
        'PANTONE 186 C',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();

      // Assert — no swatch chosen, so none is sent.
      expect(changed, [
        const PrintColor(name: 'أحمر الشعار', code: 'PANTONE 186 C'),
      ]);
    });

    testWidgets('a colour with no name cannot be saved', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(PrintColorsField(colors: const [], onChanged: (_) {})),
      );

      // Act
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'رمز اللون'),
        'PANTONE 186 C',
      );
      await tester.pump();

      // Assert — the server would refuse it, and this says so before the round trip.
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'حفظ'),
      );
      expect(save.onPressed, isNull);
    });

    testWidgets('a typed swatch is tidied into #RRGGBB', (tester) async {
      // Arrange
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [],
            onChanged: (colors) => changed = colors,
          ),
        ),
      );

      // Act — typed without the hash, in lower case.
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextField, 'اسم اللون'),
        'أزرق',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'رمز العيّنة'),
        '0033a0',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'حفظ'));
      await tester.pumpAndSettle();

      // Assert
      expect(changed?.single.hex, '#0033A0');
    });

    testWidgets('a chip is removed by its own button', (tester) async {
      // Arrange
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [red, white],
            onChanged: (colors) => changed = colors,
          ),
        ),
      );

      // Act
      await tester.tap(find.byTooltip('حذف اللون').first);
      await tester.pump();

      // Assert
      expect(changed, [white]);
    });

    testWidgets('the add button goes away at the limit', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: List.filled(PrintColor.max, white),
            onChanged: (_) {},
          ),
        ),
      );

      // Assert
      expect(find.text('إضافة لون'), findsNothing);
    });
  });
}
