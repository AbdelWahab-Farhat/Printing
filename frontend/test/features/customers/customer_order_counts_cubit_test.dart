import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customer_order_counts_cubit.dart';
import 'package:dayaa/features/orders/models/order_counts.dart';
import 'package:dayaa/features/orders/repositories/order_repository.dart';
import 'package:dayaa/features/orders/usecases/get_order_counts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOrderRepository extends Mock implements OrderRepository {}

/// The three numbers over «إدارة الطلبات» on the customer screen.
///
/// **One request, three numbers.** The summary endpoint already answers per status and already
/// takes `customer_id`, so the groups are added up here rather than asked for three times — see
/// CUSTOMER-ORDERS-SECTION.md §٣.
///
/// Arrange - Act - Assert throughout.
void main() {
  late _MockOrderRepository repository;

  setUp(() => repository = _MockOrderRepository());

  /// A shop-wide answer narrowed to one customer, with a number in each of the three groups.
  const counts = OrderCounts(
    byStatus: {
      'new': 2,
      'designing': 0,
      'printing': 1,
      'ready': 0,
      'shortage': 1,
      'office_pickup': 0,
      'out_for_delivery': 3,
      'returned_courier': 1,
      'returned_carrier': 0,
      'returned_office': 0,
      'resend': 0,
      'delivered': 8,
      'settled': 5,
      'cancelled': 4,
    },
    total: 25,
  );

  void stub(Either<Failure, OrderCounts> answer) {
    when(
      () => repository.statusCounts(
        search: any(named: 'search'),
        customerId: any(named: 'customerId'),
      ),
    ).thenAnswer((_) async => answer);
  }

  CustomerOrderCountsCubit cubitFor(int customerId) => CustomerOrderCountsCubit(
    customerId: customerId,
    getCounts: GetOrderCounts(repository),
  );

  test('it asks only about this customer', () async {
    // Arrange
    stub(const Right(counts));
    final cubit = cubitFor(7);

    // Act
    await cubit.load();

    // Assert — without the id these would be the whole shop's numbers printed under one
    // person's name, which is a screen that looks correct and is not.
    verify(() => repository.statusCounts(customerId: 7)).called(1);
  });

  test('the three numbers are the three groups', () async {
    // Arrange
    stub(const Right(counts));
    final cubit = cubitFor(7);

    // Act
    await cubit.load();

    // Assert
    final state = cubit.state as CustomerOrderCountsLoaded;
    expect(state.total, 25, reason: 'كل طلبات العميل is everything, cancellations included');
    expect(state.inProgress, 8, reason: '2 + 1 + 1 + 3 + 1 — the statuses nobody has finished');
    expect(state.received, 13, reason: '8 delivered + 5 settled');
  });

  test('a cancelled order is counted in the total and in neither group', () async {
    // Arrange — the only orders this customer has are written off.
    stub(
      const Right(OrderCounts(byStatus: {'cancelled': 4}, total: 4)),
    );
    final cubit = cubitFor(7);

    // Act
    await cubit.load();

    // Assert — «كل طلبات العميل ٤» and «الجارية ٠» is the honest pair: they exist, and nobody
    // is working on them.
    final state = cubit.state as CustomerOrderCountsLoaded;
    expect(state.total, 4);
    expect(state.inProgress, 0);
    expect(state.received, 0);
  });

  test('a status this build has never heard of does not break the count', () async {
    // Arrange — the server added one after this build shipped.
    stub(
      const Right(OrderCounts(byStatus: {'new': 1, 'awaiting_courier': 6}, total: 7)),
    );
    final cubit = cubitFor(7);

    // Act
    await cubit.load();

    // Assert — the total still says seven, because it is the server's own sum rather than one
    // added up here out of the statuses this build happens to know.
    final state = cubit.state as CustomerOrderCountsLoaded;
    expect(state.total, 7);
    expect(state.inProgress, 1);
  });

  test('a failure is a state of its own, not a zero', () async {
    // Arrange
    stub(const Left(NetworkFailure(message: FailureMessages.noConnection)));
    final cubit = cubitFor(7);

    // Act
    await cubit.load();

    // Assert — «٠ طلبيات» about a customer whose orders were never counted is a lie the screen
    // must not tell. The section still draws its three ways in; it just draws them bare.
    expect(cubit.state, isA<CustomerOrderCountsFailure>());
  });
}
