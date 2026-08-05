import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/warehouses/models/warehouse.dart';
import 'package:printing/features/warehouses/presentation/viewmodel/warehouses_cubit.dart';
import 'package:printing/features/warehouses/repositories/warehouse_repository.dart';
import 'package:printing/features/warehouses/usecases/delete_warehouse.dart';
import 'package:printing/features/warehouses/usecases/get_warehouses.dart';

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
}
