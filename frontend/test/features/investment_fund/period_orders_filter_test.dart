import 'package:dayaa/core/utils/digits.dart';
import 'package:dayaa/features/investment_fund/models/period_orders.dart';
import 'package:dayaa/features/investment_fund/presentation/viewmodel/period_orders_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

/// تصفيةُ طلبيات الفترة على الهاتف — قرارُ المالك ٤ في §١١.
///
/// **المرشّحُ يقرأ `states`**: طلبيةٌ انقسم ربحُها تظهر تحت حالتيها، فتجمع الصفوفُ تحت كلّ
/// مرشّحٍ إلى رقمه في المجموع.
///
/// Arrange - Act - Assert في كلٍّ منها.
void main() {
  PeriodOrder order(
    int id, {
    String code = '',
    String? customer,
    String total = '0.00',
    List<PeriodProfitState> states = const [],
    PeriodProfitState? state,
    PeriodOrderByState? byState,
    DateTime? at,
    List<PeriodInvestorShare> investors = const [],
  }) => PeriodOrder(
    orderId: id,
    code: code.isEmpty ? 'ORD-$id' : code,
    status: 'delivered',
    statusLabel: 'تم الاستلام',
    customerName: customer,
    grandTotal: '1000.00',
    investorsTotal: total,
    states: states,
    profitState: state ?? (states.isEmpty ? null : states.first),
    byState: byState,
    occurredAt: at,
    investors: investors,
  );

  test('an order split across two gates is listed under both', () {
    // Arrange — هامشٌ أُفرج عنه، وربحُ تسليمٍ محجوز.
    final split = order(
      1,
      states: const [PeriodProfitState.awaitingPayment, PeriodProfitState.released],
    );
    final paid = order(2, states: const [PeriodProfitState.released]);

    // Act
    final released = visiblePeriodOrders([split, paid], filter: PeriodOrdersFilter.received);
    final held = visiblePeriodOrders([split, paid], filter: PeriodOrdersFilter.waiting);

    // Assert
    expect(released.map((o) => o.orderId), unorderedEquals([1, 2]));
    expect(held.map((o) => o.orderId), [1]);
  });

  test('«في الانتظار» gathers both waiting gates, and «قيد التسليم» stays apart', () {
    // Arrange — مفتوحةٌ تنتظر موعدَها، ومنتظِرةٌ تنتظر التحصيل، وطلبيةٌ في الطريق.
    final periodEnd = order(1, states: const [PeriodProfitState.awaitingPeriodEnd]);
    final payment = order(2, states: const [PeriodProfitState.awaitingPayment]);
    final road = order(3, states: const [PeriodProfitState.awaitingDelivery]);
    final all = [periodEnd, payment, road];

    // Act
    final waiting = visiblePeriodOrders(all, filter: PeriodOrdersFilter.waiting);
    final onTheRoad = visiblePeriodOrders(all, filter: PeriodOrdersFilter.onTheRoad);

    // Assert
    expect(waiting.map((o) => o.orderId), unorderedEquals([1, 2]));
    expect(onTheRoad.map((o) => o.orderId), [3]);
  });

  test('the waiting total adds both gates from the server totals', () {
    // Arrange
    const totals = PeriodStatesTotals(
      awaitingPayment: PeriodStateTotal(orders: 2, amount: '90.00'),
      awaitingPeriodEnd: PeriodStateTotal(orders: 1, amount: '15.50'),
      released: PeriodStateTotal(orders: 4, amount: '300.00'),
    );

    // Act
    final waiting = totals.ofFilter(PeriodOrdersFilter.waiting);
    final received = totals.ofFilter(PeriodOrdersFilter.received);

    // Assert
    expect(waiting.orders, 3);
    expect(waiting.amount.grouped, '105.5');
    expect(received.amount, '300.00');
  });

  test('the search reads Arabic digits as the code is written', () {
    // Arrange
    final orders = [order(1, code: 'ORD-0091'), order(2, code: 'ORD-0092')];

    // Act
    final found = visiblePeriodOrders(orders, query: '٩١');

    // Assert
    expect(found.map((o) => o.orderId), [1]);
  });

  test('the search finds a customer by part of the name', () {
    // Arrange
    final orders = [order(1, customer: 'مطعم البركة'), order(2, customer: 'مخبز النور')];

    // Act
    final found = visiblePeriodOrders(orders, query: 'النور');

    // Assert
    expect(found.map((o) => o.orderId), [2]);
  });

  test('newest first, and oldest when asked', () {
    // Arrange
    final orders = [
      order(1, at: DateTime(2026, 9, 3)),
      order(2, at: DateTime(2026, 9, 20)),
      order(3, at: DateTime(2026, 9, 10)),
    ];

    // Act
    final newest = visiblePeriodOrders(orders);
    final oldest = visiblePeriodOrders(orders, sort: PeriodOrdersSort.oldest);

    // Assert
    expect(newest.map((o) => o.orderId), [2, 3, 1]);
    expect(oldest.map((o) => o.orderId), [1, 3, 2]);
  });

  test('the largest profit counts what an order on the road will bring', () {
    // Arrange — طلبيةٌ في الطريق بلا صفٍّ في الدفتر رقمُها ما سيصل عند التسليم.
    final onTheRoad = order(
      1,
      states: const [PeriodProfitState.awaitingDelivery],
      byState: const PeriodOrderByState(awaitingDelivery: '900.00'),
    );
    final delivered = order(
      2,
      total: '300.00',
      states: const [PeriodProfitState.awaitingPeriodEnd],
      investors: const [PeriodInvestorShare(investorId: 1, name: 'أحمد', amount: '300.00')],
    );

    // Act
    final largest = visiblePeriodOrders([delivered, onTheRoad], sort: PeriodOrdersSort.largest);

    // Assert
    expect(largest.map((o) => o.orderId), [1, 2]);
  });
}
