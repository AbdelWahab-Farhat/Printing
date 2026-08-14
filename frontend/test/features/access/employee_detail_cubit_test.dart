import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/presentation/viewmodel/employee_detail_cubit.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/access/usecases/get_user.dart';
import 'package:dayaa/features/access/usecases/set_user_activation.dart';
import 'package:dayaa/features/access/usecases/set_user_password.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// One employee's screen, and the two changes it makes without leaving itself.
///
/// **What is proved here is the part that is easy to get wrong**: that the employee stays on
/// screen while a request is in flight and after one fails, and that a failed change reports
/// `false` so the sheet that asked for it knows not to close.
///
/// The wage is not here — it is a field on the edit form, and `EmployeeFormCubit` owns it.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;
  late EmployeeDetailCubit cubit;

  const employee = AuthUser(
    id: 4,
    name: 'محمد عز الدين',
    phone: '0944909851',
    email: 'mohamed@printing.ly',
    employeeCode: 'E4',
    salary: '2500.00',
  );

  EmployeeDetailCubit build() => EmployeeDetailCubit(
    userId: 4,
    getUser: GetUser(repository),
    setPassword: SetUserPassword(repository),
    setActivation: SetUserActivation(repository),
  );

  setUp(() {
    repository = _MockAccessRepository();
    cubit = build();
  });

  tearDown(() => cubit.close());

  // ─────────────────────────── reading ───────────────────────────

  blocTest<EmployeeDetailCubit, EmployeeDetailState>(
    'goes loading then loaded when the employee answers',
    setUp: () {
      // Arrange
      when(() => repository.user(4)).thenAnswer((_) async => right(employee));
    },
    build: build,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => const [
      EmployeeDetailState.loading(),
      EmployeeDetailState.loaded(employee),
    ],
  );

  blocTest<EmployeeDetailCubit, EmployeeDetailState>(
    "a first read that fails leaves nothing to show, and says the server's own words",
    setUp: () {
      // Arrange
      when(() => repository.user(4)).thenAnswer(
        (_) async => left(const Failure.forbidden(message: 'ليس لديك صلاحية')),
      );
    },
    build: build,
    // Act
    act: (cubit) => cubit.load(),
    // Assert
    expect: () => const [
      EmployeeDetailState.loading(),
      EmployeeDetailState.failure(Failure.forbidden(message: 'ليس لديك صلاحية')),
    ],
  );

  blocTest<EmployeeDetailCubit, EmployeeDetailState>(
    're-reading does not blank the screen somebody is looking at',
    setUp: () {
      // Arrange
      when(() => repository.user(4)).thenAnswer((_) async => right(employee));
    },
    build: build,
    // Act — the second load is the one after an edit.
    act: (cubit) async {
      await cubit.load();
      await cubit.load();
    },
    // Assert — **two states for two reads**, and both facts are in that: no second `loading`
    // between them, which is the property under test; and no second `loaded` either, because
    // the employee came back unchanged and a Cubit does not re-emit a state equal to the one it
    // is in. A screen that blanked here would show a spinner every time somebody saved an edit.
    expect: () => const [
      EmployeeDetailState.loading(),
      EmployeeDetailState.loaded(employee),
    ],
  );

  // ─────────────────────────── the password ───────────────────────────

  blocTest<EmployeeDetailCubit, EmployeeDetailState>(
    'setting a password keeps the employee on screen throughout',
    setUp: () {
      // Arrange
      when(() => repository.user(4)).thenAnswer((_) async => right(employee));
      when(() => repository.setUserPassword(4, any())).thenAnswer(
        (_) async => right(employee),
      );
    },
    build: build,
    // Act
    act: (cubit) async {
      await cubit.load();
      await cubit.setPassword('كلمة-جديدة');
    },
    // Assert — `changing` carries the employee, so the page is never replaced by a spinner. The
    // final state equals the one before it, so the Cubit does not re-emit: the account did not
    // change, only the credential behind it, which this screen never holds.
    expect: () => const [
      EmployeeDetailState.loading(),
      EmployeeDetailState.loaded(employee),
      EmployeeDetailState.changing(employee),
      EmployeeDetailState.loaded(employee),
    ],
  );

  test('a refused password keeps the employee, carries the reason, and answers false', () async {
    // Arrange
    when(() => repository.user(4)).thenAnswer((_) async => right(employee));
    when(() => repository.setUserPassword(4, any())).thenAnswer(
      (_) async => left(const Failure.forbidden(message: 'لا تملك صلاحية')),
    );
    await cubit.load();

    // Act
    final saved = await cubit.setPassword('كلمة-جديدة');

    // Assert — false, so the sheet stays open with both boxes as they were; and the employee is
    // still there with the reason beside them rather than instead of them.
    expect(saved, isFalse);
    expect(cubit.state.user, employee);
    expect(cubit.state, isA<EmployeeDetailLoaded>().having((s) => s.failure, 'failure', isNotNull));
  });

  test('the new password is sent exactly as typed, spaces and all', () async {
    // Arrange — a space is a character in a password; trimming would store something other than
    // what was typed and confirmed.
    when(() => repository.user(4)).thenAnswer((_) async => right(employee));
    when(() => repository.setUserPassword(4, ' كلمة سر ')).thenAnswer(
      (_) async => right(employee),
    );
    await cubit.load();

    // Act
    final saved = await cubit.setPassword(' كلمة سر ');

    // Assert
    expect(saved, isTrue);
    verify(() => repository.setUserPassword(4, ' كلمة سر ')).called(1);
  });

  // ─────────────────────────── stopping the account ───────────────────────────

  blocTest<EmployeeDetailCubit, EmployeeDetailState>(
    'stopping the account puts back the stopped employee',
    setUp: () {
      // Arrange
      when(() => repository.user(4)).thenAnswer((_) async => right(employee));
      when(() => repository.setUserActivation(4, isActive: false)).thenAnswer(
        (_) async => right(employee.copyWith(isActive: false)),
      );
    },
    build: build,
    // Act
    act: (cubit) async {
      await cubit.load();
      await cubit.setActive(isActive: false);
    },
    // Assert
    expect: () => [
      const EmployeeDetailState.loading(),
      const EmployeeDetailState.loaded(employee),
      const EmployeeDetailState.changing(employee),
      EmployeeDetailState.loaded(employee.copyWith(isActive: false)),
    ],
  );

  test('a second change while one is in flight is ignored rather than queued', () async {
    // Arrange
    when(() => repository.user(4)).thenAnswer((_) async => right(employee));
    when(() => repository.setUserPassword(4, any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 30));

      return right(employee);
    });
    await cubit.load();

    // Act — two taps on «حفظ» in the time one request takes.
    final first = cubit.setPassword('الأولى');
    final second = await cubit.setPassword('الثانية');
    await first;

    // Assert — one request, and the second tap answers false rather than closing the sheet on a
    // save that never happened. Two credentials set in one gesture, in whichever order they
    // landed, is the outcome this guards against.
    expect(second, isFalse);
    verify(() => repository.setUserPassword(4, any())).called(1);
  });
}
