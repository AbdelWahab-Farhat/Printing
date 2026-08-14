import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/network/paginated.dart';
import 'package:dayaa/features/access/presentation/viewmodel/users_cubit.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/access/usecases/get_users.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The staff list. Everything about paging is `PagedCubit`'s and tested there; what is left is
/// that this one asks for the right thing and shows what comes back.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;
  late UsersCubit cubit;

  const admin = AuthUser(
    id: 1,
    name: 'المدير',
    phone: '0910000000',
    employeeCode: '1001',
    roles: [UserRole(name: 'admin', label: 'مدير')],
    isAdmin: true,
  );

  const newcomer = AuthUser(
    id: 9,
    name: 'موظف جديد',
    phone: '0911000009',
    employeeCode: '1009',
  );

  Paginated<AuthUser> pageOf(List<AuthUser> users, {int currentPage = 1, int lastPage = 1}) {
    return Paginated<AuthUser>(
      items: users,
      meta: PageMeta(
        currentPage: currentPage,
        perPage: 20,
        lastPage: lastPage,
        total: users.length,
      ),
    );
  }

  void answerWith(Either<Failure, Paginated<AuthUser>> result, {int? page}) {
    when(
      () => repository.users(
        search: any(named: 'search'),
        page: page ?? any(named: 'page'),
        perPage: any(named: 'perPage'),
      ),
    ).thenAnswer((_) async => result);
  }

  setUp(() {
    repository = _MockAccessRepository();
    cubit = UsersCubit(getUsers: GetUsers(repository));
  });

  tearDown(() async {
    await cubit.close();
  });

  blocTest<UsersCubit, UsersState>(
    'goes loading then loaded when the repository answers',
    setUp: () => answerWith(Right(pageOf([admin, newcomer]))),
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      const UsersState.loading(),
      isA<UsersLoaded>().having((s) => s.page.items, 'items', [admin, newcomer]),
    ],
  );

  blocTest<UsersCubit, UsersState>(
    'surfaces the failure the repository returned, not a generic one',
    setUp: () => answerWith(
      const Left(Failure.forbidden(message: FailureMessages.forbidden)),
    ),
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      const UsersState.loading(),
      const UsersState.failure(Failure.forbidden(message: FailureMessages.forbidden)),
    ],
  );

  blocTest<UsersCubit, UsersState>(
    'an account with no roles is a row like any other, not an error',
    setUp: () => answerWith(Right(pageOf([newcomer]))),
    build: () => cubit,
    act: (cubit) => cubit.load(),
    expect: () => [
      const UsersState.loading(),
      // Empty roles is the most actionable row on the screen — somebody who can sign in and do
      // nothing — so it must arrive as data rather than be filtered out.
      isA<UsersLoaded>().having((s) => s.page.items.single.roles, 'roles', isEmpty),
    ],
  );

  blocTest<UsersCubit, UsersState>(
    'keeps the loaded list when a further page fails',
    setUp: () {
      answerWith(Right(pageOf([admin], lastPage: 2)), page: 1);
      answerWith(
        const Left(Failure.network(message: FailureMessages.noConnection)),
        page: 2,
      );
    },
    build: () => cubit,
    act: (cubit) async {
      await cubit.load();
      await cubit.loadMore();
    },
    skip: 3, // loading, loaded, isLoadingMore: true
    expect: () => [
      isA<UsersLoaded>()
          .having((s) => s.page.items, 'items', [admin])
          .having((s) => s.isLoadingMore, 'isLoadingMore', false),
    ],
  );
}
