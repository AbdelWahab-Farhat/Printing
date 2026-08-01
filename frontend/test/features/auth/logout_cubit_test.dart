import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/auth/presentation/viewmodel/logout_cubit.dart';
import 'package:printing/features/auth/repositories/auth_repository.dart';
import 'package:printing/features/auth/usecases/logout.dart';

/// Signing out has one outcome, and these tests exist to keep it that way.
///
/// Arrange - Act - Assert throughout.
class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late LogoutCubit cubit;

  setUp(() {
    repository = _MockAuthRepository();
    cubit = LogoutCubit(logout: Logout(repository));
  });

  tearDown(() => cubit.close());

  void arrangeLogout(Either<Failure, Unit> result) {
    when(() => repository.logout()).thenAnswer((_) async => result);
  }

  blocTest<LogoutCubit, LogoutState>(
    'goes submitting then signed out',
    setUp: () {
      // Arrange
      arrangeLogout(right(unit));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.submit(),
    // Assert
    expect: () => const [LogoutState.submitting(), LogoutState.signedOut()],
  );

  blocTest<LogoutCubit, LogoutState>(
    'signs out on this device even when the server was never reached',
    setUp: () {
      // Arrange
      arrangeLogout(left(const Failure.network(message: 'لا يوجد اتصال')));
    },
    build: () => cubit,
    // Act
    act: (cubit) => cubit.submit(),
    // Assert — signed out all the same. The failure rides along for anyone who wants to say so,
    // and is never a reason to leave a shared phone signed in.
    expect: () => const [
      LogoutState.submitting(),
      LogoutState.signedOut(failure: Failure.network(message: 'لا يوجد اتصال')),
    ],
  );

  blocTest<LogoutCubit, LogoutState>(
    'a second tap while the first is in flight is ignored',
    setUp: () {
      // Arrange
      arrangeLogout(right(unit));
    },
    build: () => cubit,
    // Act — two taps, no await between them.
    act: (cubit) async {
      final first = cubit.submit();
      final second = cubit.submit();
      await Future.wait([first, second]);
    },
    // Assert — one round trip, one navigation.
    expect: () => const [LogoutState.submitting(), LogoutState.signedOut()],
    verify: (_) => verify(() => repository.logout()).called(1),
  );
}
