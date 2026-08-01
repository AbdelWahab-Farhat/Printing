import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/network/paginated.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';
import 'package:printing/features/customers/usecases/get_customers.dart';

/// Paging itself is proved once in `test/core/pagination/paged_cubit_test.dart`. What is left to
/// prove here is the part that is about customers: that the screen's search reaches the API as
/// the API's own `search` parameter, and that the rows come back as customers.
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late _MockCustomerRepository repository;
  late CustomersCubit cubit;

  const customer = Customer(
    id: 1,
    code: 'C1',
    name: 'مطبعة النور',
    phone: '0912345678',
    isActive: true,
  );

  Paginated<Customer> page(List<Customer> items, {int current = 1, int last = 1}) => Paginated(
    items: items,
    meta: PageMeta(currentPage: current, perPage: 20, lastPage: last, total: items.length),
  );

  void arrangeCustomers(Either<Failure, Paginated<Customer>> result) {
    when(
      () => repository.customers(
        search: any(named: 'search'),
        isActive: any(named: 'isActive'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUp(() {
    repository = _MockCustomerRepository();
    cubit = CustomersCubit(getCustomers: GetCustomers(repository));
  });

  tearDown(() => cubit.close());

  blocTest<CustomersCubit, CustomersState>(
    'goes loading then loaded when the list answers',
    setUp: () {
      // Arrange
      arrangeCustomers(right(page([customer])));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      const CustomersState.loading(),
      CustomersState.loaded(page: page([customer])),
    ],
  );

  blocTest<CustomersCubit, CustomersState>(
    "shows the server's own message rather than a generic one",
    setUp: () {
      // Arrange
      arrangeCustomers(left(const Failure.forbidden(message: 'ليس لديك صلاحية')));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => const [
      CustomersState.loading(),
      CustomersState.failure(Failure.forbidden(message: 'ليس لديك صلاحية')),
    ],
  );

  blocTest<CustomersCubit, CustomersState>(
    'a phone number typed into the box is what the API is asked for',
    setUp: () {
      // Arrange
      arrangeCustomers(right(page([customer])));
    },
    build: () => cubit,
    // Act — the API matches a name, a code or a phone with the same parameter.
    act: (cubit) => cubit.search(' 0912345678 '),
    wait: const Duration(milliseconds: 500),
    // Assert — trimmed, and sent as `search`.
    verify: (_) {
      verify(
        () => repository.customers(
          search: '0912345678',
          isActive: any(named: 'isActive'),
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    },
  );

  blocTest<CustomersCubit, CustomersState>(
    'an empty list is a loaded state, not a failure',
    setUp: () {
      // Arrange
      arrangeCustomers(right(page([])));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => [
      const CustomersState.loading(),
      isA<CustomersLoaded>().having((state) => state.page.isEmpty, 'is empty', isTrue),
    ],
  );
}
