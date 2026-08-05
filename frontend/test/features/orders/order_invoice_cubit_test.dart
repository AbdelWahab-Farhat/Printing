import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';
import 'package:printing/features/orders/usecases/update_order_invoice.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

class _FakeLine extends Fake implements InvoiceLineUpdate {}

/// Editing an invoice: what the sheet sends, what it refuses to send, and what it keeps on
/// screen when the server says no.
void main() {
  late _MockOrderRepository repository;

  OrderItem itemWith({int id = 1, String quantity = '300', String price = '1.100'}) {
    return OrderItem(
      id: id,
      productId: 10,
      productVariantId: 20,
      productName: 'كيس شحن',
      variantLabel: '25*35',
      pricingUnitLabel: 'قطعة',
      quantity: quantity,
      unitPrice: price,
      lineTotal: '330.00',
    );
  }

  Order orderWith({List<OrderItem>? items, String discount = '0.00'}) {
    return Order(
      id: 7,
      code: '7',
      status: OrderStatus.taken,
      statusLabel: 'جديدة',
      isFinal: false,
      customerId: 5,
      cityId: 3,
      designSource: 'none',
      cityName: 'طرابلس',
      fulfilmentTypeLabel: 'توصيل',
      isOfficePickup: false,
      designSourceLabel: 'بدون تصميم',
      itemsTotal: '330.00',
      designFee: '0.00',
      deliveryPrice: '20.00',
      discount: discount,
      grandTotal: '350.00',
      items: items ?? [itemWith()],
    );
  }

  OrderInvoiceCubit cubitFor(Order order) => OrderInvoiceCubit(
    order: order,
    updateInvoice: UpdateOrderInvoice(repository),
  );

  void stubSave({Failure? failure}) {
    when(
      () => repository.updateInvoice(
        any(),
        lines: any(named: 'lines'),
        discount: any(named: 'discount'),
      ),
    ).thenAnswer(
      (_) async => failure != null ? Left(failure) : Right(orderWith()),
    );
  }

  setUpAll(() => registerFallbackValue(<InvoiceLineUpdate>[_FakeLine()]));

  setUp(() => repository = _MockOrderRepository());

  // ───────────────────────────── seeding ─────────────────────────────

  test('it opens on the order the screen already has, with no round trip', () {
    // Act
    final cubit = cubitFor(orderWith());

    // Assert — a spinner over data the user is looking at is a request spent to show them what
    // they can already see.
    expect(cubit.state.lines.single.quantity, '300');
    expect(cubit.state.isDirty, isFalse);
    verifyZeroInteractions(repository);
  });

  // ───────────────────────────── editing ─────────────────────────────

  test('changing a quantity marks the form dirty', () {
    // Arrange
    final cubit = cubitFor(orderWith());

    // Act
    cubit.setQuantity(1, '500');

    // Assert
    expect(cubit.state.lines.single.quantity, '500');
    expect(cubit.state.isDirty, isTrue);
  });

  test('the last line cannot be removed', () {
    // Arrange
    final cubit = cubitFor(orderWith());

    // Act
    cubit.remove(1);

    // Assert — the server refuses an order with nothing on it, and a Cubit that only holds
    // when a widget remembers to is not holding.
    expect(cubit.state.lines, hasLength(1));
  });

  test('a line is dropped when others remain', () {
    // Arrange
    final cubit = cubitFor(orderWith(items: [itemWith(id: 1), itemWith(id: 2)]));

    // Act
    cubit.remove(1);

    // Assert
    expect(cubit.state.lines.map((l) => l.id), [2]);
  });

  test('a quantity of zero is not valid', () {
    // Arrange
    final cubit = cubitFor(orderWith());

    // Act
    cubit.setQuantity(1, '0');

    // Assert
    expect(cubit.state.isValid, isFalse);
  });

  test('a trailing decimal point does not fight the person typing', () {
    // Arrange
    final cubit = cubitFor(orderWith());

    // Act — what the field holds mid-keystroke, on the way to «3.5».
    cubit.setQuantity(1, '3.');

    // Assert — read as 3 rather than refused. Blocking a half-typed number would put an error
    // under the field on the way to a value that is about to be fine, and PHP's `numeric`
    // accepts the same string on the other end.
    expect(cubit.state.isValid, isTrue);
  });

  test('an empty quantity is not valid', () {
    // Arrange
    final cubit = cubitFor(orderWith());

    // Act — the field cleared before retyping.
    cubit.setQuantity(1, '');

    // Assert
    expect(cubit.state.isValid, isFalse);
  });

  test('Arabic-Indic digits are a number', () {
    // Arrange
    final cubit = cubitFor(orderWith());

    // Act — what a Libyan keyboard produces.
    cubit.setQuantity(1, '٥٠٠');

    // Assert — reading these as invalid would tell somebody the number they typed correctly is
    // wrong, with no way to tell why.
    expect(cubit.state.isValid, isTrue);
  });

  test('the running estimate follows what is typed', () {
    // Arrange — 300 × 1.100 + 20.00 delivery.
    final cubit = cubitFor(orderWith());

    // Act
    cubit.setQuantity(1, '100');

    // Assert — 100 × 1.100 + 20.00.
    expect(cubit.state.estimatedTotal, '130.00');
  });

  // ───────────────────────────── saving ─────────────────────────────

  test('no price is ever sent — the catalogue prices the line', () async {
    // Arrange
    final cubit = cubitFor(orderWith());
    stubSave();
    cubit.setQuantity(1, '500');

    // Act
    await cubit.save();

    // Assert — a rate in the payload would be a way to undercut an agreed price.
    final sent = verify(
      () => repository.updateInvoice(
        any(),
        lines: captureAny(named: 'lines'),
        discount: any(named: 'discount'),
      ),
    ).captured.last as List<InvoiceLineUpdate>;

    expect(sent.single.toJson().containsKey('unit_price'), isFalse);
    expect(sent.single.toJson()['quantity'], '500');
  });

  test('Arabic-Indic digits are converted on the way out', () async {
    // Arrange
    final cubit = cubitFor(orderWith());
    stubSave();
    cubit.setQuantity(1, '٤٠٠');

    // Act
    await cubit.save();

    // Assert — the server parses ASCII; the conversion happens once, here.
    final sent = verify(
      () => repository.updateInvoice(
        any(),
        lines: captureAny(named: 'lines'),
        discount: any(named: 'discount'),
      ),
    ).captured.last as List<InvoiceLineUpdate>;

    expect(sent.single.toJson()['quantity'], '400');
  });

  test('an invalid form does not reach the server', () async {
    // Arrange
    final cubit = cubitFor(orderWith());
    stubSave();
    cubit.setQuantity(1, '');

    // Act
    await cubit.save();

    // Assert
    verifyNever(
      () => repository.updateInvoice(
        any(),
        lines: any(named: 'lines'),
        discount: any(named: 'discount'),
      ),
    );
  });

  test('a refusal keeps the form exactly as it was', () async {
    // Arrange
    final cubit = cubitFor(orderWith());
    stubSave(failure: const Failure.server(message: 'الكمية أقل من الحد الأدنى'));
    cubit.setQuantity(1, '5');

    // Act
    await cubit.save();

    // Assert — a 422 naming a quantity is advice about the thing still on screen.
    expect(cubit.state.lines.single.quantity, '5');
    expect(cubit.state.failure?.message, 'الكمية أقل من الحد الأدنى');
    expect(cubit.state.isSaved, isFalse);
  });

  test('editing after a refusal clears the stale message', () async {
    // Arrange
    final cubit = cubitFor(orderWith());
    stubSave(failure: const Failure.server(message: 'الكمية أقل من الحد الأدنى'));
    cubit.setQuantity(1, '5');
    await cubit.save();

    // Act
    cubit.setQuantity(1, '500');

    // Assert — advice about a form the user has since changed is stale advice.
    expect(cubit.state.failure, isNull);
  });

  test('a saved edit says so once', () async {
    // Arrange
    final cubit = cubitFor(orderWith());
    stubSave();
    cubit.setQuantity(1, '500');

    // Act
    await cubit.save();

    // Assert
    expect(cubit.state.isSaved, isTrue);
    expect(cubit.state.isSaving, isFalse);
  });
}
