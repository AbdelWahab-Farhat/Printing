import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/auth/models/auth_user.dart';
import 'package:printing/features/auth/repositories/auth_repository.dart';
import 'package:printing/features/auth/usecases/get_current_user.dart';
import 'package:printing/features/home/models/home_summary.dart';
import 'package:printing/features/home/presentation/viewmodel/home_cubit.dart';
import 'package:printing/features/home/repositories/home_repository.dart';
import 'package:printing/features/home/usecases/get_home_summary.dart';

/// Both contracts are faked, so nothing here touches Dio, the Keychain or a placeholder
/// implementation that will be deleted the day the endpoint lands.
///
/// Arrange - Act - Assert throughout.
class _MockAuthRepository extends Mock implements AuthRepository {}

class _MockHomeRepository extends Mock implements HomeRepository {}

void main() {
  late _MockAuthRepository authRepository;
  late _MockHomeRepository homeRepository;
  late HomeCubit cubit;

  const user = AuthUser(
    id: 2,
    name: 'موظف',
    phone: '0911000001',
    employeeCode: '1002',
  );

  const summary = HomeSummary(
    totalOrders: 9651,
    customersCount: 8041,
    dailyOrders: 5,
    monthlyOrders: 34,
    statuses: [OrderStatusCount(status: 'new', label: 'الجديدة', count: 72)],
  );

  setUp(() {
    authRepository = _MockAuthRepository();
    homeRepository = _MockHomeRepository();
    cubit = HomeCubit(
      getCurrentUser: GetCurrentUser(authRepository),
      getHomeSummary: GetHomeSummary(homeRepository),
    );
  });

  tearDown(() => cubit.close());

  void arrangeUser(Either<Failure, AuthUser> result) {
    when(() => authRepository.currentUser()).thenAnswer((_) async => result);
  }

  void arrangeSummary(Either<Failure, HomeSummary> result) {
    when(() => homeRepository.summary()).thenAnswer((_) async => result);
  }

  group('load', () {
    blocTest<HomeCubit, HomeState>(
      'goes loading then loaded with the employee and the numbers',
      setUp: () {
        // Arrange
        arrangeUser(right(user));
        arrangeSummary(right(summary));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        HomeState.loading(),
        HomeState.loaded(user: user, summary: summary),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'fails when nobody can be named, even though the numbers arrived',
      setUp: () {
        // Arrange
        arrangeUser(left(const Failure.unauthorized(message: 'انتهت الجلسة')));
        arrangeSummary(right(summary));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        HomeState.loading(),
        HomeState.failure(Failure.unauthorized(message: 'انتهت الجلسة')),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      "shows the server's own message rather than a generic one",
      setUp: () {
        // Arrange
        arrangeUser(right(user));
        arrangeSummary(left(const Failure.server(message: 'تعذر جلب الإحصائيات')));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.load(),
      // Assert
      expect: () => const [
        HomeState.loading(),
        HomeState.failure(Failure.server(message: 'تعذر جلب الإحصائيات')),
      ],
    );
  });

  group('refresh', () {
    blocTest<HomeCubit, HomeState>(
      'keeps the numbers on screen while it runs',
      setUp: () {
        // Arrange
        arrangeUser(right(user));
        arrangeSummary(right(summary));
      },
      build: () => cubit,
      // Act
      act: (cubit) async {
        await cubit.load();
        await cubit.refresh();
      },
      // Assert — nothing between the two loads blanks the screen.
      expect: () => const [
        HomeState.loading(),
        HomeState.loaded(user: user, summary: summary),
        HomeState.loaded(user: user, summary: summary, isRefreshing: true),
        HomeState.loaded(user: user, summary: summary),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'a failed refresh leaves the last good screen up',
      setUp: () {
        // Arrange
        arrangeUser(right(user));
        arrangeSummary(right(summary));
      },
      build: () => cubit,
      // Act
      act: (cubit) async {
        await cubit.load();
        arrangeSummary(left(const Failure.network(message: 'لا يوجد اتصال')));
        await cubit.refresh();
      },
      // Assert — it comes back to the numbers it already had, never to an error page.
      expect: () => const [
        HomeState.loading(),
        HomeState.loaded(user: user, summary: summary),
        HomeState.loaded(user: user, summary: summary, isRefreshing: true),
        HomeState.loaded(user: user, summary: summary),
      ],
    );

    blocTest<HomeCubit, HomeState>(
      'refreshing before anything loaded is a first load',
      setUp: () {
        // Arrange
        arrangeUser(right(user));
        arrangeSummary(right(summary));
      },
      build: () => cubit,
      // Act
      act: (cubit) => cubit.refresh(),
      // Assert
      expect: () => const [
        HomeState.loading(),
        HomeState.loaded(user: user, summary: summary),
      ],
    );
  });
}
