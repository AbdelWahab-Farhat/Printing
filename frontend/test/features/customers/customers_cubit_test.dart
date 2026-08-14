import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/customers/models/customer.dart';
import 'package:dayaa/features/customers/models/customers_filter.dart';
import 'package:dayaa/features/customers/presentation/viewmodel/customers_cubit.dart';
import 'package:dayaa/features/customers/repositories/customer_repository.dart';
import 'package:dayaa/features/customers/usecases/get_customers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
        hasOrders: any(named: 'hasOrders'),
        sort: any(named: 'sort'),
        page: any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => result);
  }

  // `any(named: 'sort')` needs something of the type to stand in for. Any case will do — the
  // matcher never reads it.
  setUpAll(() => registerFallbackValue(CustomersSort.newest));

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
          hasOrders: any(named: 'hasOrders'),
          sort: any(named: 'sort'),
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    },
  );

  // ─────────────────────────── the activity filter ───────────────────────────

  blocTest<CustomersCubit, CustomersState>(
    'the list opens on everybody, in no particular order',
    setUp: () {
      // Arrange
      arrangeCustomers(right(page([customer])));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.load(),
    // Assert — nothing about the orders is asked for until somebody asks.
    verify: (_) {
      verify(
        () => repository.customers(
          search: any(named: 'search'),
          isActive: any(named: 'isActive'),
          hasOrders: null,
          sort: CustomersSort.newest,
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    },
  );

  blocTest<CustomersCubit, CustomersState>(
    'the sheet\'s two ticks reach the API as has_orders and sort',
    setUp: () {
      // Arrange
      arrangeCustomers(right(page([customer])));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.applyFilter(
      const CustomersFilter(hasOrders: false, leastRecentOrderFirst: true),
    ),
    // Assert
    verify: (_) {
      verify(
        () => repository.customers(
          search: any(named: 'search'),
          isActive: any(named: 'isActive'),
          hasOrders: false,
          sort: CustomersSort.leastRecentOrder,
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    },
  );

  blocTest<CustomersCubit, CustomersState>(
    'filtering keeps the term already in the search box',
    setUp: () {
      // Arrange
      arrangeCustomers(right(page([customer])));
    },
    build: () => cubit,
    // Act — the box is not cleared by opening the sheet, so the list must not be either.
    act: (cubit) async {
      await cubit.load(search: 'مطبعة');
      await cubit.applyFilter(const CustomersFilter(hasOrders: false));
    },
    // Assert
    verify: (_) {
      verify(
        () => repository.customers(
          search: 'مطبعة',
          isActive: any(named: 'isActive'),
          hasOrders: false,
          sort: any(named: 'sort'),
          page: 1,
          perPage: any(named: 'perPage'),
        ),
      ).called(1);
    },
  );

  blocTest<CustomersCubit, CustomersState>(
    'the filter rides along on the pages after the first',
    setUp: () {
      // Arrange — two pages, so `loadMore` has somewhere to go.
      arrangeCustomers(right(page([customer], last: 2)));
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      await cubit.applyFilter(const CustomersFilter(hasOrders: false));
      await cubit.loadMore();
    },
    // Assert — page two of «بدون طلبات» must not arrive as page two of everybody, which is the
    // bug every filtered list ships once.
    verify: (_) {
      verify(
        () => repository.customers(
          search: any(named: 'search'),
          isActive: any(named: 'isActive'),
          hasOrders: false,
          sort: any(named: 'sort'),
          page: 2,
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
