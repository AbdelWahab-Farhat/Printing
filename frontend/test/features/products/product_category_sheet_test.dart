import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/features/products/models/product_category.dart';
import 'package:dayaa/features/products/models/production_mode.dart';
import 'package:dayaa/features/products/presentation/viewmodel/save_product_category_cubit.dart';
import 'package:dayaa/features/products/presentation/widgets/product_category_sheet.dart';
import 'package:dayaa/features/products/repositories/product_category_repository.dart';
import 'package:dayaa/features/products/usecases/save_product_category.dart';
import 'package:dayaa/features/products/usecases/set_product_category_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The sheet that adds or edits a catalogue heading, as it is laid out.
///
/// Three things the owner asked for on seeing it: the picture first, the mode's three answers
/// across the whole width, and the explanation of each answer kept out of the way — behind a
/// question mark and a long press — rather than printed under the picker on every visit.
///
/// Arrange - Act - Assert throughout.
class _MockProductCategoryRepository extends Mock implements ProductCategoryRepository {}

void main() {
  setUp(() {
    final repository = _MockProductCategoryRepository();
    sl.registerFactory<SaveProductCategoryCubit>(
      () => SaveProductCategoryCubit(
        saveCategory: SaveProductCategory(repository),
        setImage: SetProductCategoryImage(repository),
      ),
    );
  });

  tearDown(() => sl.reset());

  const category = ProductCategory(
    id: 5,
    name: 'سادة',
    description: 'منتجات بلا طباعة، تُباع غالباً بالوزن.',
    productionMode: ProductionMode.none,
  );

  /// A page with one button that opens the sheet, the way the categories screen does.
  Widget host() => ScreenUtilInit(
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
            child: TextButton(
              onPressed: () => showProductCategorySheet(context: context, category: category),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(host());
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('the title stands alone, with no sentence under it', (tester) async {
    // Arrange - Act
    await open(tester);

    // Assert
    expect(find.text('تعديل التصنيف'), findsOneWidget);
    expect(find.textContaining('العنوان الذي تُعرض تحته المنتجات'), findsNothing);
  });

  testWidgets('the picture comes before the name', (tester) async {
    // Arrange - Act
    await open(tester);

    // Assert — higher on the sheet means a smaller y.
    final picture = tester.getTopLeft(find.text('صورة التصنيف')).dy;
    final name = tester.getTopLeft(find.text('اسم التصنيف')).dy;
    expect(picture, lessThan(name));
  });

  testWidgets('the three modes span the sheet and open on the heading\'s own', (
    tester,
  ) async {
    // Arrange - Act
    await open(tester);

    // Assert — one segment per mode, the row as wide as the fields above it.
    final picker = find.byType(SegmentedButton<ProductionMode>);
    expect(picker, findsOneWidget);
    expect(find.text('تصميم وطباعة'), findsOneWidget);
    expect(find.text('بدون طباعة'), findsOneWidget);
    expect(find.text('وسيط'), findsOneWidget);

    final fieldWidth = tester.getSize(find.byType(TextField).first).width;
    expect(tester.getSize(picker).width, moreOrLessEquals(fieldWidth, epsilon: 2));

    final segmented = tester.widget<SegmentedButton<ProductionMode>>(picker);
    expect(segmented.selected, {ProductionMode.none});
  });

  testWidgets('what each mode does is behind the question mark, not under the picker', (
    tester,
  ) async {
    // Arrange
    await open(tester);
    expect(find.textContaining('نصمّمها ونطبعها هنا'), findsNothing);
    expect(find.textContaining('يصنعها مورد خارجي'), findsNothing);

    // Act
    await tester.tap(find.byKey(const Key('production-mode-help')));
    await tester.pumpAndSettle();

    // Assert — all three, together, so the choice can be compared rather than read one at a
    // time.
    expect(find.textContaining('نصمّمها ونطبعها هنا'), findsOneWidget);
    expect(find.textContaining('جاهزة من الرفّ'), findsOneWidget);
    expect(find.textContaining('يصنعها مورد خارجي'), findsOneWidget);
  });

  testWidgets('a long press on a segment says what it does', (tester) async {
    // Arrange
    await open(tester);

    // Act
    await tester.longPress(find.text('وسيط'));
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('يصنعها مورد خارجي'), findsOneWidget);
  });
}
