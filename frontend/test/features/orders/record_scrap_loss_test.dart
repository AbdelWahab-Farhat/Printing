import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/production_cost_entry.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/record_scrap_loss.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Writing off bags that were ruined making a line.
///
/// **The storekeeper counts, the batches price.** Nothing here sends a cost, and there is no
/// arithmetic to check — what this layer owns is the two things a person typed: a quantity from a
/// keyboard that produces `٢٥`, and a reason that has to survive being padded with spaces.
///
/// **A refusal is the server's sentence, not ours.** «لا يمكن تسجيل تلف لطلبية لم تدخل مرحلة
/// الطباعة بعد» and «الكمية المتوفرة في المخزن (٥٠) لا تكفي للكمية المطلوبة (٦٠)» both name what
/// to do next and both quote numbers only the shelf knows, so they travel to the screen untouched.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;
  late RecordScrapLoss recordScrap;

  const entry = ProductionCostEntry(
    id: 7,
    orderId: 3,
    orderItemId: 11,
    costType: 'scrap_loss',
    costTypeLabel: 'خسارة تلف',
    amount: '40.00',
    quantity: '10.000',
    notes: 'انحراف في طباعة الشعار',
  );

  setUp(() {
    repository = _MockOrderRepository();
    recordScrap = RecordScrapLoss(repository);

    when(
      () => repository.recordScrapLoss(
        any(),
        any(),
        quantity: any(named: 'quantity'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer((_) async => const Right(entry));
  });

  /// What the repository was actually handed.
  ///
  /// Called once per test and held in a local: `verify` marks the call verified, so a second
  /// `sent()` in the same test finds nothing.
  ({String quantity, String notes}) sent() {
    final captured = verify(
      () => repository.recordScrapLoss(
        any(),
        any(),
        quantity: captureAny(named: 'quantity'),
        notes: captureAny(named: 'notes'),
      ),
    ).captured;

    return (quantity: captured[0] as String, notes: captured[1] as String);
  }

  test('the line is addressed inside its order', () async {
    // Arrange & Act
    await recordScrap(3, 11, quantity: '10', notes: 'انحراف في طباعة الشعار');

    // Assert — both ids travel, because the API resolves the item *within* the order and a bare
    // line id would be a 404 there.
    verify(
      () => repository.recordScrapLoss(
        3,
        11,
        quantity: any(named: 'quantity'),
        notes: any(named: 'notes'),
      ),
    ).called(1);
  });

  test('what an Arabic keyboard produced becomes the ASCII the server takes', () async {
    // Arrange & Act — `٢٥٫٥` is what a storekeeper reads off their own screen, and every numeric
    // rule on the server is ASCII-only.
    await recordScrap(3, 11, quantity: '٢٥٫٥', notes: 'انحراف في طباعة الشعار');

    // Assert — cleaned, never parsed: the string is passed on and the server does the arithmetic
    // in exact decimals.
    expect(sent().quantity, '25.5');
  });

  test('a quantity stays a string, decimals and all', () async {
    // Arrange & Act
    await recordScrap(3, 11, quantity: '10.500', notes: 'انحراف في طباعة الشعار');

    // Assert
    expect(sent().quantity, '10.500');
  });

  test('a reason padded with spaces travels without them', () async {
    // Arrange & Act
    await recordScrap(3, 11, quantity: '10', notes: '  انحراف في طباعة الشعار  ');

    // Assert
    expect(sent().notes, 'انحراف في طباعة الشعار');
  });

  test('a reason of nothing but spaces is left for the server to refuse', () async {
    // Arrange & Act — trimmed to empty rather than sent as three spaces, which would satisfy a
    // `min:3` check and tell the next reader nothing at all.
    await recordScrap(3, 11, quantity: '10', notes: '   ');

    // Assert
    expect(sent().notes, '');
  });

  test('what the bags cost comes back, and it is the server that says so', () async {
    // Arrange & Act
    final result = await recordScrap(3, 11, quantity: '10', notes: 'انحراف في طباعة الشعار');

    // Assert — the amount is read out of the batches the bags came from. Nothing on this side
    // could have worked it out.
    expect(result.fold((failure) => null, (entry) => entry.amount), '40.00');
  });

  test('an order that never reached the press is refused in the server\'s own words', () async {
    // Arrange
    when(
      () => repository.recordScrapLoss(
        any(),
        any(),
        quantity: any(named: 'quantity'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer(
      (_) async => const Left(
        Failure.server(
          message: 'لا يمكن تسجيل تلف لطلبية لم تدخل مرحلة الطباعة بعد',
          statusCode: 422,
        ),
      ),
    );

    // Act
    final result = await recordScrap(3, 11, quantity: '10', notes: 'انحراف في طباعة الشعار');

    // Assert — it names the condition and the fix. A sentence of ours would say less.
    expect(
      result.fold((failure) => failure.message, (_) => null),
      'لا يمكن تسجيل تلف لطلبية لم تدخل مرحلة الطباعة بعد',
    );
  });

  test('a shelf that cannot cover it says both numbers, under the quantity', () async {
    // Arrange
    when(
      () => repository.recordScrapLoss(
        any(),
        any(),
        quantity: any(named: 'quantity'),
        notes: any(named: 'notes'),
      ),
    ).thenAnswer(
      (_) async => const Left(
        Failure.server(
          message: 'الكمية المتوفرة في المخزن (50.000) لا تكفي للكمية المطلوبة (60.000)',
          statusCode: 422,
          fieldErrors: {
            'quantity': ['الكمية المتوفرة في المخزن (50.000) لا تكفي للكمية المطلوبة (60.000)'],
          },
        ),
      ),
    );

    // Act
    final result = await recordScrap(3, 11, quantity: '60', notes: 'انحراف في طباعة الشعار');

    // Assert — keyed on `quantity`, so the message lands under the box that caused it, and it
    // carries both figures: what was asked for and what is actually on the shelf. Nobody has to
    // leave the screen to find out how much they may write off.
    final failure = result.fold((failure) => failure, (_) => null);

    expect(
      failure,
      isA<ServerFailure>().having(
        (failure) => failure.fieldErrors?['quantity']?.single,
        'the message under the quantity',
        contains('50.000'),
      ),
    );
  });
}
