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

/// شريط «المنتجات» العلوي: السلة فيه لا عائمةً فوق الشبكة، ولا جرس (طلب المستخدم، 2026-09-25).
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

  testWidgets('the basket sits in the top bar, not floating over the grid', (tester) async {
    // Arrange
    sl<CartCubit>().add(
      const OrderDraftLine(
        line: NewOrderLine(productId: 1, productVariantId: 1, quantity: '100'),
        title: 'كروت',
      ),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — الزرّ العائم كان يغطّي سعرَ البطاقة التي تحته.
    expect(
      find.descendant(of: find.byType(AppBar), matching: find.byTooltip('سلتك')),
      findsOneWidget,
    );
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('the bar has no bell', (tester) async {
    // Arrange
    final app = host();

    // Act
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    // Assert — لا خادمَ للإشعارات بعد، فالجرس زرٌّ لا يفعل شيئاً.
    expect(find.byTooltip('الإشعارات'), findsNothing);
  });
}
