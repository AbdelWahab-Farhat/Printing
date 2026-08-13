import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/presentation/viewmodel/employee_form_cubit.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/access/usecases/set_user_salary.dart';
import 'package:printing/features/access/usecases/update_user.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// One form, two endpoints.
///
/// **This is the whole reason this Cubit is worth testing.** The wage sits on the same screen as
/// the name but leaves by `PATCH /users/{id}/salary`, because the server guards the two
/// differently — `users.salary` against `users.manage`. What the person filling the form sees is
/// one «حفظ»; what has to be true underneath is that the second request is sent when, and only
/// when, there is a wage to send.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;
  late EmployeeFormCubit cubit;

  const employee = AuthUser(
    id: 4,
    name: 'محمد عز الدين',
    phone: '0944909851',
    email: 'mohamed@printing.ly',
    salary: '2500.00',
  );

  void arrangeDetails([AuthUser saved = employee]) {
    when(
      () => repository.updateUser(
        userId: any(named: 'userId'),
        name: any(named: 'name'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async => right(saved));
  }

  Future<void> submit({Option<String?> salary = const None()}) {
    return cubit.submit(
      userId: 4,
      name: 'محمد عز الدين',
      email: 'mohamed@printing.ly',
      phone: '0944909851',
      salary: salary,
    );
  }

  setUp(() {
    repository = _MockAccessRepository();
    cubit = EmployeeFormCubit(
      updateUser: UpdateUser(repository),
      setSalary: SetUserSalary(repository),
    );
  });

  tearDown(() => cubit.close());

  test('an edit that did not touch the wage is one request, not two', () async {
    // Arrange — the ordinary case: somebody corrected a phone number.
    arrangeDetails();

    // Act
    await submit();

    // Assert — and this is also what keeps a reader without `users.salary`, who never saw the
    // box, from sending a request the server would refuse.
    verifyNever(() => repository.setUserSalary(any(), any()));
    expect(cubit.state.saved, employee);
  });

  test('a changed wage follows the details, to its own endpoint', () async {
    // Arrange
    arrangeDetails();
    when(() => repository.setUserSalary(4, '3000')).thenAnswer(
      (_) async => right(employee.copyWith(salary: '3000.00')),
    );

    // Act
    await submit(salary: const Some('3000'));

    // Assert — the employee the form pops with is the one the *second* answer carried, or the
    // screen behind would show the old wage until it refreshed.
    verify(() => repository.setUserSalary(4, '3000')).called(1);
    expect(cubit.state.saved?.salary, '3000.00');
  });

  test('an emptied box clears the wage rather than sending an empty string', () async {
    // Arrange
    arrangeDetails();
    when(() => repository.setUserSalary(4, null)).thenAnswer(
      (_) async => right(employee.copyWith(salary: null)),
    );

    // Act
    await submit(salary: const Some(''));

    // Assert — «لم يُحدَّد» has to stay reachable, and `''` would come back a 422 about a box
    // somebody emptied deliberately.
    verify(() => repository.setUserSalary(4, null)).called(1);
  });

  test('a refused edit never reaches the wage', () async {
    // Arrange — a duplicate phone number, say.
    when(
      () => repository.updateUser(
        userId: any(named: 'userId'),
        name: any(named: 'name'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer(
      (_) async => left(const Failure.server(message: 'رقم الهاتف مستخدم مسبقاً')),
    );

    // Act
    await submit(salary: const Some('3000'));

    // Assert — a wage set against a form that did not save would be half an edit nobody asked
    // for, and the screen would report a failure while one of the two halves had landed.
    verifyNever(() => repository.setUserSalary(any(), any()));
    expect(cubit.state.saved, isNull);
    expect(cubit.state.failure, isNotNull);
  });

  test('a refused wage leaves the form open, saying so, with the details already stored', () async {
    // Arrange
    arrangeDetails();
    when(() => repository.setUserSalary(4, any())).thenAnswer(
      (_) async => left(const Failure.forbidden(message: 'لا تملك صلاحية')),
    );

    // Act
    await submit(salary: const Some('3000'));

    // Assert — `saved` stays null so the form does not pop: the screen must not report success
    // for a save that half happened. Submitting again is safe — both requests are idempotent —
    // which is what makes «أعد المحاولة» an honest offer here.
    expect(cubit.state.saved, isNull);
    expect(cubit.state.failure, isNotNull);
    expect(cubit.state.isSubmitting, isFalse);
  });

  test('a second tap while the first is in flight is ignored', () async {
    // Arrange
    when(
      () => repository.updateUser(
        userId: any(named: 'userId'),
        name: any(named: 'name'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
      ),
    ).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));

      return right(employee);
    });

    // Act
    final first = submit();
    await submit();
    await first;

    // Assert — one PUT, not two.
    verify(
      () => repository.updateUser(
        userId: any(named: 'userId'),
        name: any(named: 'name'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
      ),
    ).called(1);
  });
}
