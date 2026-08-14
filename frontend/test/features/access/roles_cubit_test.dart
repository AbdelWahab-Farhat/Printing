import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/presentation/viewmodel/roles_cubit.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/access/usecases/delete_role.dart';
import 'package:dayaa/features/access/usecases/get_roles.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The roles screen's ViewModel, with the repository faked and nothing touching Dio.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;
  late RolesCubit cubit;

  const admin = Role(
    id: 1,
    name: 'admin',
    label: 'مدير',
    grantsEverything: true,
    isSystem: true,
    canBeRenamed: false,
    canBeDeleted: false,
    canEditPermissions: false,
    usersCount: 1,
  );

  const accountant = Role(
    id: 3,
    name: 'accountant',
    label: 'محاسب',
    isSystem: false,
    canBeDeleted: true,
    permissions: [PermissionOption(name: 'orders.view', label: 'عرض الطلبيات')],
    usersCount: 0,
  );

  setUp(() {
    repository = _MockAccessRepository();
    cubit = RolesCubit(
      getRoles: GetRoles(repository),
      deleteRole: DeleteRole(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  group('load', () {
    blocTest<RolesCubit, RolesState>(
      'goes loading then loaded when the repository answers',
      setUp: () {
        when(() => repository.roles()).thenAnswer(
          (_) async => const Right([admin, accountant]),
        );
      },
      build: () => cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const RolesState.loading(),
        isA<RolesLoaded>().having((s) => s.roles, 'roles', [admin, accountant]),
      ],
    );

    blocTest<RolesCubit, RolesState>(
      'surfaces the failure the repository returned, not a generic one',
      setUp: () {
        when(() => repository.roles()).thenAnswer(
          (_) async => const Left(Failure.forbidden(message: FailureMessages.forbidden)),
        );
      },
      build: () => cubit,
      act: (cubit) => cubit.load(),
      expect: () => [
        const RolesState.loading(),
        const RolesState.failure(Failure.forbidden(message: FailureMessages.forbidden)),
      ],
    );

    blocTest<RolesCubit, RolesState>(
      'a reload does not blank the list somebody is reading',
      setUp: () {
        // A different answer the second time, so the reload has something to emit at all —
        // otherwise an identical state is dropped and the test would prove nothing.
        var call = 0;
        when(() => repository.roles()).thenAnswer(
          (_) async => call++ == 0 ? const Right([admin]) : const Right([admin, accountant]),
        );
      },
      build: () => cubit,
      act: (cubit) async {
        await cubit.load();
        await cubit.refresh();
      },
      skip: 2, // the first load's loading + loaded
      expect: () => [
        // Straight to loaded again — no `loading` in between, which is what would make the
        // screen flash on every return from the role screen.
        isA<RolesLoaded>().having((s) => s.roles, 'roles', [admin, accountant]),
      ],
    );
  });

  group('delete', () {
    test('marks the row it is deleting, then reloads the list', () async {
      // Arrange
      when(() => repository.roles()).thenAnswer((_) async => const Right([accountant]));
      when(() => repository.deleteRole(3)).thenAnswer((_) async => const Right('تم حذف الدور'));
      await cubit.load();

      final seen = <int?>[];
      final subscription = cubit.stream.listen((state) {
        if (state is RolesLoaded) seen.add(state.deletingId);
      });

      // Act
      final result = await cubit.delete(accountant);
      // A Cubit's stream delivers asynchronously, so cancelling in the same turn as the last
      // `emit` would drop exactly the event this test is about.
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      // Assert — the row is flagged while the request is in flight, and cleared by the reload.
      expect(seen, [3, null]);
      expect(result.isRight(), isTrue);
      verify(() => repository.deleteRole(3)).called(1);
      verify(() => repository.roles()).called(2);
    });

    test("hands back the server's own refusal rather than guessing which it was", () async {
      // Arrange — the API refuses for two different reasons, and its Arabic says which. The app
      // must not translate that into a message of its own.
      const refusal = Failure.server(message: 'لا يمكن حذف دور يحمله موظفون');
      when(() => repository.roles()).thenAnswer((_) async => const Right([accountant]));
      when(() => repository.deleteRole(3)).thenAnswer((_) async => const Left(refusal));
      await cubit.load();

      // Act
      final result = await cubit.delete(accountant);

      // Assert
      expect(result, const Left<Failure, String>(refusal));
      // The list is untouched and the row is no longer marked, so the screen stays usable.
      expect(cubit.state, isA<RolesLoaded>().having((s) => s.deletingId, 'deletingId', isNull));
      expect((cubit.state as RolesLoaded).roles, [accountant]);
    });

    test('a second delete while one is in flight is refused rather than queued', () async {
      // Arrange
      when(() => repository.roles()).thenAnswer((_) async => const Right([accountant]));
      when(() => repository.deleteRole(3)).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));

        return const Right('تم حذف الدور');
      });
      await cubit.load();

      // Act — both started before either finishes.
      final first = cubit.delete(accountant);
      final second = await cubit.delete(accountant);
      await first;

      // Assert — one request went out, not two.
      expect(second.isLeft(), isTrue);
      verify(() => repository.deleteRole(3)).called(1);
    });
  });
}
