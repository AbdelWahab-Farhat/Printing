import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/presentation/viewmodel/login_cubit.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/login.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late Login login;

  const account = CustomerAccount(id: 1, name: 'متجر النور', phone: '0911111111');
  const session = AuthSession(customer: account, token: 'tok');

  setUp(() {
    repository = _MockAuthRepository();
    login = Login(repository);
  });

  group('submit', () {
    blocTest<LoginCubit, LoginState>(
      'emits submitting then success when the server accepts the credentials',
      build: () {
        when(
          () => repository.login(phone: any(named: 'phone'), password: any(named: 'password')),
        ).thenAnswer((_) async => const Right(session));

        return LoginCubit(login: login);
      },
      act: (cubit) => cubit.submit(phone: '0911111111', password: 'password123'),
      expect: () => const [LoginState.submitting(), LoginState.success(session)],
    );

    blocTest<LoginCubit, LoginState>(
      'emits submitting then failure when it does not',
      build: () {
        when(
          () => repository.login(phone: any(named: 'phone'), password: any(named: 'password')),
        ).thenAnswer((_) async => const Left(ServerFailure(message: 'خطأ')));

        return LoginCubit(login: login);
      },
      act: (cubit) => cubit.submit(phone: '0911111111', password: 'wrong'),
      expect: () => const [
        LoginState.submitting(),
        LoginState.failure(ServerFailure(message: 'خطأ')),
      ],
    );

    /// A second tap while the first request is in flight would issue a second token and, on a
    /// slow connection, race the navigation that follows.
    blocTest<LoginCubit, LoginState>(
      'ignores a second tap while a request is in flight',
      build: () {
        when(
          () => repository.login(phone: any(named: 'phone'), password: any(named: 'password')),
        ).thenAnswer((_) async {
          await Future<void>.delayed(const Duration(milliseconds: 20));

          return const Right(session);
        });

        return LoginCubit(login: login);
      },
      act: (cubit) {
        cubit
          ..submit(phone: '0911111111', password: 'password123')
          ..submit(phone: '0911111111', password: 'password123');
      },
      wait: const Duration(milliseconds: 60),
      expect: () => const [LoginState.submitting(), LoginState.success(session)],
      verify: (_) {
        verify(
          () => repository.login(phone: any(named: 'phone'), password: any(named: 'password')),
        ).called(1);
      },
    );

    /// A trailing space pasted into the phone field is a failed sign-in whose cause the customer
    /// cannot see, so the use case trims it before anything else does.
    test('the use case trims the phone before it reaches the repository', () async {
      when(
        () => repository.login(phone: any(named: 'phone'), password: any(named: 'password')),
      ).thenAnswer((_) async => const Right(session));

      await login(phone: '  0911111111 ', password: 'password123');

      verify(() => repository.login(phone: '0911111111', password: 'password123')).called(1);
    });
  });

  group('field errors', () {
    /// **The key is `phone`, not `login`.** The staff endpoint accepts an email or a phone and
    /// reports against a field called `login`; the customer endpoint has one identifier and
    /// names it plainly, so there is nothing to translate.
    test('a server complaint about the phone lands under the phone field', () {
      const state = LoginState.failure(
        ServerFailure(
          message: 'البيانات المدخلة غير صحيحة',
          fieldErrors: {'phone': ['رقم الهاتف أو كلمة المرور غير صحيحة']},
        ),
      );

      expect(state.phoneError, 'رقم الهاتف أو كلمة المرور غير صحيحة');
      expect(state.passwordError, isNull);
    });

    /// A deactivated account answers 403 with a message and no field, so the screen shows it in
    /// a snackbar rather than hanging it under an input the customer cannot correct.
    test('a failure with no field errors leaves both fields clean', () {
      const state = LoginState.failure(ServerFailure(message: 'حسابك موقوف حالياً'));

      expect(state.phoneError, isNull);
      expect(state.passwordError, isNull);
    });
  });

  blocTest<LoginCubit, LoginState>(
    'clearFailure returns to initial so the error under a field disappears as it is corrected',
    build: () => LoginCubit(login: login),
    seed: () => const LoginState.failure(ServerFailure(message: 'خطأ')),
    act: (cubit) => cubit.clearFailure(),
    expect: () => const [LoginState.initial()],
  );
}
