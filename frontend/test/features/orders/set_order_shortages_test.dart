import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';
import 'package:printing/features/orders/usecases/set_order_shortages.dart';

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

  setUp(() {
    repository = _MockOrderRepository();
    setShortages = SetOrderShortages(repository);

    when(() => repository.setShortages(any(), shortages: any(named: 'shortages')))
        .thenAnswer((_) async => const Right(order));
  });

  test('what is missing travels line by line', () async {
    // Arrange & Act
    await setShortages(7, shortages: {11: '100', 12: '50'});

    // Assert
    final sent = verify(
      () => repository.setShortages(7, shortages: captureAny(named: 'shortages')),
    ).captured.single as Map<int, String?>;

    expect(sent, {11: '100', 12: '50'});
  });

  test('a line that is no longer short travels as nothing, not as absent', () async {
    // Arrange & Act — the box was emptied, which is the whole gesture for «وصلت الكمية».
    await setShortages(7, shortages: {11: '', 12: '50'});

    // Assert — sent as null so the server clears it. Dropping the key would leave the old
    // number standing and the invoice with it.
    final sent = verify(
      () => repository.setShortages(7, shortages: captureAny(named: 'shortages')),
    ).captured.single as Map<int, String?>;

    expect(sent, {11: null, 12: '50'});
  });

  test('a zero is a real answer and is sent as one', () async {
    // Arrange & Act
    await setShortages(7, shortages: {11: '0'});

    // Assert — «صفر ناقص» and «لا شيء مسجَّل» reach the same invoice, but the clerk typed one
    // of them, and turning a typed number into a blank is editing their answer.
    final sent = verify(
      () => repository.setShortages(7, shortages: captureAny(named: 'shortages')),
    ).captured.single as Map<int, String?>;

    expect(sent, {11: '0'});
  });

  test('spaces are not a number', () async {
    // Arrange & Act
    await setShortages(7, shortages: {11: '  '});

    // Assert
    final sent = verify(
      () => repository.setShortages(7, shortages: captureAny(named: 'shortages')),
    ).captured.single as Map<int, String?>;

    expect(sent, {11: null});
  });

  test('a refusal comes back as it was written', () async {
    // Arrange
    when(() => repository.setShortages(any(), shortages: any(named: 'shortages'))).thenAnswer(
      (_) async => const Left(
        Failure.server(message: 'لا يمكن تعديل بنود الطلبية بعد أن أصبحت «جاهزة»'),
      ),
    );

    // Act
    final result = await setShortages(7, shortages: {11: '100'});

    // Assert — the server's own Arabic, straight to the sheet.
    expect(
      result.fold((failure) => failure.message, (_) => null),
      'لا يمكن تعديل بنود الطلبية بعد أن أصبحت «جاهزة»',
    );
  });
}
