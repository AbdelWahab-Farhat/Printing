import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/orders/models/order.dart';
import 'package:dayaa/features/orders/models/order_status.dart';
import 'package:dayaa/features/orders/presentation/widgets/open_ticket_on_order.dart';
import 'package:flutter_test/flutter_test.dart';

/// Why «تذكرة تصميم» is disabled on the «فتح تذكرة» sheet: the server's refusals, read off the
/// order before a request is sent.
///
/// Arrange - Act - Assert throughout.
void main() {
  const customer = Customer(
    id: 10,
    code: 'A730',
    name: 'حساب تجريبي ٢',
    phone: '0910000002',
    isActive: true,
  );

  /// Takes artwork, has a customer, and is not archived: a design ticket may be opened.
  const open = Order(
    id: 1324,
    code: '1324',
    status: OrderStatus.taken,
    statusLabel: 'جديدة',
    isFinal: false,
    customerId: 10,
    cityId: 1,
    designSource: 'ours',
    cityName: 'طرابلس',
    fulfilmentTypeLabel: 'استلام مكتب',
    isOfficePickup: true,
    designSourceLabel: 'من عندنا',
    itemsTotal: '2222.00',
    designFee: '1000.00',
    deliveryPrice: '0.00',
    discount: '0.00',
    grandTotal: '3222.00',
    remainingAmount: '3222.00',
    paymentStatusLabel: 'غير مدفوعة',
    customer: customer,
    designsAreEditable: true,
  );

  setUp(() async {
    await Injector.reset();
    sl.registerSingleton<Session>(
      Session()
        ..adopt(
          const AuthUser(
            id: 1,
            name: 'فرحات',
            phone: '0911234567',
            permissions: ['design_tickets.manage'],
          ),
        ),
    );
  });

  tearDown(Injector.reset);

  test('nothing blocks it on an order that still takes artwork', () {
    // Arrange
    const order = open;

    // Act
    final reason = designTicketBlocker(order);

    // Assert
    expect(reason, isNull);
  });

  test('an archived order says so', () {
    // Arrange
    final order = open.copyWith(deletedAt: DateTime(2026, 11, 13));

    // Act
    final reason = designTicketBlocker(order);

    // Assert
    expect(reason, 'الطلبية في الأرشيف');
  });

  test('an order without a customer says so', () {
    // Arrange
    final order = open.copyWith(customer: null);

    // Act
    final reason = designTicketBlocker(order);

    // Assert
    expect(reason, 'الطلبية بلا عميل');
  });
}
