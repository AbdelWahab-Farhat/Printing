import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa_client/core/error/failure.dart';
import 'package:dayaa_client/features/auth/models/customer_account.dart';
import 'package:dayaa_client/features/auth/repositories/auth_repository.dart';
import 'package:dayaa_client/features/auth/usecases/get_current_customer.dart';
import 'package:dayaa_client/features/auth/usecases/has_stored_session.dart';
import 'package:dayaa_client/features/auth/usecases/logout.dart';
import 'package:dayaa_client/features/splash/presentation/viewmodel/splash_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Where the app opens, and — the reason this file exists — where it refuses to open.
///
/// A dropped connection must never read as a dead session: the token is fine, and sending the
/// customer to the login screen asks them for a password to fix something that has nothing to do
/// with their password.
///
/// Arrange - Act - Assert throughout.
class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late SplashCubit cubit;

  const customer = CustomerAccount(id: 1, name: 'متجر النور', phone: '0911111111');

  /// The Cubit waits out a minimum display time before it answers; every test walks past it.
  const past = Duration(milliseconds: 1300);

  SplashCubit build() => SplashCubit(
    hasStoredSession: HasStoredSession(repository),
    getCurrentCustomer: GetCurrentCustomer(repository),
    logout: Logout(repository),
  );

  void arrangeToken({required bool exists}) {
    when(() => repository.hasStoredToken).thenReturn(exists);
  }

  void arrangeCheck(Either<Failure, CustomerAccount> result) {
    when(() => repository.currentCustomer()).thenAnswer((_) async => result);
  }

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.logout()).thenAnswer((_) async => right(unit));
    cubit = build();
  });

  tearDown(() => cubit.close());

  group('the token is good', () {
    blocTest<SplashCubit, SplashState>(
      'opens the app',
      setUp: () {
        // Arrange
        arrangeToken(exists: true);
        arrangeCheck(right(customer));
      },
      build: build,
      // Act
      act: (cubit) => cubit.check(),
      wait: past,
      // Assert
      expect: () => const [SplashState.checking(), SplashState.signedIn()],
    );
  });

  group('there is nothing to check', () {
    blocTest<SplashCubit, SplashState>(
      'goes to the login screen without spending a request',
      setUp: () {
        // Arrange
        arrangeToken(exists: false);
      },
      build: build,
      // Act
      act: (cubit) => cubit.check(),
      wait: past,
      // Assert
      expect: () => const [SplashState.checking(), SplashState.signedOut()],
      verify: (_) => verifyNever(() => repository.currentCustomer()),
    );
  });

  group('the session is genuinely over', () {
    blocTest<SplashCubit, SplashState>(
      'a 401 is the one failure that leads to the login screen',
      setUp: () {
        // Arrange — revoked from another device, or expired. Signing in again is the fix.
        arrangeToken(exists: true);
        arrangeCheck(left(const Failure.unauthorized(message: 'انتهت الجلسة')));
      },
      build: build,
      // Act
      act: (cubit) => cubit.check(),
      wait: past,
      // Assert
      expect: () => const [SplashState.checking(), SplashState.signedOut()],
    );
  });

  group('the server could not be reached', () {
    blocTest<SplashCubit, SplashState>(
      'a dropped connection keeps the session and offers a retry',
      setUp: () {
        // Arrange
        arrangeToken(exists: true);
        arrangeCheck(left(const Failure.network(message: FailureMessages.noConnection)));
      },
      build: build,
      // Act
      act: (cubit) => cubit.check(),
      wait: past,
      // Assert — never `signedOut`: nothing about the token is in question here.
      expect: () => const [
        SplashState.checking(),
        SplashState.unreachable(Failure.network(message: FailureMessages.noConnection)),
      ],
    );

    blocTest<SplashCubit, SplashState>(
      'a server that answered badly is treated the same way',
      setUp: () {
        // Arrange — a 500 is our problem, not the customer's password.
        arrangeToken(exists: true);
        arrangeCheck(left(const Failure.server(message: 'خطأ في الخادم', statusCode: 500)));
      },
      build: build,
      // Act
      act: (cubit) => cubit.check(),
      wait: past,
      // Assert
      expect: () => const [
        SplashState.checking(),
        SplashState.unreachable(Failure.server(message: 'خطأ في الخادم', statusCode: 500)),
      ],
    );

    blocTest<SplashCubit, SplashState>(
      'retrying after the connection returns opens the app',
      setUp: () {
        // Arrange
        arrangeToken(exists: true);
        arrangeCheck(left(const Failure.network(message: FailureMessages.noConnection)));
      },
      build: build,
      // Act — the second attempt is what the button does.
      act: (cubit) async {
        await cubit.check();
        arrangeCheck(right(customer));
        await cubit.check();
      },
      wait: past,
      // Assert
      expect: () => const [
        SplashState.checking(),
        SplashState.unreachable(Failure.network(message: FailureMessages.noConnection)),
        SplashState.checking(),
        SplashState.signedIn(),
      ],
    );

    blocTest<SplashCubit, SplashState>(
      'abandoning clears the token so the next launch does not land here again',
      setUp: () {
        // Arrange — the way out of a retry screen a broken backend would otherwise trap
        // somebody on.
        arrangeToken(exists: true);
        arrangeCheck(left(const Failure.network(message: FailureMessages.noConnection)));
      },
      build: build,
      // Act
      act: (cubit) async {
        await cubit.check();
        await cubit.abandon();
      },
      wait: past,
      // Assert
      expect: () => const [
        SplashState.checking(),
        SplashState.unreachable(Failure.network(message: FailureMessages.noConnection)),
        SplashState.signedOut(),
      ],
      verify: (_) => verify(() => repository.logout()).called(1),
    );
  });
}
