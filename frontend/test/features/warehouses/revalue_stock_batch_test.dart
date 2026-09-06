import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/warehouses/models/stock_batch.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/stock_batches_cubit.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';
import 'package:dayaa/features/warehouses/usecases/get_stock_batches.dart';
import 'package:dayaa/features/warehouses/usecases/revalue_stock_batch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Correcting what a quantity of stock is carried at, from the shelf's own screen.
///
/// Two things are under test and they are different questions: **what reaches the API** — an
/// Arabic-Indic figure typed on the storekeeper's keyboard is `3.5` by the time it is sent, and
/// an untouched quantity box is no key at all rather than a zero — and **what the list does
/// afterwards**, which turns on whether the layer split.
///
/// Arrange - Act - Assert throughout.
class _MockWarehouseRepository extends Mock implements WarehouseRepository {}

void main() {
  late _MockWarehouseRepository repository;

  StockBatch batch({
    int id = 40,
    String unitCost = '0.000',
    String received = '500.000',
    String remaining = '300.000',
  }) => StockBatch(
    id: id,
    warehouseId: 1,
    stockItemId: 7,
    unitCost: unitCost,
    quantityReceived: received,
    quantityRemaining: remaining,
    quantityConsumed: '200.000',
    unit: 'piece',
    unitLabel: 'قطعة',
    sourceType: 'purchase_arrival',
    sourceTypeLabel: 'توريد',
    receivedAt: DateTime(2026, 8, 31),
    canBeRevalued: true,
  );

  Paginated<StockBatch> pageOf(List<StockBatch> items) => Paginated<StockBatch>(
    items: items,
    meta: PageMeta(currentPage: 1, perPage: 50, lastPage: 1, total: items.length),
  );

  StockBatchesCubit buildCubit() => StockBatchesCubit(
    getBatches: GetStockBatches(repository),
    revalueBatch: RevalueStockBatch(repository),
    warehouseId: 1,
    stockItemId: 7,
  );

  setUp(() {
    repository = _MockWarehouseRepository();

    when(
      () => repository.stockBatches(
        warehouseId: any(named: 'warehouseId'),
        stockItemId: any(named: 'stockItemId'),
        remaining: any(named: 'remaining'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => Right(pageOf([batch()])));

    when(
      () => repository.revalueStockBatch(
        any(),
        unitCost: any(named: 'unitCost'),
        quantity: any(named: 'quantity'),
        reason: any(named: 'reason'),
      ),
    ).thenAnswer((_) async => Right(batch(unitCost: '3.500')));
  });

  group('what reaches the API', () {
    test('an Arabic-Indic price with the keyboard\'s decimal mark is sent as a number', () async {
      // Arrange
      final revalue = RevalueStockBatch(repository);

      // Act
      await revalue(batchId: 40, unitCost: '٣٫٥', reason: '  فاتورة المورد وصلت بسعر مختلف  ');

      // Assert — and the reason trimmed, because the API measures its length.
      verify(
        () => repository.revalueStockBatch(
          40,
          unitCost: '3.5',
          quantity: null,
          reason: 'فاتورة المورد وصلت بسعر مختلف',
        ),
      ).called(1);
    });

    test('an untouched quantity box means «كل المتبقي», never a zero', () async {
      // Arrange
      final revalue = RevalueStockBatch(repository);

      // Act
      await revalue(batchId: 40, unitCost: '3.5', quantity: '   ', reason: 'تصحيح');

      // Assert — omitting the key is what asks the server for the whole layer; `'0'` would be a
      // quantity it refuses.
      verify(
        () => repository.revalueStockBatch(
          40,
          unitCost: '3.5',
          quantity: null,
          reason: 'تصحيح',
        ),
      ).called(1);
    });

    test('a named quantity travels as typed, in western digits', () async {
      // Arrange
      final revalue = RevalueStockBatch(repository);

      // Act
      await revalue(batchId: 40, unitCost: '3.5', quantity: '١٠٠', reason: 'تصحيح');

      // Assert
      verify(
        () => repository.revalueStockBatch(
          40,
          unitCost: '3.5',
          quantity: '100',
          reason: 'تصحيح',
        ),
      ).called(1);
    });
  });

  group('what the list does afterwards', () {
    test('correcting the whole layer patches the row it came back with', () async {
      // Arrange
      final cubit = buildCubit();
      await cubit.load();

      // Act
      final failure = await cubit.revalue(
        batch(),
        unitCost: '3.5',
        reason: 'فاتورة المورد وصلت بسعر مختلف',
      );

      // Assert — one read at load, and no second one: the corrected layer was in hand.
      expect(failure, isNull);

      final state = cubit.state as StockBatchesLoaded;
      expect(state.page.items.single.unitCost, '3.500');
      verify(
        () => repository.stockBatches(
          warehouseId: any(named: 'warehouseId'),
          stockItemId: any(named: 'stockItemId'),
          remaining: any(named: 'remaining'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).called(1);

      await cubit.close();
    });

    test('correcting part of a layer re-reads, because the split off row is new', () async {
      // Arrange — the server answers with the parent holding only what was repriced; the
      // remainder is now a row this list has never seen and whose id is the server's to mint.
      final cubit = buildCubit();
      await cubit.load();

      when(
        () => repository.revalueStockBatch(
          any(),
          unitCost: any(named: 'unitCost'),
          quantity: any(named: 'quantity'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer((_) async => Right(batch(unitCost: '3.500', remaining: '100.000')));

      when(
        () => repository.stockBatches(
          warehouseId: any(named: 'warehouseId'),
          stockItemId: any(named: 'stockItemId'),
          remaining: any(named: 'remaining'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer(
        (_) async => Right(
          pageOf([
            batch(unitCost: '3.500', remaining: '100.000'),
            batch(id: 41, remaining: '200.000'),
          ]),
        ),
      );

      // Act
      final failure = await cubit.revalue(
        batch(),
        unitCost: '3.5',
        quantity: '100',
        reason: 'فاتورة المورد وصلت بسعر مختلف',
      );

      // Assert — both layers on screen, so the shelf's value still adds up to its balance.
      expect(failure, isNull);

      final state = cubit.state as StockBatchesLoaded;
      expect(state.page.items.map((layer) => layer.id), [40, 41]);

      await cubit.close();
    });

    test('a refusal is handed back and the list is left exactly as it was', () async {
      // Arrange
      final cubit = buildCubit();
      await cubit.load();

      when(
        () => repository.revalueStockBatch(
          any(),
          unitCost: any(named: 'unitCost'),
          quantity: any(named: 'quantity'),
          reason: any(named: 'reason'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          Failure.server(message: 'الدفعة رقم 40 تموّلها صفقة مستثمر، ولا تُعدَّل تكلفتها'),
        ),
      );

      // Act
      final failure = await cubit.revalue(batch(), unitCost: '3.5', reason: 'تصحيح');

      // Assert — the screen shows the server's sentence; nothing on the shelf pretends to have
      // changed.
      expect(failure, isNotNull);

      final state = cubit.state as StockBatchesLoaded;
      expect(state.page.items.single.unitCost, '0.000');

      await cubit.close();
    });
  });
}
