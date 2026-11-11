import 'package:dayaa/core/print_colors/print_color.dart';
import 'package:dayaa/core/print_colors/print_colors_editor.dart';
import 'package:dayaa/core/print_colors/print_colors_view.dart';
import 'package:dayaa/core/widgets/app_button.dart';
import 'package:dayaa/core/widgets/app_color_picker.dart';
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
  const white = PrintColor(name: 'أبيض', hex: '#FFFFFF');

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
            {'name': 'أبيض', 'hex': '#FFFFFF'},
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

    testWidgets('a colour with no press code says nothing about it', (
      tester,
    ) async {
      // Arrange / Act
      await tester.pumpWidget(host(const PrintColorsView(colors: [white])));

      // Assert — the box is gone, so a missing code is no longer something to flag.
      expect(find.text('أبيض'), findsOneWidget);
      expect(find.text('بلا رمز'), findsNothing);
    });
  });

  group('PrintColorDots', () {
    testWidgets('past [max] it stops drawing and counts the rest', (tester) async {
      // Arrange — ستة ألوان في سطرٍ واحد بجانب الحجم تفيض عن البطاقة.
      const six = [red, white, red, white, red, white];

      // Act
      await tester.pumpWidget(host(const PrintColorDots(colors: six, max: 4)));

      // Assert
      expect(find.byType(PrintColorSwatch), findsNWidgets(4));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('within [max] every ink is drawn and nothing is counted', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(host(const PrintColorDots(colors: [red, white], max: 4)));

      // Assert
      expect(find.byType(PrintColorSwatch), findsNWidgets(2));
      expect(find.textContaining('+'), findsNothing);
    });
  });

  // الورقة أطول من شاشة الاختبار الافتراضية (٨٠٠×٦٠٠)، فتُفتح على مقاس الهاتف المرجعي.
  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Finder field(String label) => find.widgetWithText(TextField, label);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'حفظ'));
    await tester.pumpAndSettle();
  }

  group('PrintColorsField', () {
    testWidgets('a colour is added with its name and its colour code — no box for a press code', (
      tester,
    ) async {
      // Arrange
      phone(tester);
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
      expect(find.text('رمز المطبعة'), findsNothing);
      await tester.enterText(field('اسم اللون (اختياري)'), 'أحمر الشعار');
      await tester.enterText(field('كود اللون'), '#E4002B');
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed, [const PrintColor(name: 'أحمر الشعار', hex: '#E4002B')]);
    });

    testWidgets('the name and the colour code share one row', (tester) async {
      // Arrange
      phone(tester);
      await tester.pumpWidget(
        host(PrintColorsField(colors: const [], onChanged: (_) {})),
      );

      // Act
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();

      // Assert — side by side, the name on the reading edge.
      final name = tester.getRect(field('اسم اللون (اختياري)'));
      final code = tester.getRect(field('كود اللون'));
      expect(name.center.dy, code.center.dy);
      expect(name.left, greaterThan(code.right));
    });

    testWidgets('a press code already on record survives an edit', (tester) async {
      // Arrange — written before the box was hidden.
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [red],
            onChanged: (colors) => changed = colors,
          ),
        ),
      );
      await tester.tap(find.text('أحمر الشعار'));
      await tester.pumpAndSettle();

      // Act
      await tester.enterText(field('اسم اللون (اختياري)'), 'أحمر');
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed, [
        const PrintColor(name: 'أحمر', code: 'PANTONE 186 C', hex: '#E4002B'),
      ]);
    });

    testWidgets('a colour with no name is saved under its colour code', (
      tester,
    ) async {
      // Arrange
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [],
            onChanged: (colors) => changed = colors,
          ),
        ),
      );

      // Act — the name is optional.
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();
      await tester.enterText(field('كود اللون'), '#E4002B');
      await tester.pump();
      await save(tester);

      // Assert — the server wants a name, so the code stands in for it and is what the chip shows.
      expect(changed, [const PrintColor(name: '#E4002B', hex: '#E4002B')]);
    });

    testWidgets('reopened, a colour saved under its code shows an empty name box', (
      tester,
    ) async {
      // Arrange
      phone(tester);
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [PrintColor(name: '#E4002B', hex: '#E4002B')],
            onChanged: (_) {},
          ),
        ),
      );

      // Act
      await tester.tap(find.text('#E4002B'));
      await tester.pumpAndSettle();

      // Assert
      final name = tester.widget<TextField>(field('اسم اللون (اختياري)'));
      expect(name.controller?.text, isEmpty);
    });

    testWidgets('a typed colour code is tidied into #RRGGBB', (tester) async {
      // Arrange
      phone(tester);
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
      await tester.enterText(field('اسم اللون (اختياري)'), 'أزرق');
      await tester.enterText(field('كود اللون'), '0033a0');
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed?.single.hex, '#0033A0');
    });

    testWidgets('the picker gives the colour its swatch and writes its code', (
      tester,
    ) async {
      // Arrange
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [],
            onChanged: (colors) => changed = colors,
          ),
        ),
      );
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();
      await tester.enterText(field('اسم اللون (اختياري)'), 'أحمر');

      // Act — the top-left corner is the full colour in an Arabic screen.
      final area = find.byKey(AppColorPicker.saturationKey);
      await tester.tapAt(tester.getTopLeft(area) + const Offset(1, 1));
      await tester.pump();

      // Assert — the code box follows the picker, and the swatch is saved.
      final typed = tester.widget<TextField>(field('كود اللون'));
      expect(typed.controller?.text, matches(RegExp(r'^#[0-9A-F]{6}$')));
      await save(tester);
      expect(changed?.single.hex, typed.controller?.text);
    });

    testWidgets('one sheet edits every colour on the design, each slot its own', (
      tester,
    ) async {
      // Arrange — two colours on record; the sheet opens on the one tapped.
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [red, white],
            onChanged: (colors) => changed = colors,
          ),
        ),
      );
      await tester.tap(find.text('أبيض'));
      await tester.pumpAndSettle();
      final name = tester.widget<TextField>(field('اسم اللون (اختياري)'));
      expect(name.controller?.text, 'أبيض');

      // Act — back to the first, then a third colour from the presets.
      await tester.tap(find.bySemanticsLabel('اللون 1'));
      await tester.pump();
      expect(name.controller?.text, 'أحمر الشعار');
      await tester.tap(find.byTooltip('إضافة لون'));
      await tester.pump();
      await tester.tap(find.byTooltip('ذهبي'));
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed, [red, white, const PrintColor(name: 'ذهبي', hex: '#C9A227')]);
    });

    testWidgets('the selected colour is removed from inside the sheet', (
      tester,
    ) async {
      // Arrange
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [red, white],
            onChanged: (colors) => changed = colors,
          ),
        ),
      );
      await tester.tap(find.text('أحمر الشعار'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byTooltip('حذف هذا اللون'));
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed, [white]);
    });

    testWidgets('an empty slot stops the save and the sheet names it', (
      tester,
    ) async {
      // Arrange — a two-colour design with only the first colour picked.
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [red],
            onChanged: (colors) => changed = colors,
          ),
        ),
      );

      // Act
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();
      await save(tester);

      // Assert — nothing sent, and slot 2 is the one asked for.
      expect(changed, isNull);
      expect(find.textContaining('اللون 2'), findsOneWidget);
      expect(find.text('اختر اللون'), findsOneWidget);
    });

    testWidgets('a preset gives the slot its swatch and its name', (tester) async {
      // Arrange
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(PrintColorsField(colors: const [], onChanged: (colors) => changed = colors)),
      );
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byTooltip('أزرق'));
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed, [const PrintColor(name: 'أزرق', hex: '#0057B8')]);
    });

    testWidgets('a preset keeps a name somebody typed', (tester) async {
      // Arrange
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(PrintColorsField(colors: const [], onChanged: (colors) => changed = colors)),
      );
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();
      await tester.enterText(field('اسم اللون (اختياري)'), 'لون الشعار');
      await tester.pump();

      // Act — one preset, then another: the typed name survives both.
      await tester.tap(find.byTooltip('أحمر'));
      await tester.pump();
      await tester.tap(find.byTooltip('أسود'));
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed, [const PrintColor(name: 'لون الشعار', hex: '#000000')]);
    });

    testWidgets('picking another preset replaces the name the last one wrote', (tester) async {
      // Arrange
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(PrintColorsField(colors: const [], onChanged: (colors) => changed = colors)),
      );
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();

      // Act
      await tester.tap(find.byTooltip('أحمر'));
      await tester.pump();
      await tester.tap(find.byTooltip('أصفر'));
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed, [const PrintColor(name: 'أصفر', hex: '#FFD100')]);
    });

    testWidgets('«عدد الألوان» makes that many slots, and each must be filled', (tester) async {
      // Arrange
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(PrintColorsField(colors: const [], onChanged: (colors) => changed = colors)),
      );
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();

      // Act — two colours; only the first picked.
      await tester.tap(find.widgetWithText(ChoiceChip, '2'));
      await tester.pump();
      expect(find.bySemanticsLabel('اللون 2'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('اللون 1'));
      await tester.pump();
      await tester.tap(find.byTooltip('أسود'));
      await tester.pump();
      await save(tester);

      // Assert — refused, and slot 2 is opened.
      expect(changed, isNull);
      expect(find.textContaining('اللون 2'), findsOneWidget);

      // Act — the second picked.
      await tester.tap(find.byTooltip('ذهبي'));
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed, [
        const PrintColor(name: 'أسود', hex: '#000000'),
        const PrintColor(name: 'ذهبي', hex: '#C9A227'),
      ]);
    });

    testWidgets('«إلغاء» leaves the colours as they were', (tester) async {
      // Arrange
      phone(tester);
      List<PrintColor>? changed;
      await tester.pumpWidget(
        host(
          PrintColorsField(
            colors: const [red],
            onChanged: (colors) => changed = colors,
          ),
        ),
      );
      await tester.tap(find.text('أحمر الشعار'));
      await tester.pumpAndSettle();
      await tester.enterText(field('اسم اللون (اختياري)'), 'أحمر');

      // Act
      await tester.tap(find.widgetWithText(AppButton, 'إلغاء'));
      await tester.pumpAndSettle();

      // Assert
      expect(changed, isNull);
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

  group('showPrintColorsSheet', () {
    testWidgets('a design with no colours opens on one empty slot, and saves none', (
      tester,
    ) async {
      // Arrange
      phone(tester);
      List<PrintColor>? saved;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async =>
                  saved = await showPrintColorsSheet(context: context, initial: const []),
              child: const Text('افتح'),
            ),
          ),
        ),
      );

      // Act
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('اللون 1'), findsOneWidget);
      await save(tester);

      // Assert — an empty list, not null: «حفظ» was pressed.
      expect(saved, isEmpty);
    });

    testWidgets('where colours are required, an untouched sheet does not save', (tester) async {
      // Arrange
      phone(tester);
      List<PrintColor>? saved;
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => saved = await showPrintColorsSheet(
                context: context,
                initial: const [],
                required: true,
              ),
              child: const Text('افتح'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('افتح'));
      await tester.pumpAndSettle();

      // Act
      await save(tester);

      // Assert — still open, asking for colour 1.
      expect(saved, isNull);
      expect(find.text('اختر اللون'), findsOneWidget);

      // Act — removing the only slot does not get round it either.
      await tester.tap(find.byTooltip('حذف هذا اللون'));
      await tester.pump();
      await save(tester);

      // Assert
      expect(saved, isNull);
      expect(find.bySemanticsLabel('اللون 1'), findsOneWidget);
    });
  });
}
