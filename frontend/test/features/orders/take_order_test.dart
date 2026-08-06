import 'package:dartz/dartz.dart' hide Order;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/orders/models/new_order.dart';
import 'package:printing/features/orders/models/order.dart';
import 'package:printing/features/orders/models/order_status.dart';
import 'package:printing/features/orders/repositories/order_repository.dart';
import 'package:printing/features/orders/usecases/take_order.dart';

/// What the form typed, turned into what the API accepts.
///
/// This is the file that earns the use case its place, and the reason is the same one
/// `SaveProduct` has: **`٣٠٠` is what a Libyan keyboard produces, and every numeric rule on the
/// server is ASCII-only.** An order has a quantity per line plus a design fee and a discount,
/// and converting each at its widget would be one chance per field to forget.
///
/// The second job is subtler and is money: a design fee only counts when we did the design, and
/// a discount nobody typed must be *absent* rather than `'0'` — a zero discount posted by a
/// clerk without `orders.discount` is still a discount field, and the server guards on the
/// value being greater than zero, not on the key.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _FakeNewOrder extends Fake implements NewOrder {}

void main() {
  late _MockOrderRepository repository;
  late TakeOrder takeOrder;

  setUpAll(() => registerFallbackValue(_FakeNewOrder()));

  const stored = Order(
    id: 52,
    code: '52',
    status: OrderStatus.taken,
    statusLabel: 'جديدة',
    isFinal: false,
    customerId: 3,
    cityId: 1,
    designSource: 'none',
    designSourceLabel: 'بدون تصميم',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    itemsTotal: '330.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '350.00',
  );

  setUp(() {
    repository = _MockOrderRepository();
    when(() => repository.create(any())).thenAnswer((_) async => const Right(stored));
    takeOrder = TakeOrder(repository);
  });

  /// The draft the repository was actually handed.
  ///
  /// Called once per test and held in a local: `verify` marks the call verified, so a second
  /// `sent()` in the same test finds nothing.
  NewOrder sent() => verify(() => repository.create(captureAny())).captured.single as NewOrder;

  Future<Either<Failure, Order>> submit({
    int customerId = 3,
    int cityId = 1,
    int? regionId,
    int? customerShopId,
    String designSource = 'none',
    String? designFee,
    String? discount,
    String? recipientName,
    String? recipientPhone,
    String? addressDetails,
    String? notes,
    List<DraftOrderLine> lines = const [
      DraftOrderLine(productId: 7, productVariantId: 12, quantity: '300'),
    ],
  }) {
    return takeOrder(
      customerId: customerId,
      cityId: cityId,
      regionId: regionId,
      customerShopId: customerShopId,
      designSource: designSource,
      designFee: designFee,
      discount: discount,
      recipientName: recipientName,
      recipientPhone: recipientPhone,
      addressDetails: addressDetails,
      notes: notes,
      lines: lines,
    );
  }

  group('the numbers a Libyan keyboard produces', () {
    test('a quantity in Arabic-Indic digits reaches the API in ASCII', () async {
      // Arrange — ٣٠٠ is `items.*.quantity`, whose rule is `numeric`. Sent as typed it is a 422
      // on a field the clerk can see nothing wrong with.
      const line = DraftOrderLine(productId: 7, productVariantId: 12, quantity: '٣٠٠');

      // Act
      await submit(lines: const [line]);

      // Assert
      expect(sent().items.single.quantity, '300');
    });

    test('a comma is the decimal mark on that keyboard, and becomes a point', () async {
      // Arrange — `1,5` kilos is what gets typed; `1,5` is not a number to the server.
      const line = DraftOrderLine(productId: 7, productVariantId: 12, quantity: '1,5');

      // Act
      await submit(lines: const [line]);

      // Assert
      expect(sent().items.single.quantity, '1.5');
    });

    test('the discount and the design fee are converted too', () async {
      // Arrange
      // Act
      await submit(designSource: 'in_house', designFee: '٤٠', discount: '٢٥٫٥');

      // Assert
      final order = sent();
      expect(order.designFee, '40');
      expect(order.discount, '25.5');
    });

    test('a price named for a quote-only product is converted too', () async {
      // Arrange
      const line = DraftOrderLine(
        productId: 9,
        productVariantId: 14,
        quantity: '200',
        unitPrice: '٢٫٧٥',
      );

      // Act
      await submit(lines: const [line]);

      // Assert
      expect(sent().items.single.unitPrice, '2.75');
    });
  });

  group('the money a person decides', () {
    test('a design fee is not sent when the design was not ours', () async {
      // Arrange — the field is on screen only for «تصميم من عندنا», but a clerk who typed a fee
      // and then changed the source would otherwise still send it. The server ignores it; the
      // point is that the request says what the clerk meant.

      // Act
      await submit(designSource: 'customer', designFee: '40');

      // Assert
      expect(sent().designFee, isNull);
    });

    test('a design fee is sent when it was', () async {
      // Arrange
      // Act
      await submit(designSource: 'in_house', designFee: '40');

      // Assert
      expect(sent().designFee, '40');
    });

    test('an untouched discount box is absent, not a zero', () async {
      // Arrange — `orders.discount` is enforced on the *value*: a clerk without the grant may
      // take an order, and their request must carry no discount at all.

      // Act
      await submit(discount: '   ');

      // Assert
      expect(sent().discount, isNull);
    });
  });

  group('what the clerk left blank', () {
    test('empty text fields are left out rather than sent as empty strings', () async {
      // Arrange
      // Act
      await submit(recipientName: '  ', recipientPhone: '', addressDetails: null, notes: '');

      // Assert
      final order = sent();
      expect(order.recipientName, isNull);
      expect(order.recipientPhone, isNull);
      expect(order.addressDetails, isNull);
      expect(order.notes, isNull);
    });

    test('text that was typed is trimmed and kept', () async {
      // Arrange
      // Act
      await submit(recipientName: '  أحمد  ', addressDetails: 'خلف مسجد النور ');

      // Assert
      final order = sent();
      expect(order.recipientName, 'أحمد');
      expect(order.addressDetails, 'خلف مسجد النور');
    });

    test('a line note that is blank does not become an empty note', () async {
      // Arrange
      const line = DraftOrderLine(
        productId: 7,
        productVariantId: 12,
        quantity: '300',
        notes: '   ',
      );

      // Act
      await submit(lines: const [line]);

      // Assert
      expect(sent().items.single.notes, isNull);
    });

    test('no price named means the catalogue prices the line', () async {
      // Arrange — an empty box is not «this costs nothing»; it is «you tell me».
      const line = DraftOrderLine(
        productId: 7,
        productVariantId: 12,
        quantity: '300',
        unitPrice: '',
      );

      // Act
      await submit(lines: const [line]);

      // Assert
      expect(sent().items.single.unitPrice, isNull);
    });
  });

  test('the lines keep the order they were written in', () async {
    // Arrange
    const lines = [
      DraftOrderLine(productId: 7, productVariantId: 12, quantity: '300'),
      DraftOrderLine(productId: 9, productVariantId: 14, quantity: '50'),
      DraftOrderLine(productId: 4, productVariantId: 5, quantity: '10'),
    ];

    // Act
    await submit(lines: lines);

    // Assert — the invoice reads the way the clerk wrote it.
    final order = sent();
    expect(order.items.map((item) => item.sortOrder), [0, 1, 2]);
    expect(order.items.map((item) => item.productId), [7, 9, 4]);
  });

  test('the destination travels as ids, and an unchosen region is absent', () async {
    // Arrange
    // Act
    await submit(cityId: 4, regionId: null, customerShopId: 2);

    // Assert
    final order = sent();
    expect(order.cityId, 4);
    expect(order.regionId, isNull);
    expect(order.customerShopId, 2);
  });

  test('the order the server stored is what comes back', () async {
    // Arrange
    // Act
    final result = await submit();

    // Assert
    expect(result.getOrElse(() => throw StateError('expected an order')).code, '52');
  });

  test('a refusal is handed back untouched', () async {
    // Arrange
    const failure = Failure.server(
      message: 'العميل «محل النور» معطَّل، ولا تُؤخذ منه طلبيات',
      statusCode: 422,
    );
    when(() => repository.create(any())).thenAnswer((_) async => const Left(failure));

    // Act
    final result = await submit();

    // Assert — the use case invents no wording of its own.
    expect(result.fold((failure) => failure.message, (_) => null), failure.message);
  });
}
