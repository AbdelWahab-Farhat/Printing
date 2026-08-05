import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/viewmodel/customer_detail_cubit.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';
import 'package:printing/features/customers/usecases/get_customer.dart';
import 'package:printing/features/customers/usecases/set_customer_activation.dart';

/// One customer's screen: reading them, and turning them on or off.
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late _MockCustomerRepository repository;
  late CustomerDetailCubit cubit;

  const active = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0913334444',
    isActive: true,
    shops: [],
  );
  final stopped = active.copyWith(isActive: false);

  setUp(() {
    repository = _MockCustomerRepository();
    cubit = CustomerDetailCubit(
      customerId: 7,
      getCustomer: GetCustomer(repository),
      setActivation: SetCustomerActivation(repository),
    );
  });

  tearDown(() => cubit.close());

  blocTest<CustomerDetailCubit, CustomerDetailState>(
    'loads the customer',
    setUp: () {
      // Arrange
      when(() => repository.customer(7)).thenAnswer((_) async => const Right(active));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => const [CustomerDetailState.loading(), CustomerDetailState.loaded(active)],
  );

  blocTest<CustomerDetailCubit, CustomerDetailState>(
    "shows the server's own message when it cannot",
    setUp: () {
      // Arrange
      when(
        () => repository.customer(7),
      ).thenAnswer((_) async => const Left(Failure.server(message: 'العميل غير موجود')));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => const [
      CustomerDetailState.loading(),
      CustomerDetailState.failure(Failure.server(message: 'العميل غير موجود')),
    ],
  );

  blocTest<CustomerDetailCubit, CustomerDetailState>(
    'deactivating keeps the customer on screen while it happens',
    setUp: () {
      // Arrange — a detail screen that blanks to a spinner because one flag was flipped has
      // thrown away the page the user was reading.
      when(() => repository.customer(7)).thenAnswer((_) async => const Right(active));
      when(
        () => repository.setActivation(7, isActive: false),
      ).thenAnswer((_) async => Right(stopped));
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      await cubit.load();
      await cubit.setActive(isActive: false);
    },
    // Assert
    expect: () => [
      const CustomerDetailState.loading(),
      const CustomerDetailState.loaded(active),
      // Still carrying them, mid-flight.
      const CustomerDetailState.changing(active),
      CustomerDetailState.loaded(stopped),
    ],
  );

  blocTest<CustomerDetailCubit, CustomerDetailState>(
    'a refresh after an edit never blanks the page',
    setUp: () {
      // Arrange — coming back from the form reloads with the *changed* customer, and the screen
      // must not flash empty on the way there.
      var call = 0;
      when(() => repository.customer(7)).thenAnswer(
        (_) async => Right(call++ == 0 ? active : active.copyWith(name: 'مطبعة الأمل')),
      );
    },
    build: () => cubit,
    // Act
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    // Assert — `loading` appears once, at the very start, and never again.
    expect: () => [
      const CustomerDetailState.loading(),
      const CustomerDetailState.loaded(active),
      CustomerDetailState.loaded(active.copyWith(name: 'مطبعة الأمل')),
    ],
  );

  test('a second toggle while one is in flight is ignored', () async {
    // Arrange — the dial can be tapped again before the first answer arrives, and two PATCHes
    // racing means the last one wins at random.
    when(() => repository.customer(7)).thenAnswer((_) async => const Right(active));
    when(
      () => repository.setActivation(7, isActive: false),
    ).thenAnswer((_) => Future.delayed(const Duration(milliseconds: 40), () => Right(stopped)));
    await cubit.load();

    // Act
    final first = cubit.setActive(isActive: false);
    await cubit.setActive(isActive: false);
    await first;

    // Assert
    verify(() => repository.setActivation(7, isActive: false)).called(1);
  });

  test('nothing is toggled before the customer has loaded', () async {
    // Arrange — there is no id-less state to act on, and a request fired at nothing would come
    // back and overwrite the load.
    // Act
    await cubit.setActive(isActive: false);

    // Assert
    verifyNever(() => repository.setActivation(any(), isActive: any(named: 'isActive')));
  });
}
