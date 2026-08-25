import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/products/models/product.dart';
import 'package:dayaa/features/products/presentation/viewmodel/products_cubit.dart';
import 'package:dayaa/features/products/repositories/product_repository.dart';
import 'package:dayaa/features/products/usecases/get_products.dart';
import 'package:dayaa/features/stock_items/presentation/widgets/variant_link_picker_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ticking the product sizes that draw on one material.
///
/// **What is being protected here is a replacement.** `PUT /stock-items/{id}/variants` makes the
/// list it is given true — what is missing comes off — so every id the sheet fails to carry back
/// is a link silently destroyed. The catalogue is paged and searchable, which means most of the
/// selection is off-screen most of the time; the answer therefore has to be «the set», never «the
/// boxes currently ticked in the tree».
///
/// Arrange - Act - Assert throughout.
class _StubRepository implements ProductRepository {
  _StubRepository(this._products);

  final List<Product> _products;

  @override
  Future<Either<Failure, Paginated<Product>>> products({
    String? search,
    int? productCategoryId,
    String? pricingUnit,
    bool? isActive,
    int page = 1,
    int perPage = 20,
  }) async {
    final matched = search == null || search.isEmpty
        ? _products
        : _products.where((p) => p.name.contains(search)).toList();

    return Right(
      Paginated<Product>(
        items: matched,
        meta: PageMeta(
          currentPage: 1,
          perPage: perPage,
          lastPage: 1,
          total: matched.length,
        ),
      ),
    );
  }

  @override
  Object noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  /// «كيس شحن 25*35» — the pile every size in this file is being pointed at or away from.
  const thisMaterial = 'كيس شحن 25*35';

  /// Another pile entirely. A size drawing on it is the one case that asks before it moves.
  const elsewhere = VariantStockItem(
    id: 9,
    code: 'S9',
    name: 'كيس ورقي',
    displayName: 'كيس ورقي 25*35',
    unit: 'piece',
    unitLabel: 'قطعة',
  );

  const bags = Product(
    id: 1,
    code: 'P1',
    slug: 'plain-bags',
    name: 'أكياس سادة',
    pricingUnit: 'piece',
    pricingUnitLabel: 'بالقطعة',
    pricingMode: 'tiered',
    pricingModeLabel: 'أسعار مدرجة',
    minOrderQuantity: '100.000',
    variants: [
      ProductVariant(id: 11, label: '25*35'),
      ProductVariant(id: 12, label: '35*40', stockItemId: 9, stockItem: elsewhere),
    ],
  );

  const printed = Product(
    id: 2,
    code: 'P2',
    slug: 'printed-bags',
    name: 'أكياس مطبوعة',
    pricingUnit: 'piece',
    pricingUnitLabel: 'بالقطعة',
    pricingMode: 'tiered',
    pricingModeLabel: 'أسعار مدرجة',
    minOrderQuantity: '100.000',
    variants: [ProductVariant(id: 21, label: '25*35')],
  );

  setUp(() async {
    await Injector.reset();

    sl.registerLazySingleton<GetProducts>(
      () => GetProducts(_StubRepository(const [bags, printed])),
    );
    sl.registerFactory<ProductsCubit>(() => ProductsCubit(getProducts: sl<GetProducts>()));
  });

  tearDown(Injector.reset);

  /// What the sheet answered, captured where the caller would keep it.
  Set<int>? answered;

  Widget host(Set<int> initial) {
    answered = null;

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
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () async {
                  answered = await showVariantLinkPicker(
                    context: context,
                    materialName: thisMaterial,
                    initial: initial,
                  );
                },
                child: const Text('افتح'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> open(WidgetTester tester, Set<int> initial) async {
    await tester.pumpWidget(host(initial));
    await tester.pumpAndSettle();
    await tester.tap(find.text('افتح'));
    await tester.pumpAndSettle();
  }

  testWidgets('the catalogue opens with what is already linked ticked', (tester) async {
    // Arrange & Act
    await open(tester, {11});
    await tester.tap(find.text('أكياس سادة'));
    await tester.pumpAndSettle();

    // Assert — the tick is the material's own answer, read back rather than inferred.
    final ticked = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(ticked.map((t) => t.value), [true, false]);
  });

  testWidgets('a size drawing on another material says so on its row', (tester) async {
    // Arrange & Act
    await open(tester, const <int>{});
    await tester.tap(find.text('أكياس سادة'));
    await tester.pumpAndSettle();

    // Assert — the fact that turns a tick into a move, said before the tick.
    expect(find.text('يسحب من «كيس ورقي 25*35»'), findsOneWidget);
  });

  testWidgets('moving a size off another material asks first, and a refusal leaves it', (
    tester,
  ) async {
    // Arrange
    await open(tester, const <int>{});
    await tester.tap(find.text('أكياس سادة'));
    await tester.pumpAndSettle();

    // Act — tick the one that is already eating from another pile, then decline.
    await tester.tap(find.text('35*40'));
    await tester.pumpAndSettle();
    expect(find.textContaining('يسحب حالياً من «كيس ورقي 25*35»'), findsOneWidget);
    await tester.tap(find.text('إلغاء'));
    await tester.pumpAndSettle();

    // Assert — declining a confirm must not do half of what accepting it would.
    final ticked = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(ticked.map((t) => t.value), [false, false]);
  });

  testWidgets('a size that draws on nothing is ticked without a question', (tester) async {
    // Arrange
    await open(tester, const <int>{});
    await tester.tap(find.text('أكياس سادة'));
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.text('25*35'));
    await tester.pumpAndSettle();

    // Assert — nothing is being taken away from anybody, so nothing is asked.
    expect(find.textContaining('يسحب حالياً'), findsNothing);
    final ticked = tester.widgetList<CheckboxListTile>(find.byType(CheckboxListTile));
    expect(ticked.first.value, isTrue);
  });

  testWidgets('ids the search never rendered are still in the answer', (tester) async {
    // Arrange — 21 belongs to «أكياس مطبوعة», and the search is about to hide that product
    // entirely. This is the case that would quietly unlink half a material.
    await open(tester, {21});

    // Act
    await tester.enterText(find.byType(TextField), 'سادة');
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
    expect(find.text('أكياس مطبوعة'), findsNothing);
    await tester.tap(find.text('أكياس سادة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25*35'));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('تم —'));
    await tester.pumpAndSettle();

    // Assert — the set, not the boxes on screen.
    expect(answered, {21, 11});
  });

  testWidgets('dismissing answers nothing, and the caller keeps what it had', (tester) async {
    // Arrange
    await open(tester, {11});

    // Act — the drag-down every sheet has, expressed as a back-press.
    await tester.tap(find.text('أكياس سادة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25*35'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('أكياس سادة'))).pop();
    await tester.pumpAndSettle();

    // Assert — null is «لم يُختر شيء», which is not the same as «اختير لا شيء».
    expect(answered, isNull);
  });
}
