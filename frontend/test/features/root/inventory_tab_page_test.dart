import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/widgets/app_tab_bar.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/root/presentation/views/inventory_tab_page.dart';
import 'package:dayaa/features/stock_items/models/stock_item.dart';
import 'package:dayaa/features/stock_items/presentation/viewmodel/stock_items_cubit.dart';
import 'package:dayaa/features/stock_items/repositories/stock_item_repository.dart';
import 'package:dayaa/features/stock_items/usecases/delete_stock_item.dart';
import 'package:dayaa/features/stock_items/usecases/get_stock_items.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/warehouses_cubit.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';
import 'package:dayaa/features/warehouses/usecases/delete_warehouse.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouses.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «المخزون» — المخازن and المواد as the same tabs الجهات uses.
///
/// The thing worth proving beyond the look is what swiping costs: the bodies each fetch on
/// create, so a tab that is disposed when it leaves the screen is a tab that re-reads the server
/// every time somebody comes back to it.
///
/// Arrange - Act - Assert throughout.
class _MockWarehouseRepository extends Mock implements WarehouseRepository {}

class _MockStockItemRepository extends Mock implements StockItemRepository {}

void main() {
  const main = Warehouse(
    id: 1,
    name: 'المخزن الرئيسي',
    type: WarehouseType.main,
    typeLabel: 'المخزن الرئيسي',
    stocksCount: 12,
  );

  late _MockWarehouseRepository warehouses;
  late _MockStockItemRepository items;

  Future<Either<Failure, Paginated<Warehouse>>> warehousesPage() => warehouses.warehouses(
    search: any(named: 'search'),
    page: any(named: 'page'),
    perPage: any(named: 'perPage'),
  );

  Future<Either<Failure, Paginated<StockItem>>> itemsPage() => items.items(
    search: any(named: 'search'),
    isActive: any(named: 'isActive'),
    widthCm: any(named: 'widthCm'),
    heightCm: any(named: 'heightCm'),
    page: any(named: 'page'),
    perPage: any(named: 'perPage'),
  );

  setUp(() async {
    await Injector.reset();

    warehouses = _MockWarehouseRepository();
    when(warehousesPage).thenAnswer(
      (_) async => const Right(
        Paginated<Warehouse>(
          items: [main],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 1),
        ),
      ),
    );
    sl.registerFactory<WarehousesCubit>(
      () => WarehousesCubit(
        getWarehouses: GetWarehouses(warehouses),
        deleteWarehouse: DeleteWarehouse(warehouses),
      ),
    );

    items = _MockStockItemRepository();
    when(itemsPage).thenAnswer(
      (_) async => const Right(
        Paginated<StockItem>(
          items: [],
          meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
        ),
      ),
    );
    sl.registerFactory<StockItemsCubit>(
      () => StockItemsCubit(
        getStockItems: GetStockItems(items),
        deleteStockItem: DeleteStockItem(items),
      ),
    );

    sl.registerSingleton<Session>(
      Session()..adopt(
        const AuthUser(
          id: 1,
          name: 'عبدالوهاب',
          phone: '0911234567',
          permissions: ['inventory.view'],
        ),
      ),
    );
  });

  tearDown(Injector.reset);

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
      home: Scaffold(body: InventoryTabPage()),
    ),
  );

  testWidgets('المخازن and المواد are tabs, drawn as الجهات draws its own', (tester) async {
    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the shared bar rather than the pill switch it replaced, and المخازن landing.
    expect(find.byType(AppTabBar), findsOneWidget);
    expect(find.byType(SegmentedButton<int>), findsNothing);
    expect(find.text('المخازن'), findsOneWidget);
    expect(find.text('المواد'), findsOneWidget);
    expect(find.text('المخزن الرئيسي'), findsWidgets);
  });

  testWidgets('going to المواد and back does not re-read either list', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — over and back again.
    await tester.tap(find.text('المواد'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('المخازن'));
    await tester.pumpAndSettle();

    // Assert — one request each: the tab swiped off stayed mounted, Cubit and all.
    verify(warehousesPage).called(1);
    verify(itemsPage).called(1);
    expect(find.text('المخزن الرئيسي'), findsWidgets);
  });

  testWidgets('a swipe changes the tab, as it does on الجهات', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act — right to left is «next» in an RTL app, so the finger moves left-to-right.
    await tester.fling(find.byType(TabBarView), const Offset(400, 0), 1000);
    await tester.pumpAndSettle();

    // Assert
    final controller = DefaultTabController.of(tester.element(find.byType(TabBarView)));
    expect(controller.index, 1);
  });
}
