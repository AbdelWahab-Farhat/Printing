import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/core/print_colors/print_color.dart';
import 'package:dayaa_client/core/print_colors/print_colors_editor.dart';
import 'package:dayaa_client/core/print_colors/print_colors_view.dart';
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

  group('PrintColorsField', () {
    testWidgets(
      'the customer names a colour and picks it — there is no box for a code',
      (tester) async {
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
        // One box — the name. The label sits outside the field in this app, so it is found by type.
        expect(find.text('رمز اللون'), findsNothing);
        expect(find.byType(TextField), findsOneWidget);
        await tester.enterText(find.byType(TextField), 'أحمر الشعار');
        await tester.tap(find.bySemanticsLabel('#E4002B'));
        await tester.pump();
        await tester.tap(find.widgetWithText(TextButton, 'حفظ'));
        await tester.pumpAndSettle();

        // Assert
        expect(changed, [red]);
      },
    );

    testWidgets('a colour cannot be saved until one is picked', (tester) async {
      // Arrange
      await tester.pumpWidget(
        host(PrintColorsField(colors: const [], onChanged: (_) {})),
      );

      // Act — named, but no swatch chosen.
      await tester.tap(find.text('إضافة لون'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'أحمر');
      await tester.pump();

      // Assert — choosing the colour is the point of asking the customer.
      final save = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'حفظ'),
      );
      expect(save.onPressed, isNull);
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
