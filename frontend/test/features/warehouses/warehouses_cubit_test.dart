import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/models/warehouse.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/stock_movements_cubit.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/warehouses_cubit.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';
import 'package:dayaa/features/warehouses/usecases/delete_warehouse.dart';
import 'package:dayaa/features/warehouses/usecases/get_stock_movements.dart';
import 'package:dayaa/features/warehouses/usecases/get_warehouses.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// المخازن — the list screen's ViewModel, with the repository faked and no Dio anywhere.
///
/// Arrange - Act - Assert throughout.
class _MockWarehouseRepository extends Mock implements WarehouseRepository {}

void main() {
  late _MockWarehouseRepository repository;
  late WarehousesCubit cubit;

  const main = Warehouse(
    id: 1,
    name: 'المخزن الرئيسي',
    type: WarehouseType.main,
    typeLabel: 'المخزن الرئيسي',
    stocksCount: 12,
  );

  const showroom = Warehouse(
    id: 2,
    name: 'صالة العرض',
    type: WarehouseType.showroom,
    typeLabel: 'صالة العرض',
    stocksCount: 0,
  );

  Paginated<Warehouse> pageOf(List<Warehouse> warehouses) => Paginated<Warehouse>(
    items: warehouses,
    meta: PageMeta(
      currentPage: 1,
      perPage: 20,
      lastPage: 1,
      total: warehouses.length,
    ),
  );

  void answerWith(Either<Failure, Paginated<Warehouse>> result) {
    when(
      () => repository.warehouses(
        search: any(named: 'search'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUp(() {
    repository = _MockWarehouseRepository();
    cubit = WarehousesCubit(
      getWarehouses: GetWarehouses(repository),
      deleteWarehouse: DeleteWarehouse(repository),
    );
  });

  tearDown(() => cubit.close());

  blocTest<WarehousesCubit, WarehousesState>(
    'goes loading then loaded when the list answers',
    setUp: () {
      // Arrange
      answerWith(Right(pageOf(const [main, showroom])));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      const WarehousesState.loading(),
      isA<WarehousesLoaded>().having(
        (state) => state.page.items.map((warehouse) => warehouse.name),
        'names',
        ['المخزن الرئيسي', 'صالة العرض'],
      ),
    ],
  );

  blocTest<WarehousesCubit, WarehousesState>(
    'the server\'s own message is what a failure carries',
    setUp: () {
      // Arrange
      answerWith(const Left(Failure.forbidden(message: 'ليس لديك صلاحية')));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      const WarehousesState.loading(),
      isA<WarehousesFailure>().having(
        (state) => state.failure.message,
        'message',
        'ليس لديك صلاحية',
      ),
    ],
  );

  test('an empty warehouse is removed and the list re-read', () async {
    // Arrange
    answerWith(Right(pageOf(const [showroom])));
    when(() => repository.delete(any())).thenAnswer((_) async => const Right('تم الحذف'));
    await cubit.load();

    // Act
    final failure = await cubit.remove(showroom);

    // Assert
    expect(failure, isNull);
    verify(() => repository.delete(2)).called(1);
  });

  test('«ما زال يحتوي على مخزون» comes back as the failure the sheet shows', () async {
    // Arrange — the rule belongs to the server, and the app does not guess at it.
    answerWith(Right(pageOf(const [main])));
    when(() => repository.delete(any())).thenAnswer(
      (_) async => const Left(
        Failure.server(message: 'لا يمكن حذف مخزن ما زال يحتوي على مخزون'),
      ),
    );
    await cubit.load();

    // Act
    final failure = await cubit.remove(main);

    // Assert
    expect(failure?.message, contains('ما زال يحتوي'));
  });

  group('the warehouse itself', () {
    test('a warehouse with shelves knows it cannot be deleted', () {
      // Arrange & Act — read off the model, so the sheet and the list agree.
      // Assert
      expect(main.holdsStock, isTrue);
      expect(showroom.holdsStock, isFalse);
    });

    test('a warehouse whose count was never asked for is assumed to hold stock', () {
      // Arrange
      const unknown = Warehouse(
        id: 9,
        name: 'مخزن',
        type: WarehouseType.operational,
        typeLabel: 'مخزن التشغيل',
      );

      // Act & Assert — refusing wrongly is recoverable; the opposite is a 422 nobody expected.
      expect(unknown.holdsStock, isTrue);
    });
  });

  group('the ledger, at three zoom levels', () {
    Paginated<StockMovement> emptyLedger() => const Paginated<StockMovement>(
      items: [],
      meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 1, total: 0),
    );

    void answerLedger() {
      when(
        () => repository.movements(
          warehouseId: any(named: 'warehouseId'),
          stockItemId: any(named: 'stockItemId'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer((_) async => Right(emptyLedger()));
    }

    test('the whole workshop asks for nothing in particular', () async {
      // Arrange
      answerLedger();
      final ledger = StockMovementsCubit(getMovements: GetStockMovements(repository));

      // Act
      await ledger.load();
      await ledger.close();

      // Assert
      verify(
        () => repository.movements(
          warehouseId: null,
          stockItemId: null,
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    });

    test('one shelf asks for its صنف *and* its place', () async {
      // Arrange — «هذا الصنف، في هذا المخزن»: the two filters combine, which is what makes a
      // shelf's own history different from the item's history everywhere.
      //
      // **The pile, not one product's share of it.** Two catalogue rows draw on «كيس شحن 25*35»,
      // and the rows that explain the number on that shelf are all of them together — narrowing
      // by a product size would show a history that does not add up to the balance above it.
      answerLedger();
      final ledger = StockMovementsCubit(
        getMovements: GetStockMovements(repository),
        warehouseId: 2,
        stockItemId: 7,
      );

      // Act
      await ledger.load();
      await ledger.close();

      // Assert
      verify(
        () => repository.movements(
          warehouseId: 2,
          stockItemId: 7,
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    });

    test('the filters ride along on the next page too', () async {
      // Arrange
      when(
        () => repository.movements(
          warehouseId: any(named: 'warehouseId'),
          stockItemId: any(named: 'stockItemId'),
          page: any(named: 'page'),
          perPage: any(named: 'perPage'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          Paginated<StockMovement>(
            items: [
              StockMovement(
                id: 1,
                movementType: MovementType.purchaseArrival,
                movementTypeLabel: 'توريد',
                quantity: '10.000',
                stockItemId: 7,
              ),
            ],
            meta: PageMeta(currentPage: 1, perPage: 20, lastPage: 2, total: 21),
          ),
        ),
      );
      final ledger = StockMovementsCubit(
        getMovements: GetStockMovements(repository),
        warehouseId: 2,
        stockItemId: 7,
      );

      // Act
      await ledger.load();
      await ledger.loadMore();
      await ledger.close();

      // Assert — page two of one shelf must not arrive as page two of everything.
      verify(
        () => repository.movements(
          warehouseId: 2,
          stockItemId: 7,
          page: 2,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    });
  });
}
