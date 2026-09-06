import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/record_movement_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/shelf_balance_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/views/record_movement_page.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouse_stocks.dart';
import 'package:dayaa/features/warehouses/usecases/record_stock_movement.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The form that writes a line into the ledger, opened from a shelf.
///
/// **The warehouse it was opened from is an answer, not a missing one.** The destination picker
/// is deliberately not drawn in that case — the storekeeper already stood on the shelf — so a
/// form that read the destination off the picker alone refused every movement with «اختر مخزن
/// الاستلام» and offered no box to answer it in.
///
/// **And it says what is on that shelf before anything is typed.** «تسوية بالنقص ٢٠٠» is a
/// different decision on a shelf holding ٨٠٠ than on one holding nothing, and the storekeeper
/// used to learn which only from the server's refusal, after the whole form had been filled in.
///
/// Arrange - Act - Assert throughout.
class _MockWarehouseRepository extends Mock implements WarehouseRepository {}

void main() {
  late _MockWarehouseRepository repository;

  const movement = StockMovement(
    id: 900,
    movementType: MovementType.purchaseArrival,
    movementTypeLabel: 'توريد',
    quantity: '20.000',
    stockItemId: 7,
    toWarehouseId: 3,
  );

  /// The shelf and the warehouse the storekeeper is standing on — «اكياس سادة · المخزن الرئيسي».
  const shelf = MovementContext(
    stockItemId: 7,
    stockItemName: 'اكياس سادة وكل شي',
    warehouseId: 3,
    warehouseName: 'المخزن الرئيسي',
    unitLabel: 'كجم',
  );

  /// What the shelf holds, as the balances endpoint answers for one size.
  const onShelf = WarehouseStock(
    id: 11,
    warehouseId: 3,
    stockItemId: 7,
    quantity: '800.000',
    unit: 'kilogram',
    unitLabel: 'كجم',
  );

  Paginated<WarehouseStock> page_(List<WarehouseStock> items) => Paginated<WarehouseStock>(
    items: items,
    meta: PageMeta(
      currentPage: 1,
      perPage: 1,
      lastPage: 1,
      total: items.length,
    ),
  );

  void stubBalance(List<WarehouseStock> items) {
    when(
      () => repository.stocks(
        any(),
        lowStock: any(named: 'lowStock'),
        inStock: any(named: 'inStock'),
        stockItemId: any(named: 'stockItemId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(page_(items)));
  }

  setUp(() async {
    await Injector.reset();

    repository = _MockWarehouseRepository();

    sl
      ..registerLazySingleton<RecordStockMovement>(() => RecordStockMovement(repository))
      ..registerLazySingleton<GetWarehouseStocks>(() => GetWarehouseStocks(repository))
      ..registerFactory<RecordMovementCubit>(
        () => RecordMovementCubit(recordMovement: sl<RecordStockMovement>()),
      )
      ..registerFactory<ShelfBalanceCubit>(
        () => ShelfBalanceCubit(getStocks: sl<GetWarehouseStocks>()),
      );

    stubBalance([onShelf]);
  });

  tearDown(Injector.reset);

  Widget page() => ScreenUtilInit(
    designSize: const Size(430, 932),
    builder: (context, _) => const MaterialApp(
      locale: Locale('ar'),
      supportedLocales: [Locale('ar')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: RecordMovementPage(context: shelf),
    ),
  );

  testWidgets('an arrival on a fixed shelf posts to the warehouse it was opened from', (
    tester,
  ) async {
    // Arrange
    when(
      () => repository.recordArrival(
        stockItemId: any(named: 'stockItemId'),
        toWarehouseId: any(named: 'toWarehouseId'),
        quantity: any(named: 'quantity'),
        unitCost: any(named: 'unitCost'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(movement));

    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    // Act — the only two questions the form still asks on a fixed shelf.
    await tester.enterText(find.widgetWithText(TextFormField, 'الكمية (كجم)'), '20');
    await tester.enterText(
      find.widgetWithText(TextFormField, 'تكلفة الوحدة (لكل كجم)'),
      '50',
    );
    await tester.tap(find.widgetWithText(InkWell, 'تسجيل'));
    // Long enough for the success snack to come and go: it animates on a ticker the popped
    // page's navigator owns, and a test that ends mid-flight fails on the pending timer.
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Assert — it reached the server against المخزن الرئيسي, and did not stop to ask for it.
    expect(find.text('اختر مخزن الاستلام'), findsNothing);
    verify(
      () => repository.recordArrival(
        stockItemId: 7,
        toWarehouseId: 3,
        quantity: '20',
        unitCost: '50',
        notes: null,
      ),
    ).called(1);
  });

  testWidgets('it says what is on the shelf, named after the warehouse it read', (tester) async {
    // Arrange
    stubBalance([onShelf]);

    // Act
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    // Assert — the balance is there before anything is typed, with its unit and its warehouse.
    expect(find.text('الرصيد الحالي في المخزن الرئيسي'), findsOneWidget);
    expect(find.text('800 كجم'), findsOneWidget);
    verify(
      () => repository.stocks(3, stockItemId: 7, perPage: 1),
    ).called(1);
  });

  testWidgets('a warehouse that has never held this size reads zero, not nothing', (
    tester,
  ) async {
    // Arrange — the balances endpoint has no line for this pair at all.
    stubBalance([]);

    // Act
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    // Assert — counted in the item's own unit, because there is no shelf to take one from.
    expect(find.text('0 كجم'), findsOneWidget);
  });

  testWidgets('a balance that could not be read takes itself away', (tester) async {
    // Arrange
    when(
      () => repository.stocks(
        any(),
        lowStock: any(named: 'lowStock'),
        inStock: any(named: 'inStock'),
        stockItemId: any(named: 'stockItemId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => const Left(Failure.server(message: 'تعذّر القراءة')));

    // Act
    await tester.pumpWidget(page());
    await tester.pumpAndSettle();

    // Assert — the form is perfectly usable without the figure, so nothing is said.
    expect(find.textContaining('الرصيد الحالي'), findsNothing);
    expect(find.widgetWithText(TextFormField, 'الكمية (كجم)'), findsOneWidget);
  });
}
