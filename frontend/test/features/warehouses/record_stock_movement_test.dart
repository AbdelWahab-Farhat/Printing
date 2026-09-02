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
/// **What moves is a صنف مخزني, not a product's size.** «كيس شحن سادة 25*35» and «كيس شحن مطبوع
/// 25*35» are two catalogue rows and one pile of bags, so every payload here names the pile. A
/// movement keyed by a product size could only ever have moved one of the two products' shares of
/// stock that was never divided — which is the shortfall this whole change exists to prevent.
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
    stockItemId: 3,
  );

  const shelf = WarehouseStock(
    id: 5,
    warehouseId: 1,
    stockItemId: 3,
    quantity: '250.000',
    unit: 'piece',
    unitLabel: 'قطعة',
  );

  setUp(() {
    repository = _MockWarehouseRepository();
    record = RecordStockMovement(repository);

    when(
      () => repository.recordArrival(
        stockItemId: any(named: 'stockItemId'),
        toWarehouseId: any(named: 'toWarehouseId'),
        quantity: any(named: 'quantity'),
        unitCost: any(named: 'unitCost'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(written));

    when(
      () => repository.recordTransfer(
        stockItemId: any(named: 'stockItemId'),
        fromWarehouseId: any(named: 'fromWarehouseId'),
        toWarehouseId: any(named: 'toWarehouseId'),
        quantity: any(named: 'quantity'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(written));

    when(
      () => repository.recordAdjustment(
        stockItemId: any(named: 'stockItemId'),
        warehouseId: any(named: 'warehouseId'),
        quantity: any(named: 'quantity'),
        isIncrease: any(named: 'isIncrease'),
        unitCost: any(named: 'unitCost'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(written));
  });

  test('an arrival has a destination and no source', () async {
    // Arrange & Act
    await record(
      kind: MovementKind.arrival,
      stockItemId: 3,
      warehouseId: 1,
      quantity: '250',
    );

    // Assert — each kind is its own endpoint precisely because their shapes differ.
    verify(
      () => repository.recordArrival(
        stockItemId: 3,
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
      stockItemId: 3,
      warehouseId: 2,
      fromWarehouseId: 1,
      quantity: '50',
    );

    // Assert
    verify(
      () => repository.recordTransfer(
        stockItemId: 3,
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
      stockItemId: 3,
      warehouseId: 1,
      quantity: '4',
      notes: '  تلف أثناء التخزين  ',
    );

    // Assert — and the note is trimmed on the way out.
    verify(
      () => repository.recordAdjustment(
        stockItemId: 3,
        warehouseId: 1,
        quantity: '4',
        isIncrease: false,
        notes: 'تلف أثناء التخزين',
      ),
    ).called(1);
  });

  group('the cost that opens the layer', () {
    test('an arrival carries it', () async {
      // Arrange & Act
      await record(
        kind: MovementKind.arrival,
        stockItemId: 3,
        warehouseId: 1,
        quantity: '250',
        unitCost: '3.5',
      );

      // Assert
      verify(
        () => repository.recordArrival(
          stockItemId: 3,
          toWarehouseId: 1,
          quantity: '250',
          unitCost: '3.5',
          notes: null,
        ),
      ).called(1);
    });

    test('an increase carries it, alongside the direction', () async {
      // Arrange — the API refuses an increase without one, which is the 422 staff hit today.
      await record(
        kind: MovementKind.increase,
        stockItemId: 3,
        warehouseId: 1,
        quantity: '10',
        unitCost: '3.5',
        notes: 'وجدنا أكثر مما في السجل',
      );

      // Assert
      verify(
        () => repository.recordAdjustment(
          stockItemId: 3,
          warehouseId: 1,
          quantity: '10',
          isIncrease: true,
          unitCost: '3.5',
          notes: 'وجدنا أكثر مما في السجل',
        ),
      ).called(1);
    });

    test('a decrease drops a cost that was typed and then abandoned', () async {
      // Arrange — the two adjustments share one repository call, so nothing but this use case
      // stands between a figure typed under «زيادة» and a «نقص» that consumes existing layers.
      // A hidden field is not a rule; this is.
      await record(
        kind: MovementKind.decrease,
        stockItemId: 3,
        warehouseId: 1,
        quantity: '4',
        unitCost: '3.5',
        notes: 'تلف أثناء التخزين',
      );

      // Assert
      verify(
        () => repository.recordAdjustment(
          stockItemId: 3,
          warehouseId: 1,
          quantity: '4',
          isIncrease: false,
          unitCost: null,
          notes: 'تلف أثناء التخزين',
        ),
      ).called(1);
    });

    test('an empty box sends nothing rather than a zero', () async {
      // Arrange — «لا نعرف سعرها» leaves the layer findable in the uncosted queue; «صفر» says a
      // person decided it is worthless and takes it out of that queue for good.
      await record(
        kind: MovementKind.arrival,
        stockItemId: 3,
        warehouseId: 1,
        quantity: '250',
        unitCost: '   ',
      );

      // Assert
      verify(
        () => repository.recordArrival(
          stockItemId: 3,
          toWarehouseId: 1,
          quantity: '250',
          unitCost: null,
          notes: null,
        ),
      ).called(1);
    });

    test('Arabic-Indic digits and a decimal comma reach the API as a number', () async {
      // Arrange — ٣٫٥ is what the keyboard produces and 3,5 is the decimal mark it offers; the
      // cost goes through the same normalisation the quantity does, and for the same reason.
      await record(
        kind: MovementKind.arrival,
        stockItemId: 3,
        warehouseId: 1,
        quantity: '250',
        unitCost: ' ٣,٥ ',
      );

      // Assert
      final captured = verify(
        () => repository.recordArrival(
          stockItemId: any(named: 'stockItemId'),
          toWarehouseId: any(named: 'toWarehouseId'),
          quantity: any(named: 'quantity'),
          unitCost: captureAny(named: 'unitCost'),
          notes: any(named: 'notes'),
        ),
      ).captured.single;

      expect(captured, '3.5');
    });

    test('a transfer has no cost to carry, and cannot be given one', () {
      // Arrange & Act & Assert — a transfer relocates layers at the prices they already hold, so
      // `recordTransfer` never took a cost. Stated as a test so the reason survives: the guard
      // is the contract's shape, and the compiler enforces it on anyone who adds the argument.
      expect(MovementKind.transfer.opensCostLayer, isFalse);
      expect(MovementKind.decrease.opensCostLayer, isFalse);
      expect(MovementKind.arrival.opensCostLayer, isTrue);
      expect(MovementKind.increase.opensCostLayer, isTrue);

      // Only the increase is refused without one — an arrival may genuinely not know its price.
      expect(MovementKind.increase.requiresCost, isTrue);
      expect(MovementKind.arrival.requiresCost, isFalse);
    });
  });

  test('Arabic-Indic digits and a decimal comma both reach the API as a number', () async {
    // Arrange — ٢٥٠٫٥ is what a Libyan keyboard produces, and 250,5 is what it offers as a
    // decimal mark. Sent untouched, either is a 422 about a field filled in correctly.
    await record(
      kind: MovementKind.arrival,
      stockItemId: 3,
      warehouseId: 1,
      quantity: '٢٥٠,٥',
    );

    // Assert
    final captured = verify(
      () => repository.recordArrival(
        stockItemId: any(named: 'stockItemId'),
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
        // `stock_item_id` carries three refusals at once — «الصنف المخزني مطلوب», «غير موجود»,
        // and ««المنتج — المقاس» غير مرتبط بصنف مخزني» for a quote-only size nobody gave a shelf.
        // The last is new and is not an impossible state: a size may legitimately have none, so
        // it is a refusal this form has to be able to put under the box that picked the pile.
        'stock_item_id': 'stock item',
        'warehouse_id': 'warehouse',
        'to_warehouse_id': 'warehouse',
        'from_warehouse_id': 'source',
        'quantity': 'quantity',
        // «تكلفة الوحدة مطلوبة عند تسجيل زيادة» is the refusal this whole change exists to
        // stop; it would be worse than useless behind a generic snackbar.
        'unit_cost': 'unit cost',
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
        stockItemId: any(named: 'stockItemId'),
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
      stockItemId: 3,
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
