import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/features/products/models/investability.dart';
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
  late _MockProductCategoryRepository repository;

  // `any(named: 'productionMode')` needs a value of the type to stand in for.
  setUpAll(() => registerFallbackValue(ProductionMode.inHouse));

  setUp(() {
    repository = _MockProductCategoryRepository();
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
  Widget host([ProductCategory seed = category]) => ScreenUtilInit(
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
              onPressed: () => showProductCategorySheet(context: context, category: seed),
              child: const Text('افتح'),
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester, [ProductCategory seed = category]) async {
    await tester.pumpWidget(host(seed));
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
    expect(find.text('مطبوعة'), findsOneWidget);
    expect(find.text('سادة'), findsWidgets);
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

  // ─────────────────────────── قابل للاستثمار ───────────────────────────

  testWidgets('a heading with nothing above it is offered two answers, not three', (
    tester,
  ) async {
    // Arrange - Act
    await open(tester);

    // Assert — «حسب الرئيسي» would be a segment with nothing to ask: this heading is a root.
    final picker = find.byType(SegmentedButton<Investability>);
    expect(picker, findsOneWidget);
    expect(find.text('نعم'), findsOneWidget);
    expect(find.text('لا'), findsOneWidget);
    expect(find.text('حسب الرئيسي'), findsNothing);

    final fieldWidth = tester.getSize(find.byType(TextField).first).width;
    expect(tester.getSize(picker).width, moreOrLessEquals(fieldWidth, epsilon: 2));
  });

  testWidgets('a heading nobody has decided about opens on «لا»', (tester) async {
    // Arrange - Act
    await open(tester);

    // Assert — fail-closed, and the same answer the server gives: nothing is fundable until
    // somebody says so.
    final segmented = tester.widget<SegmentedButton<Investability>>(
      find.byType(SegmentedButton<Investability>),
    );
    expect(segmented.selected, {Investability.no});
  });

  testWidgets('a subheading may hand the answer back to its parent', (tester) async {
    // Arrange — a child, left at null: «حسب الرئيسي».
    const child = ProductCategory(id: 6, name: 'أكياس ورقية', parentId: 3);

    // Act
    await open(tester, child);

    // Assert — three answers here, and it opens on the one it holds. This is the whole reason
    // the field is nullable: «لا» on a child means «استثنِ هذا الفرع», not «لم يُسأل عنه».
    expect(find.text('حسب الرئيسي'), findsOneWidget);
    final segmented = tester.widget<SegmentedButton<Investability>>(
      find.byType(SegmentedButton<Investability>),
    );
    expect(segmented.selected, {Investability.inherit});
  });

  testWidgets('a heading already open to investment opens on «نعم»', (tester) async {
    // Arrange
    const funded = ProductCategory(id: 7, name: 'أكياس', isInvestable: true);

    // Act
    await open(tester, funded);

    // Assert
    final segmented = tester.widget<SegmentedButton<Investability>>(
      find.byType(SegmentedButton<Investability>),
    );
    expect(segmented.selected, {Investability.yes});
  });

  testWidgets('the answer on the picker is what the save sends', (tester) async {
    // Arrange — the last link in the chain, and the one that would fail silently: a sheet that
    // draws the segments and drops them on submit looks right and changes nothing, while every
    // shelf under the heading stays refused by the deal sheet.
    when(
      () => repository.update(
        any(),
        name: any(named: 'name'),
        description: any(named: 'description'),
        sortOrder: any(named: 'sortOrder'),
        isActive: any(named: 'isActive'),
        productionMode: any(named: 'productionMode'),
        parentId: any(named: 'parentId'),
        isInvestable: any(named: 'isInvestable'),
      ),
    ).thenAnswer((_) async => const Right(category));
    await open(tester);

    // Act
    await tester.tap(find.text('نعم'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('حفظ'));
    await tester.pumpAndSettle();

    // Assert — and the rest of the row goes back untouched beside it: a PUT replaces the whole
    // representation, so anything left out is an answer given by accident.
    verify(
      () => repository.update(
        5,
        name: 'سادة',
        description: 'منتجات بلا طباعة، تُباع غالباً بالوزن.',
        sortOrder: 0,
        isActive: true,
        productionMode: ProductionMode.none,
        parentId: null,
        isInvestable: true,
      ),
    ).called(1);

    // The success toast holds a three-second dismissal timer of its own, and a timer still
    // pending when the tree is torn down fails the test. Let it run out.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });

  testWidgets('what the flag does is behind the question mark, not under the picker', (
    tester,
  ) async {
    // Arrange
    await open(tester);
    expect(find.textContaining('كل المنتجات النشطة'), findsNothing);

    // Act
    await tester.tap(find.byKey(const Key('investable-help')));
    await tester.pumpAndSettle();

    // Assert — the rule somebody would otherwise meet as a 422 on the deal sheet: the flag
    // opens headings, and a deal is opened against a shelf.
    expect(find.textContaining('كل المنتجات النشطة'), findsOneWidget);
  });
}
