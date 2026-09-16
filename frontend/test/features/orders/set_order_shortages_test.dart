import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/line_shortage_entry.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/set_order_shortages.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Correcting what is missing — and therefore what the customer pays.
///
/// **The set is replaced, not patched.** Every line the sheet showed travels, and a line that is
/// no longer short travels as null: that is how a shortage is un-recorded, and un-recording one
/// is what puts the invoice back. A payload that quietly dropped the empty boxes would make the
/// sheet able to add a shortage and never able to clear one.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;
  late SetOrderShortages setShortages;

  const order = Order(
    id: 7,
    code: '7',
    status: OrderStatus.shortage,
    statusLabel: 'نواقص',
    isFinal: false,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsAreEditable: true,
    designsAreEditable: false,
    itemsTotal: '310.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '330.00',
  );

  /// A line with one figure — the shape every size stocked in the unit it was sold in
  /// takes, which is most of them. The two-unit case has its own test below.
  LineShortageEntry e(String? quantity) => LineShortageEntry(quantity: quantity);

  setUp(() {
    repository = _MockOrderRepository();
    setShortages = SetOrderShortages(repository);

    when(() => repository.setShortages(any(), shortages: any(named: 'shortages')))
        .thenAnswer((_) async => const Right(order));
  });

  test('what is missing travels line by line', () async {
    // Arrange & Act
    await setShortages(7, shortages: {11: e('100'), 12: e('50')});

    // Assert
    final sent = verify(
      () => repository.setShortages(7, shortages: captureAny(named: 'shortages')),
    ).captured.single as Map<int, LineShortageEntry>;

    expect(sent.map((id, v) => MapEntry(id, v.quantity)), {11: '100', 12: '50'});
  });

  test('a line that is no longer short travels as nothing, not as absent', () async {
    // Arrange & Act — the box was emptied, which is the whole gesture for «وصلت الكمية».
    await setShortages(7, shortages: {11: e(''), 12: e('50')});

    // Assert — sent as null so the server clears it. Dropping the key would leave the old
    // number standing and the invoice with it.
    final sent = verify(
      () => repository.setShortages(7, shortages: captureAny(named: 'shortages')),
    ).captured.single as Map<int, LineShortageEntry>;

    expect(sent.map((id, v) => MapEntry(id, v.quantity)), {11: null, 12: '50'});
  });

  test('a zero is a real answer and is sent as one', () async {
    // Arrange & Act
    await setShortages(7, shortages: {11: e('0')});

    // Assert — «صفر ناقص» and «لا شيء مسجَّل» reach the same invoice, but the clerk typed one
    // of them, and turning a typed number into a blank is editing their answer.
    final sent = verify(
      () => repository.setShortages(7, shortages: captureAny(named: 'shortages')),
    ).captured.single as Map<int, LineShortageEntry>;

    expect(sent.map((id, v) => MapEntry(id, v.quantity)), {11: '0'});
  });

  test('spaces are not a number', () async {
    // Arrange & Act
    await setShortages(7, shortages: {11: e('  ')});

    // Assert
    final sent = verify(
      () => repository.setShortages(7, shortages: captureAny(named: 'shortages')),
    ).captured.single as Map<int, LineShortageEntry>;

    expect(sent.map((id, v) => MapEntry(id, v.quantity)), {11: null});
  });

  test('a line the warehouse counts differently carries both figures', () async {
    // Arrange & Act — «ناقص ٣٠ قطعة، وهي ١٢٫٥ كجم». Neither number can be derived from the
    // other, so both are carried rather than one being converted.
    await setShortages(7, shortages: {
      11: const LineShortageEntry(quantity: '30', warehouseQuantity: '12.5'),
    });

    // Assert
    final sent = verify(
      () => repository.setShortages(7, shortages: captureAny(named: 'shortages')),
    ).captured.single as Map<int, LineShortageEntry>;

    expect(sent[11]!.quantity, '30');
    expect(sent[11]!.warehouseQuantity, '12.5');
  });

  test('a cleared line drops its weight, because a weight with no shortage is nothing', () async {
    // Arrange & Act — the box emptied on a two-unit line. The server refuses the pairing, and
    // sending it would be claiming a measurement of a gap that no longer exists.
    await setShortages(7, shortages: {
      11: const LineShortageEntry(quantity: '', warehouseQuantity: '12.5'),
    });

    // Assert
    final sent = verify(
      () => repository.setShortages(7, shortages: captureAny(named: 'shortages')),
    ).captured.single as Map<int, LineShortageEntry>;

    expect(sent[11]!.quantity, isNull);
    expect(sent[11]!.warehouseQuantity, isNull);
  });

  test('a refusal comes back as it was written', () async {
    // Arrange
    when(() => repository.setShortages(any(), shortages: any(named: 'shortages'))).thenAnswer(
      (_) async => const Left(
        Failure.server(message: 'لا يمكن تعديل بنود الطلبية بعد أن أصبحت «جاهزة»'),
      ),
    );

    // Act
    final result = await setShortages(7, shortages: {11: e('100')});

    // Assert — the server's own Arabic, straight to the sheet.
    expect(
      result.fold((failure) => failure.message, (_) => null),
      'لا يمكن تعديل بنود الطلبية بعد أن أصبحت «جاهزة»',
    );
  });
}
