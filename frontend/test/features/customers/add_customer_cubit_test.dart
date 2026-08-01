import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/customers/models/customer.dart';
import 'package:printing/features/customers/presentation/viewmodel/add_customer_cubit.dart';
import 'package:printing/features/customers/repositories/customer_repository.dart';
import 'package:printing/features/customers/usecases/create_customer.dart';

/// The repository is faked, nothing touches Dio, and the assertions are on the sequence of
/// states the screen would have rendered.
///
/// Arrange - Act - Assert throughout.
class _MockCustomerRepository extends Mock implements CustomerRepository {}

void main() {
  late _MockCustomerRepository repository;
  late AddCustomerCubit cubit;

  // What the API answers with: the `code` is allocated by the server and is the one piece of
  // the reply the screen actually reads back to the user.
  const created = Customer(
    id: 7,
    code: 'C7',
    name: 'مطبعة النور',
    phone: '0913334444',
    isActive: true,
    shops: [],
  );

  setUp(() {
    repository = _MockCustomerRepository();
    cubit = AddCustomerCubit(createCustomer: CreateCustomer(repository));
  });

  tearDown(() => cubit.close());

  void arrangeCreate(Either<Failure, Customer> result) {
    when(
      () => repository.create(name: any(named: 'name'), phone: any(named: 'phone')),
    ).thenAnswer((_) async => result);
  }

  // ─────────────────────────── creating ───────────────────────────

  blocTest<AddCustomerCubit, AddCustomerState>(
    'emits submitting then success when the server accepts the customer',
    setUp: () => arrangeCreate(const Right(created)),
    build: () => cubit,
    act: (cubit) => cubit.submit(name: 'مطبعة النور', phone: '0913334444'),
    expect: () => const [
      AddCustomerState.submitting(),
      AddCustomerState.success(created),
    ],
  );

  blocTest<AddCustomerCubit, AddCustomerState>(
    'surfaces the server\'s own message, not a generic one',
    setUp: () => arrangeCreate(
      const Left(
        ServerFailure(
          message: 'رقم الهاتف مستخدم مسبقاً لعميل آخر',
          statusCode: 422,
          fieldErrors: {
            'phone': ['رقم الهاتف مستخدم مسبقاً لعميل آخر'],
          },
        ),
      ),
    ),
    build: () => cubit,
    act: (cubit) => cubit.submit(name: 'مطبعة النور', phone: '0913334444'),
    expect: () => const [
      AddCustomerState.submitting(),
      AddCustomerState.failure(
        ServerFailure(
          message: 'رقم الهاتف مستخدم مسبقاً لعميل آخر',
          statusCode: 422,
          fieldErrors: {
            'phone': ['رقم الهاتف مستخدم مسبقاً لعميل آخر'],
          },
        ),
      ),
    ],
  );

  test('a second submit while one is in flight is ignored', () async {
    // Arrange — an impatient double tap on a *create* button is the one that matters: two
    // requests would be two customers if the phone were not unique server-side.
    var calls = 0;
    when(
      () => repository.create(name: any(named: 'name'), phone: any(named: 'phone')),
    ).thenAnswer((_) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 30));

      return const Right(created);
    });

    // Act — deliberately not awaited, so the second call lands mid-flight.
    final first = cubit.submit(name: 'مطبعة النور', phone: '0913334444');
    final second = cubit.submit(name: 'مطبعة النور', phone: '0913334444');
    await Future.wait([first, second]);

    // Assert
    expect(calls, 1);
  });

  // ─────────────────────────── what reaches the API ───────────────────────────

  test('the name is trimmed before it reaches the repository', () async {
    // Arrange — a name pasted from a message carries whitespace, and the customer it creates
    // is one nobody can find by searching for it.
    arrangeCreate(const Right(created));

    // Act
    await cubit.submit(name: '  مطبعة النور  ', phone: '0913334444');

    // Assert
    verify(
      () => repository.create(name: 'مطبعة النور', phone: '0913334444'),
    ).called(1);
  });

  test('an Arabic-Indic phone number is sent as western digits', () async {
    // Arrange — that is what a Libyan keyboard produces, and the API's `^\d{9,15}$` is
    // ASCII-only, so sending it through untouched is a 422 the user cannot diagnose.
    arrangeCreate(const Right(created));

    // Act
    await cubit.submit(name: 'مطبعة النور', phone: '٠٩١٣٣٣٤٤٤٤');

    // Assert
    verify(
      () => repository.create(name: 'مطبعة النور', phone: '0913334444'),
    ).called(1);
  });

  // ─────────────────────────── what the screen reads ───────────────────────────

  test('field errors are offered under the field the server blamed', () async {
    // Arrange
    arrangeCreate(
      const Left(
        ServerFailure(
          message: 'البيانات المدخلة غير صحيحة',
          statusCode: 422,
          fieldErrors: {
            'name': ['اسم العميل يجب أن يكون حرفين على الأقل'],
            'phone': ['رقم الهاتف مستخدم مسبقاً لعميل آخر'],
          },
        ),
      ),
    );

    // Act
    await cubit.submit(name: 'م', phone: '0913334444');

    // Assert
    expect(cubit.state.nameError, 'اسم العميل يجب أن يكون حرفين على الأقل');
    expect(cubit.state.phoneError, 'رقم الهاتف مستخدم مسبقاً لعميل آخر');
  });

  test('a network failure carries no field error, so the screen shows a snackbar', () async {
    // Arrange
    arrangeCreate(const Left(NetworkFailure(message: FailureMessages.noConnection)));

    // Act
    await cubit.submit(name: 'مطبعة النور', phone: '0913334444');

    // Assert
    expect(cubit.state.nameError, isNull);
    expect(cubit.state.phoneError, isNull);
    expect(cubit.state, isA<AddCustomerFailure>());
  });

  blocTest<AddCustomerCubit, AddCustomerState>(
    'clearFailure returns to initial so the error under a field disappears while typing',
    setUp: () => arrangeCreate(
      const Left(ServerFailure(message: 'خطأ', statusCode: 422)),
    ),
    build: () => cubit,
    act: (cubit) async {
      await cubit.submit(name: 'مطبعة النور', phone: '0913334444');
      cubit.clearFailure();
    },
    expect: () => const [
      AddCustomerState.submitting(),
      AddCustomerState.failure(ServerFailure(message: 'خطأ', statusCode: 422)),
      AddCustomerState.initial(),
    ],
  );

  blocTest<AddCustomerCubit, AddCustomerState>(
    'clearFailure does nothing when there is no failure to clear',
    build: () => cubit,
    act: (cubit) => cubit.clearFailure(),
    expect: () => const <AddCustomerState>[],
  );
}
