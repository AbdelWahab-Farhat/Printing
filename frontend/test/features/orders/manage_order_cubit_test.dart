import 'package:dartz/dartz.dart' hide Order;
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/orders/models/managed_line.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/viewmodel/manage_order_cubit.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

void main() {
  late _MockOrderRepository repository;

  OrderItem itemWith({int id = 1, String quantity = '300.000', String price = '1.100'}) {
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

  Order orderWith(List<OrderItem> items) => Order(
    id: 7,
    code: '7',
    status: OrderStatus.readyToPrint,
    statusLabel: 'جاهزة للطباعة',
    isFinal: false,
    customerId: 5,
    cityId: 3,
    designSource: 'none',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'توصيل',
    isOfficePickup: false,
    designSourceLabel: 'بدون تصميم',
    itemsTotal: '530.00',
    designFee: '0.00',
    deliveryPrice: '20.00',
    discount: '0.00',
    grandTotal: '550.00',
    items: items,
  );

  setUp(() => repository = _MockOrderRepository());

  test('it opens clean, on each line its own quantity and price', () {
    // Arrange & Act
    final cubit = ManageOrderCubit(order: orderWith([itemWith()]), repository: repository);

    // Assert
    expect(cubit.state.isDirty, isFalse);
    expect(cubit.state.lines.single.unitPrice, '1.100');
  });

  test('the same figure typed differently is not a change', () {
    // Arrange
    final cubit = ManageOrderCubit(order: orderWith([itemWith()]), repository: repository);

    // Act
    cubit
      ..setQuantity(1, '٣٠٠')
      ..setUnitPrice(1, '1.1');

    // Assert
    expect(cubit.state.isDirty, isFalse);
  });

  test('only the changed lines are sent, the price always with them', () async {
    // Arrange
    final order = orderWith([itemWith(), itemWith(id: 2, quantity: '100.000', price: '2.000')]);
    final cubit = ManageOrderCubit(order: order, repository: repository);
    List<ManagedLine>? sent;
    when(() => repository.manageLines(any(), lines: any(named: 'lines'))).thenAnswer((call) async {
      sent = call.namedArguments[#lines] as List<ManagedLine>;
      return Right(order);
    });

    // Act — only the quantity of the second line moves.
    cubit.setQuantity(2, '١٥٠');
    await cubit.save();

    // Assert
    expect(sent, hasLength(1));
    expect(sent!.single.toJson(), {'id': 2, 'quantity': '150', 'unit_price': '2.000'});
    expect(cubit.state.saved, order);
  });

  test('a refusal about a sent line is drawn under that line on the screen', () async {
    // Arrange — the second line is the first one sent, so the server calls it items.0.
    final order = orderWith([itemWith(), itemWith(id: 2, quantity: '100.000', price: '2.000')]);
    final cubit = ManageOrderCubit(order: order, repository: repository);
    when(() => repository.manageLines(any(), lines: any(named: 'lines'))).thenAnswer(
      (_) async => const Left(
        Failure.server(
          message: 'رفض',
          fieldErrors: {
            'items.0.unit_price': ['السعر غير صالح'],
          },
        ),
      ),
    );

    // Act
    cubit.setUnitPrice(2, '3');
    await cubit.save();

    // Assert
    expect(cubit.state.errorAt(1, 'unit_price'), 'السعر غير صالح');
    expect(cubit.state.errorAt(0, 'unit_price'), isNull);
  });

  test('an empty price cannot be saved', () {
    // Arrange
    final cubit = ManageOrderCubit(order: orderWith([itemWith()]), repository: repository);

    // Act
    cubit.setUnitPrice(1, '');

    // Assert
    expect(cubit.state.isValid, isFalse);
  });
}
