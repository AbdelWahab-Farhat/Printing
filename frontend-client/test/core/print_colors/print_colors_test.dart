import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/print_colors/print_color.dart';
import 'package:dayaa_client/core/print_colors/print_colors_editor.dart';
import 'package:dayaa_client/core/print_colors/print_colors_view.dart';
import 'package:dayaa_client/core/widgets/app_button.dart';
import 'package:dayaa_client/core/widgets/app_color_picker.dart';
import 'package:dayaa_client/core/widgets/app_text_field.dart';
import 'package:dayaa_client/features/designs/models/customer_design.dart';
import 'package:dayaa_client/features/designs/presentation/viewmodel/designs_cubit.dart';
import 'package:dayaa_client/features/designs/repositories/design_repository.dart';
import 'package:dayaa_client/features/designs/usecases/choose_design_colors.dart';
import 'package:dayaa_client/features/designs/usecases/list_designs.dart';
import 'package:dayaa_client/features/designs/usecases/remove_design.dart';
import 'package:dayaa_client/features/designs/usecases/rename_design.dart';
import 'package:dayaa_client/features/designs/usecases/upload_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDesignRepository extends Mock implements DesignRepository {}

/// «ألوان الطباعة» من تطبيق العميل — PRINT-COLORS.md §8: الاسم واللون منه، والرمز من فريقنا.
///
/// Arrange - Act - Assert throughout.
void main() {
  const red = PrintColor(name: 'أحمر الشعار', hex: '#E4002B');

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
    test('what goes up is the name and the swatch — never a code', () {
      // Arrange — a colour read back with the code our team wrote.
      const confirmed = PrintColor(
        name: 'أحمر الشعار',
        code: 'PANTONE 186 C',
        hex: '#E4002B',
      );

      // Act
      final json = confirmed.toJson();

      // Assert
      expect(json, {'name': 'أحمر الشعار', 'hex': '#E4002B'});
    });

    test('a design reads its colours and whether they are locked', () {
      // Act
      final design = CustomerDesign.fromJson(const {
        'id': 1,
        'label': 'شعار',
        'print_colors': [
          {'name': 'أحمر الشعار', 'code': 'PANTONE 186 C', 'hex': '#E4002B'},
        ],
        'print_colors_locked': true,
      });

      // Assert
      expect(design.printColors.single.code, 'PANTONE 186 C');
      expect(design.printColorsLocked, isTrue);
    });

    test('a design from an older server has no colours and is not locked', () {
      // Act
      final design = CustomerDesign.fromJson(const {'id': 1, 'label': 'شعار'});

      // Assert
      expect(design.printColors, isEmpty);
      expect(design.printColorsLocked, isFalse);
    });
  });

  // الورقة أطول من شاشة الاختبار الافتراضية (٨٠٠×٦٠٠)، فتُفتح على مقاس الهاتف المرجعي.
  void phone(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(430 * 3, 932 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  // العنوان فوق الخانة لا داخلها في هذا التطبيق، فيُبحث عن الخانة داخل `AppTextField` صاحبه.
  Finder field(String label) => find.descendant(
    of: find.widgetWithText(AppTextField, label),
    matching: find.byType(TextField),
  );

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.widgetWithText(AppButton, 'حفظ'));
    await tester.pumpAndSettle();
  }

  group('PrintColorsField', () {
    testWidgets(
      'the customer names a colour and picks it — there is no box for a code',
      (tester) async {
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
        final area = find.byKey(AppColorPicker.saturationKey);
        await tester.tapAt(tester.getTopLeft(area) + const Offset(1, 1));
        await tester.pump();
        await save(tester);

        // Assert
        expect(changed?.single.name, 'أحمر الشعار');
        expect(changed?.single.hex, matches(RegExp(r'^#[0-9A-F]{6}$')));
      },
    );

    testWidgets('the name and the colour code share one row', (tester) async {
      // Arrange
      phone(tester);
      await tester.pumpWidget(
        host(PrintColorsField(colors: const [], onChanged: (_) {})),
      );

      // Act
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();

      // Assert — side by side, the name on the reading edge. Measured on the whole labelled
      // field: the test font draws every letter as a 1em box, so a label that fits on a phone in
      // Cairo may wrap here and push its box down.
      Rect whole(String label) => tester.getRect(find.widgetWithText(AppTextField, label));
      final name = whole('اسم اللون (اختياري)');
      final code = whole('كود اللون');
      expect(name.top, code.top);
      expect(name.left, greaterThan(code.right));
    });

    testWidgets('a colour is not saved until one is picked, and the sheet says so', (
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

      // Act — named, but no colour chosen.
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();
      await tester.enterText(field('اسم اللون (اختياري)'), 'أحمر');
      await tester.pump();
      await save(tester);

      // Assert — choosing the colour is the point of asking the customer.
      expect(changed, isNull);
      expect(find.text('اختر اللون'), findsOneWidget);
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

      // Assert — the server wants a name, so the code stands in for it.
      expect(changed, [const PrintColor(name: '#E4002B', hex: '#E4002B')]);
    });

    testWidgets('the colour code can be typed instead of picked', (tester) async {
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

      // Act — without the hash, in lower case.
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();
      await tester.enterText(field('اسم اللون (اختياري)'), 'أحمر الشعار');
      await tester.enterText(field('كود اللون'), 'e4002b');
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed, [red]);
    });

    testWidgets('one sheet holds every colour on the design', (tester) async {
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

      // Act — a second colour from the «+» at the end of the row.
      await tester.tap(find.byTooltip('إضافة لون'));
      await tester.pump();
      await tester.enterText(field('اسم اللون (اختياري)'), 'أسود');
      await tester.enterText(field('كود اللون'), '#000000');
      await tester.pump();
      await save(tester);

      // Assert
      expect(changed, [red, const PrintColor(name: 'أسود', hex: '#000000')]);
    });
  });

  testWidgets('the code our team wrote is shown, left to right', (
    tester,
  ) async {
    // Arrange / Act
    await tester.pumpWidget(
      host(
        const PrintColorsView(
          colors: [
            PrintColor(
              name: 'أحمر الشعار',
              code: 'PANTONE 186 C',
              hex: '#E4002B',
            ),
          ],
        ),
      ),
    );

    // Assert
    final code = tester.widget<Text>(find.text('PANTONE 186 C'));
    expect(code.textDirection, TextDirection.ltr);
  });

  group('PrintColorDots', () {
    testWidgets('بعد [max] يتوقّف الرسم ويُعدّ الباقي', (tester) async {
      // Arrange — ستة ألوان في سطرٍ واحد بجانب الحجم تفيض عن البطاقة.
      final six = List.filled(6, red);

      // Act
      await tester.pumpWidget(host(PrintColorDots(colors: six, max: 4)));

      // Assert
      expect(find.byType(PrintColorSwatch), findsNWidgets(4));
      expect(find.text('+2'), findsOneWidget);
    });

    testWidgets('ضمن [max] تُرسم الألوان كلها ولا يُعدّ شيء', (tester) async {
      // Arrange / Act
      await tester.pumpWidget(host(const PrintColorDots(colors: [red, red], max: 4)));

      // Assert
      expect(find.byType(PrintColorSwatch), findsNWidgets(2));
      expect(find.textContaining('+'), findsNothing);
    });
  });

  group('DesignsCubit.setColors', () {
    late _MockDesignRepository repository;

    const logo = CustomerDesign(
      id: 1,
      label: 'شعار المتجر',
      kind: DesignKind.image,
    );
    const coloured = CustomerDesign(
      id: 1,
      label: 'شعار المتجر',
      kind: DesignKind.image,
      printColors: [red],
    );

    setUp(() => repository = _MockDesignRepository());

    DesignsCubit build() => DesignsCubit(
      list: ListDesigns(repository),
      upload: UploadDesign(repository),
      rename: RenameDesign(repository),
      chooseColors: ChooseDesignColors(repository),
      remove: RemoveDesign(repository),
    );

    blocTest<DesignsCubit, DesignsState>(
      'swaps the design for the one the server answered with',
      build: () {
        when(
          () => repository.setColors(id: 1, colors: const [red]),
        ).thenAnswer((_) async => const Right(coloured));

        return build();
      },
      seed: () => const DesignsState.loaded([logo]),
      act: (cubit) => cubit.setColors(id: 1, colors: const [red]),
      expect: () => const [
        DesignsState.loaded([logo], isBusy: true),
        DesignsState.loaded([coloured]),
      ],
    );

    blocTest<DesignsCubit, DesignsState>(
      'a refusal — our team already wrote the codes — keeps the list and says why',
      build: () {
        when(() => repository.setColors(id: 1, colors: const [red])).thenAnswer(
          (_) async => const Left(
            ServerFailure(
              message: 'ألوان هذا التصميم اعتمدها فريقنا — لتغييرها تواصل معنا',
              statusCode: 422,
            ),
          ),
        );

        return build();
      },
      seed: () => const DesignsState.loaded([logo]),
      act: (cubit) => cubit.setColors(id: 1, colors: const [red]),
      expect: () => const [
        DesignsState.loaded([logo], isBusy: true),
        DesignsState.loaded(
          [logo],
          lastFailure: ServerFailure(
            message: 'ألوان هذا التصميم اعتمدها فريقنا — لتغييرها تواصل معنا',
            statusCode: 422,
          ),
        ),
      ],
    );
  });
}
