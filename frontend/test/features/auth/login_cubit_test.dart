import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:dayaa/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:dayaa/features/auth/repositories/auth_repository.dart';
import 'package:dayaa/features/auth/usecases/login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The repository is faked, nothing touches Dio or the Keychain, and the assertions are on the
/// sequence of states the screen would have rendered.
///
/// Arrange - Act - Assert throughout.
class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late LoginCubit cubit;

  const user = AuthUser(
    id: 2,
    name: 'موظف',
    phone: '0911000001',
    email: 'staff@printing.ly',
    roles: [UserRole(name: 'staff', label: 'موظف')],
  );

  const session = AuthSession(user: user, token: '13|abcdef');

  setUp(() {
    repository = _MockAuthRepository();
    cubit = LoginCubit(login: Login(repository));
  });

  tearDown(() => cubit.close());

  void arrangeLogin(Either<Failure, AuthSession> result) {
    when(
      () => repository.login(
        phone: any(named: 'phone'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => result);
  }

  // ─────────────────────────── signing in ───────────────────────────

  blocTest<LoginCubit, LoginState>(
    'emits submitting then success when the credentials are accepted',
    setUp: () => arrangeLogin(const Right(session)),
    build: () => cubit,
    act: (cubit) => cubit.submit(phone: '0911000001', password: 'password'),
    expect: () => const [LoginState.submitting(), LoginState.success(session)],
  );

  blocTest<LoginCubit, LoginState>(
    'emits submitting then failure when the server refuses',
    setUp: () => arrangeLogin(
      const Left(
        ServerFailure(
          message: 'البيانات المدخلة غير صحيحة',
          statusCode: 422,
          fieldErrors: {
            'login': ['بيانات الدخول غير صحيحة'],
          },
        ),
      ),
    ),
    build: () => cubit,
    act: (cubit) => cubit.submit(phone: '0911000001', password: 'wrong'),
    expect: () => const [
      LoginState.submitting(),
      LoginState.failure(
        ServerFailure(
          message: 'البيانات المدخلة غير صحيحة',
          statusCode: 422,
          fieldErrors: {
            'login': ['بيانات الدخول غير صحيحة'],
          },
        ),
      ),
    ],
  );

  test('the phone number is trimmed before it reaches the repository', () async {
    // Arrange — a pasted number often carries a trailing space, and the failure it causes is
    // invisible to the person looking at the field.
    arrangeLogin(const Right(session));

    // Act
    await cubit.submit(phone: '  0911000001  ', password: 'password');

    // Assert
    verify(
      () => repository.login(phone: '0911000001', password: 'password'),
    ).called(1);
  });

  test('a second submit while one is in flight is ignored', () async {
    // Arrange — an impatient double tap must not issue two tokens.
    var calls = 0;
    when(
      () => repository.login(phone: any(named: 'phone'), password: any(named: 'password')),
    ).thenAnswer((_) async {
      calls++;
      await Future<void>.delayed(const Duration(milliseconds: 30));

      return const Right(session);
    });

    // Act — deliberately not awaited, so the second call lands mid-flight.
    final first = cubit.submit(phone: '0911000001', password: 'password');
    final second = cubit.submit(phone: '0911000001', password: 'password');
    await Future.wait([first, second]);

    // Assert
    expect(calls, 1);
  });

  // ─────────────────────────── what the screen reads ───────────────────────────

  test('a field error on `login` is offered as the phone field error', () async {
    // Arrange — the API names the field `login` because it also accepts an email; this screen
    // only offers a phone, so the message belongs under the phone input.
    arrangeLogin(
      const Left(
        ServerFailure(
          message: 'البيانات المدخلة غير صحيحة',
          statusCode: 422,
          fieldErrors: {
            'login': ['بيانات الدخول غير صحيحة'],
          },
        ),
      ),
    );

    // Act
    await cubit.submit(phone: '0911000001', password: 'wrong');

    // Assert
    expect(cubit.state.phoneError, 'بيانات الدخول غير صحيحة');
    expect(cubit.state.passwordError, isNull);
  });

  test('a network failure carries no field error, so the screen shows a snackbar', () async {
    // Arrange
    arrangeLogin(const Left(NetworkFailure(message: FailureMessages.noConnection)));

    // Act
    await cubit.submit(phone: '0911000001', password: 'password');

    // Assert
    expect(cubit.state.phoneError, isNull);
    expect(cubit.state.passwordError, isNull);
    expect(cubit.state, isA<LoginFailure>());
  });

  blocTest<LoginCubit, LoginState>(
    'clearFailure returns to initial so the error under a field disappears while typing',
    setUp: () => arrangeLogin(
      const Left(ServerFailure(message: 'خطأ', statusCode: 422)),
    ),
    build: () => cubit,
    act: (cubit) async {
      await cubit.submit(phone: '0911000001', password: 'wrong');
      cubit.clearFailure();
    },
    expect: () => const [
      LoginState.submitting(),
      LoginState.failure(ServerFailure(message: 'خطأ', statusCode: 422)),
      LoginState.initial(),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'clearFailure does nothing when there is no failure to clear',
    build: () => cubit,
    act: (cubit) => cubit.clearFailure(),
    expect: () => const <LoginState>[],
  );
}
