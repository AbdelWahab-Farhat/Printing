import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/warehouses/models/stock_movement.dart';
import 'package:dayaa/features/warehouses/models/warehouse_stock.dart';
import 'package:dayaa/features/warehouses/presentation/viewmodel/record_movement_cubit.dart';
import 'package:dayaa/features/warehouses/repositories/warehouse_repository.dart';
import 'package:dayaa/features/warehouses/usecases/record_stock_movement.dart';
import 'package:dayaa/features/warehouses/usecases/set_low_stock_threshold.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Writing one line into the ledger: which endpoint each kind goes to, and what happens to the
/// number on the way.
///
/// Arrange - Act - Assert throughout.
class _MockWarehouseRepository extends Mock implements WarehouseRepository {}

void main() {
  late _MockWarehouseRepository repository;
  late RecordStockMovement record;

  const written = StockMovement(
    id: 7,
    movementType: MovementType.purchaseArrival,
    movementTypeLabel: 'توريد',
    quantity: '250.000',
    productVariantId: 3,
  );

  const shelf = WarehouseStock(
    id: 5,
    warehouseId: 1,
    productVariantId: 3,
    quantity: '250.000',
    unit: 'piece',
    unitLabel: 'قطعة',
  );

  setUp(() {
    repository = _MockWarehouseRepository();
    record = RecordStockMovement(repository);

    when(
      () => repository.recordArrival(
        productVariantId: any(named: 'productVariantId'),
        toWarehouseId: any(named: 'toWarehouseId'),
        quantity: any(named: 'quantity'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(written));

    when(
      () => repository.recordTransfer(
        productVariantId: any(named: 'productVariantId'),
        fromWarehouseId: any(named: 'fromWarehouseId'),
        toWarehouseId: any(named: 'toWarehouseId'),
        quantity: any(named: 'quantity'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(written));

    when(
      () => repository.recordAdjustment(
        productVariantId: any(named: 'productVariantId'),
        warehouseId: any(named: 'warehouseId'),
        quantity: any(named: 'quantity'),
        isIncrease: any(named: 'isIncrease'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(written));
  });

  test('an arrival has a destination and no source', () async {
    // Arrange & Act
    await record(
      kind: MovementKind.arrival,
      productVariantId: 3,
      warehouseId: 1,
      quantity: '250',
    );

    // Assert — each kind is its own endpoint precisely because their shapes differ.
    verify(
      () => repository.recordArrival(
        productVariantId: 3,
        toWarehouseId: 1,
        quantity: '250',
        notes: null,
      ),
    ).called(1);
  });

  test('a transfer carries both ends', () async {
    // Arrange & Act
    await record(
      kind: MovementKind.transfer,
      productVariantId: 3,
      warehouseId: 2,
      fromWarehouseId: 1,
      quantity: '50',
    );

    // Assert
    verify(
      () => repository.recordTransfer(
        productVariantId: 3,
        fromWarehouseId: 1,
        toWarehouseId: 2,
        quantity: '50',
        notes: null,
      ),
    ).called(1);
  });

  test('an adjustment carries a direction instead of a second warehouse', () async {
    // Arrange & Act
    await record(
      kind: MovementKind.decrease,
      productVariantId: 3,
      warehouseId: 1,
      quantity: '4',
      notes: '  تلف أثناء التخزين  ',
    );

    // Assert — and the note is trimmed on the way out.
    verify(
      () => repository.recordAdjustment(
        productVariantId: 3,
        warehouseId: 1,
        quantity: '4',
        isIncrease: false,
        notes: 'تلف أثناء التخزين',
      ),
    ).called(1);
  });

  test('Arabic-Indic digits and a decimal comma both reach the API as a number', () async {
    // Arrange — ٢٥٠٫٥ is what a Libyan keyboard produces, and 250,5 is what it offers as a
    // decimal mark. Sent untouched, either is a 422 about a field filled in correctly.
    await record(
      kind: MovementKind.arrival,
      productVariantId: 3,
      warehouseId: 1,
      quantity: '٢٥٠,٥',
    );

    // Assert
    final captured = verify(
      () => repository.recordArrival(
        productVariantId: any(named: 'productVariantId'),
        toWarehouseId: any(named: 'toWarehouseId'),
        quantity: captureAny(named: 'quantity'),
        notes: any(named: 'notes'),
      ),
    ).captured.single;

    expect(captured, '250.5');
  });

  test('an empty alert level clears it rather than sending an empty string', () async {
    // Arrange — «لا تنبهني» is a decision, and the API's rule is nullable.
    when(
      () => repository.setThreshold(any(), any(), threshold: any(named: 'threshold')),
    ).thenAnswer((_) async => const Right(shelf));
    final setThreshold = SetLowStockThreshold(repository);

    // Act
    await setThreshold(1, 5, threshold: '   ');

    // Assert
    verify(() => repository.setThreshold(1, 5, threshold: null)).called(1);
  });

  test('a level that was typed travels trimmed', () async {
    // Arrange
    when(
      () => repository.setThreshold(any(), any(), threshold: any(named: 'threshold')),
    ).thenAnswer((_) async => const Right(shelf));
    final setThreshold = SetLowStockThreshold(repository);

    // Act
    await setThreshold(1, 5, threshold: ' 20 ');

    // Assert
    verify(() => repository.setThreshold(1, 5, threshold: '20')).called(1);
  });

  group('what the server complained about', () {
    RecordMovementState failedWith(Map<String, List<String>> errors) {
      return RecordMovementState.failure(
        Failure.server(message: 'البيانات المدخلة غير صحيحة', fieldErrors: errors),
      );
    }

    test('«سبب التسوية مطلوب» lands under the notes box', () {
      // Arrange — required on an adjustment alone: the other three movements explain
      // themselves, so this key only ever arrives for one kind.
      final state = failedWith({'notes': ['سبب التسوية مطلوب']});

      // Act & Assert
      expect(state.notesError, 'سبب التسوية مطلوب');
      expect(state.hasFieldErrors, isTrue);
    });

    test('every field the API validates has a box on this form', () {
      // Arrange — a key with nowhere to go is a key nobody sees: it falls through to the
      // envelope's generic sentence, which tells the storekeeper *that* something is wrong
      // without telling them what. `notes` did exactly that until it was wired.
      final keys = {
        'product_variant_id': 'variant',
        'warehouse_id': 'warehouse',
        'to_warehouse_id': 'warehouse',
        'from_warehouse_id': 'source',
        'quantity': 'quantity',
        'notes': 'notes',
      };

      // Act
      final unmapped = [
        for (final key in keys.keys)
          if (!failedWith({key: ['خطأ']}).hasFieldErrors) key,
      ];

      // Assert
      expect(unmapped, isEmpty);
    });

    test('a failure with no field errors is left to the snackbar', () {
      // Arrange — a 403 or a dropped line says nothing about one box.
      const state = RecordMovementState.failure(Failure.forbidden(message: 'لا صلاحية'));

      // Act & Assert
      expect(state.hasFieldErrors, isFalse);
    });

    test('a dropped connection is the one failure that must not offer a retry', () {
      // Arrange — a movement carries no unique key, so a request that landed before the line
      // dropped and is sent again moves the stock twice.
      const state = RecordMovementState.failure(Failure.network(message: 'لا يوجد اتصال'));

      // Act & Assert
      expect(state.mayHaveLanded, isTrue);
    });
  });

  test('a refusal comes back untouched', () async {
    // Arrange — «الكمية المطلوبة غير متوفرة» is the server's sentence, and the app keeps it.
    when(
      () => repository.recordTransfer(
        productVariantId: any(named: 'productVariantId'),
        fromWarehouseId: any(named: 'fromWarehouseId'),
        toWarehouseId: any(named: 'toWarehouseId'),
        quantity: any(named: 'quantity'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer(
      (_) async => const Left(Failure.server(message: 'الكمية المطلوبة غير متوفرة')),
    );

    // Act
    final result = await record(
      kind: MovementKind.transfer,
      productVariantId: 3,
      warehouseId: 2,
      fromWarehouseId: 1,
      quantity: '999',
    );

    // Assert
    expect(
      result.fold((failure) => failure.message, (_) => null),
      'الكمية المطلوبة غير متوفرة',
    );
  });
}
