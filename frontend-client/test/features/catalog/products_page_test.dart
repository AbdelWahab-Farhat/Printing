import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/di/injector.dart';
import 'package:dayaa_client/core/network/paginated.dart';
import 'package:dayaa_client/features/catalog/models/product.dart';
import 'package:dayaa_client/features/catalog/presentation/viewmodel/products_cubit.dart';
import 'package:dayaa_client/features/catalog/presentation/views/products_page.dart';
import 'package:dayaa_client/features/catalog/repositories/catalog_repository.dart';
import 'package:dayaa_client/features/catalog/usecases/browse_products.dart';
import 'package:dayaa_client/features/catalog/usecases/list_categories.dart';
import 'package:dayaa_client/features/orders/models/customer_order.dart';
import 'package:dayaa_client/features/orders/models/order_draft.dart';
import 'package:dayaa_client/features/orders/presentation/viewmodel/cart_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCatalogRepository extends Mock implements CatalogRepository {}

/// «المنتجات» بلا شريطٍ علويٍّ خاص: تلبس شريط الـ shell الذي تلبسه الرئيسية و«طلباتي»، والسلة فيه
/// لا عائمةً فوق الشبكة (طلب المستخدم، 2026-09-25).
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockCatalogRepository repository;

  setUp(() {
    repository = _MockCatalogRepository();
    when(() => repository.categories()).thenAnswer((_) async => const Right([]));
    when(
      () => repository.products(
        page: any(named: 'page'),
        search: any(named: 'search'),
        categoryId: any(named: 'categoryId'),
      ),
    ).thenAnswer(
      (_) async => const Right(
        Paginated<Product>(
          items: [Product(id: 1, name: 'كروت'), Product(id: 2, name: 'ستيكرات')],
          meta: PageMeta(currentPage: 1, perPage: 15, lastPage: 1, total: 2),
        ),
      ),
    );

    sl
      ..registerFactory(
        () => ProductsCubit(
          browse: BrowseProducts(repository),
          categories: ListCategories(repository),
        ),
      )
      ..registerLazySingleton<CartCubit>(CartCubit.new);

    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = const Size(430, 932);
    view.devicePixelRatio = 1;
  });

  tearDown(() async {
    final view = TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.resetPhysicalSize();
    view.resetDevicePixelRatio();
    await sl.reset();
  });

  Widget host() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ProductsPage(),
    ),
  );

  testWidgets('the catalogue draws no top bar of its own, and nothing floats over the grid', (
    tester,
  ) async {
    // Arrange — شيءٌ في السلة، فلو رسمت الصفحة سلّتها لظهرت.
    sl<CartCubit>().add(
      const OrderDraftLine(
        line: NewOrderLine(productId: 1, productVariantId: 1, quantity: '100'),
        title: 'كروت',
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — السلة في شريط الـ shell المشترك (`HomeAppBar`)، والزرّ العائم كان يغطّي سعرَ
    // البطاقة التي تحته.
    expect(find.byType(AppBar), findsNothing);
    expect(find.byTooltip('سلتك'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });
}
