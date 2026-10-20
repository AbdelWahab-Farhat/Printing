import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/features/orders/models/new_order.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_flow.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/order_invoice_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/record_vendor_cost.dart';
import 'package:dayaa/features/orders/usecases/take_order.dart';
import 'package:dayaa/features/orders/usecases/update_order_invoice.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «تكلفة المورد» typed for an order — OUTSOURCED-PRODUCTS.md §6.1.
///
/// What the two forms send: the figure as ASCII when somebody typed it, and no key at all when
/// nobody did, because the server reads an absent cost as «the catalogue's» on a new line and
/// «leave it» on a kept one.
///
/// Arrange - Act - Assert throughout.
class _MockOrderRepository extends Mock implements OrderRepository {}

class _FakeNewOrder extends Fake implements NewOrder {}

class _FakeLine extends Fake implements InvoiceLineUpdate {}

void main() {
  late _MockOrderRepository repository;

  const stored = Order(
    id: 7,
    code: '7',
    status: OrderStatus.taken,
    statusLabel: 'جديدة',
    isFinal: false,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    designSourceLabel: 'بدون تصميم',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    itemsTotal: '200.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '200.00',
  );

  setUpAll(() {
    registerFallbackValue(_FakeNewOrder());
    registerFallbackValue(<InvoiceLineUpdate>[_FakeLine()]);
  });

  setUp(() => repository = _MockOrderRepository());

  // ───────────────────────────── taking the order ─────────────────────────────

  group('TakeOrder', () {
    setUp(() {
      when(() => repository.create(any())).thenAnswer((_) async => const Right(stored));
    });

    Future<Map<String, dynamic>> sentLine({String? unitCost}) async {
      await TakeOrder(repository)(
        customerId: 5,
        cityId: 3,
        lines: [
          DraftOrderLine(
            productId: 10,
            productVariantId: 20,
            quantity: '100',
            unitPrice: '2',
            unitCost: unitCost,
          ),
        ],
      );

      final order = verify(() => repository.create(captureAny())).captured.single as NewOrder;

      return order.items.single.toJson();
    }

    test('a typed vendor cost travels as ASCII', () async {
      // Act — what a Libyan keyboard produces.
      final line = await sentLine(unitCost: '٠,٨');

      // Assert
      expect(line['unit_cost'], '0.8');
    });

    test('an empty box sends no key, so the catalogue or «جاهزة» answers', () async {
      // Act
      final line = await sentLine(unitCost: '  ');

      // Assert
      expect(line.containsKey('unit_cost'), isFalse);
    });
  });

  // ───────────────────────────── after «جاهزة» ─────────────────────────────

  test('RecordVendorCost sends the figure in ASCII', () async {
    // Arrange
    when(
      () => repository.recordVendorCost(any(), any(), unitCost: any(named: 'unitCost')),
    ).thenAnswer((_) async => const Right(stored));

    // Act
    await RecordVendorCost(repository)(7, 1, unitCost: '٠٫٨');

    // Assert
    verify(() => repository.recordVendorCost(7, 1, unitCost: '0.8')).called(1);
  });

  // ───────────────────────────── editing the order ─────────────────────────────

  group('OrderInvoiceCubit', () {
    Order vendorOrder({String? unitCost}) => stored.copyWith(
      productionFlow: OrderFlow.outsourced,
      // A وسيط order without a vendor is a form the screen refuses to save.
      vendorId: 3,
      vendorName: 'مطبعة النور',
      itemsAreEditable: true,
      destinationIsEditable: true,
      items: [
        OrderItem(
          id: 1,
          productId: 10,
          productVariantId: 20,
          productName: 'ستيكر',
          variantLabel: '5*5',
          pricingUnitLabel: 'قطعة',
          quantity: '100',
          unitPrice: '2.000',
          lineTotal: '200.00',
          unitCost: unitCost,
        ),
      ],
    );

    OrderInvoiceCubit cubitFor(Order order) =>
        OrderInvoiceCubit(order: order, updateInvoice: UpdateOrderInvoice(repository));

    void stubSave() {
      when(
        () => repository.updateInvoice(
          any(),
          lines: any(named: 'lines'),
          discount: any(named: 'discount'),
          cityId: any(named: 'cityId'),
          regionId: any(named: 'regionId'),
          recipientPhone: any(named: 'recipientPhone'),
          isUrgent: any(named: 'isUrgent'),
          vendor: any(named: 'vendor'),
        ),
      ).thenAnswer((_) async => Right(vendorOrder()));
    }

    Map<String, dynamic> sentLine() =>
        (verify(
                  () => repository.updateInvoice(
                    any(),
                    lines: captureAny(named: 'lines'),
                    discount: any(named: 'discount'),
                    cityId: any(named: 'cityId'),
                    regionId: any(named: 'regionId'),
                    recipientPhone: any(named: 'recipientPhone'),
                    isUrgent: any(named: 'isUrgent'),
                    vendor: any(named: 'vendor'),
                  ),
                ).captured.last
                as List<InvoiceLineUpdate>)
            .single
            .toJson();

    test('the box opens on the line’s own figure', () {
      // Act
      final cubit = cubitFor(vendorOrder(unitCost: '0.800'));

      // Assert
      expect(cubit.state.lines.single.unitCost, '0.800');
      expect(cubit.state.isDirty, isFalse);
    });

    test('a changed cost is sent, in ASCII', () async {
      // Arrange
      final cubit = cubitFor(vendorOrder(unitCost: '0.800'));
      stubSave();

      // Act
      cubit.setUnitCost(1, '٠,٩');
      await cubit.save();

      // Assert
      expect(sentLine()['unit_cost'], '0.9');
    });

    test('an untouched cost is not sent', () async {
      // Arrange — the same figure, retyped with trailing zeros dropped.
      final cubit = cubitFor(vendorOrder(unitCost: '0.800'));
      stubSave();

      // Act
      cubit
        ..setUnitCost(1, '0.8')
        ..setUrgent(true);
      await cubit.save();

      // Assert
      expect(sentLine().containsKey('unit_cost'), isFalse);
    });

    test('a reader without the grant never sends one', () async {
      // Arrange — the server omitted the key, so the line opened with nothing.
      final cubit = cubitFor(vendorOrder());
      stubSave();

      // Act
      cubit.setUrgent(true);
      await cubit.save();

      // Assert
      expect(sentLine().containsKey('unit_cost'), isFalse);
    });

    test('a cost that is not a number shuts the save', () {
      // Arrange
      final cubit = cubitFor(vendorOrder(unitCost: '0.800'));

      // Act
      cubit.setUnitCost(1, 'abc');

      // Assert
      expect(cubit.state.isValid, isFalse);
    });

    test('a line of ours never carries one, whatever was typed', () async {
      // Arrange — the road is ours, so the box is never drawn.
      final cubit = cubitFor(vendorOrder().copyWith(productionFlow: OrderFlow.standard));
      stubSave();

      // Act
      cubit.setUnitCost(1, '0.5');
      await cubit.save();

      // Assert
      expect(sentLine().containsKey('unit_cost'), isFalse);
    });
  });
}
