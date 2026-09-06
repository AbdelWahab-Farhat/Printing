import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/shelf_balance_cubit.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouse_stocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Reading one shelf's balance while a movement is being written against it.
///
/// **The answer to an older question must never land last.** A storekeeper who picks the wrong
/// warehouse and corrects it fires two lookups; if the first replies second, the form quotes one
/// warehouse's balance under the other's name — which is worse than quoting none.
///
/// Arrange - Act - Assert throughout.
class _MockWarehouseRepository extends Mock implements WarehouseRepository {}

void main() {
  late _MockWarehouseRepository repository;
  late ShelfBalanceCubit cubit;

  const onShelf = WarehouseStock(
    id: 11,
    warehouseId: 3,
    stockItemId: 7,
    quantity: '800.000',
    unit: 'kilogram',
    unitLabel: 'كجم',
  );

  Paginated<WarehouseStock> pageOf(List<WarehouseStock> items) => Paginated<WarehouseStock>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 1, lastPage: 1, total: items.length),
  );

  setUp(() {
    repository = _MockWarehouseRepository();
    cubit = ShelfBalanceCubit(getStocks: GetWarehouseStocks(repository));
  });

  tearDown(() => cubit.close());

  test('asks the balances endpoint for the one shelf, and holds what came back', () async {
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
    ).thenAnswer((_) async => Right(pageOf([onShelf])));

    // Act
    await cubit.look(warehouseId: 3, stockItemId: 7);

    // Assert — one line asked for, one line held.
    expect(cubit.state, const ShelfBalanceState.loaded(onShelf));
    verify(() => repository.stocks(3, stockItemId: 7, perPage: 1)).called(1);
  });

  test('an empty page is a shelf holding nothing, not a failed lookup', () async {
    // Arrange — this size has never been in this warehouse, so there is no line for it.
    when(
      () => repository.stocks(
        any(),
        lowStock: any(named: 'lowStock'),
        inStock: any(named: 'inStock'),
        stockItemId: any(named: 'stockItemId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(pageOf(const [])));

    // Act
    await cubit.look(warehouseId: 4, stockItemId: 7);

    // Assert
    expect(cubit.state, const ShelfBalanceState.loaded(null));
  });

  test('a failure says nothing at all', () async {
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
    await cubit.look(warehouseId: 3, stockItemId: 7);

    // Assert — the form is usable without the figure; there is no banner to put over it.
    expect(cubit.state, const ShelfBalanceState.failure());
  });

  test('the answer to a question already replaced is dropped', () async {
    // Arrange — the first warehouse replies slowly, the second quickly.
    when(
      () => repository.stocks(
        3,
        lowStock: any(named: 'lowStock'),
        inStock: any(named: 'inStock'),
        stockItemId: any(named: 'stockItemId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 40));

      return Right(pageOf([onShelf]));
    });
    when(
      () => repository.stocks(
        4,
        lowStock: any(named: 'lowStock'),
        inStock: any(named: 'inStock'),
        stockItemId: any(named: 'stockItemId'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(pageOf(const [])));

    // Act — the storekeeper corrects the warehouse before the first answer lands.
    final slow = cubit.look(warehouseId: 3, stockItemId: 7);
    await cubit.look(warehouseId: 4, stockItemId: 7);
    await slow;

    // Assert — the second warehouse's answer stands.
    expect(cubit.state, const ShelfBalanceState.loaded(null));
  });

  test('clearing forgets both the figure and the request still in flight', () async {
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
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));

      return Right(pageOf([onShelf]));
    });

    // Act — the shelf is unpicked while its balance is being read.
    final inFlight = cubit.look(warehouseId: 3, stockItemId: 7);
    cubit.clear();
    await inFlight;

    // Assert — a figure nobody asked for any more never appears.
    expect(cubit.state, const ShelfBalanceState.initial());
  });
}
