import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/presentation/viewmodel/user_roles_cubit.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/access/usecases/get_roles.dart';
import 'package:printing/features/access/usecases/sync_user_roles.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// Assigning roles to one person: what is ticked, when it is sent, and what comes back.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;

  const roles = [
    Role(id: 1, name: 'admin', label: 'مدير', grantsEverything: true, isSystem: true),
    Role(id: 2, name: 'staff', label: 'موظف', isSystem: true),
    Role(id: 3, name: 'accountant', label: 'محاسب', isSystem: true),
  ];

  const saved = AuthUser(
    id: 9,
    name: 'موظف',
    phone: '0911000001',
    roles: [UserRole(name: 'accountant', label: 'محاسب')],
  );

  UserRolesCubit cubitFor(Set<String> initial) => UserRolesCubit(
    userId: 9,
    initialRoles: initial,
    getRoles: GetRoles(repository),
    syncUserRoles: SyncUserRoles(repository),
  );

  setUp(() {
    repository = _MockAccessRepository();
    when(() => repository.roles()).thenAnswer((_) async => const Right(roles));
  });

  test('opens already knowing what the person holds, before any request lands', () {
    // Arrange — the selection came off the row that was tapped, so nothing about it waits.
    final cubit = cubitFor({'staff'});

    // Act
    final selected = cubit.state.selected;

    // Assert
    expect(selected, {'staff'});
    expect(cubit.state.roles, isEmpty);

    addTearDown(cubit.close);
  });

  test('loads the roles there are to choose from without touching the selection', () async {
    // Arrange
    final cubit = cubitFor({'staff'});
    addTearDown(cubit.close);

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state.roles, roles);
    expect(cubit.state.selected, {'staff'});
    expect(cubit.state.isLoadingRoles, isFalse);
  });

  test('ticking sends nothing — three roles are one request, not three', () async {
    // Arrange
    final cubit = cubitFor(const {});
    addTearDown(cubit.close);
    await cubit.load();

    // Act
    cubit
      ..toggle('staff')
      ..toggle('accountant');

    // Assert
    expect(cubit.state.selected, {'staff', 'accountant'});
    verifyNever(() => repository.syncUserRoles(any(), any()));
  });

  test('saving with nothing changed does not spend a request', () async {
    // Arrange — «حفظ» that would send the roles somebody already has has nothing to say.
    final cubit = cubitFor({'staff'});
    addTearDown(cubit.close);
    await cubit.load();

    // Act
    await cubit.save();

    // Assert
    verifyNever(() => repository.syncUserRoles(any(), any()));
  });

  test('saving sends the whole set, sorted, and keeps what the server returned', () async {
    // Arrange — replace, not add/remove: sending the set the user should end up with is what
    // makes the request idempotent.
    when(() => repository.syncUserRoles(any(), any())).thenAnswer(
      (_) async => const Right(saved),
    );

    final cubit = cubitFor({'staff'});
    addTearDown(cubit.close);
    await cubit.load();

    // Act
    cubit
      ..toggle('staff')
      ..toggle('accountant');
    await cubit.save();

    // Assert
    verify(() => repository.syncUserRoles(9, ['accountant'])).called(1);
    expect(cubit.state.saved, saved);
    expect(cubit.state.isSaving, isFalse);
  });

  test('taking every role away is a real edit, sent as an empty list', () async {
    // Arrange
    when(() => repository.syncUserRoles(any(), any())).thenAnswer(
      (_) async => const Right(AuthUser(id: 9, name: 'موظف', phone: '0911000001')),
    );

    final cubit = cubitFor({'staff'});
    addTearDown(cubit.close);
    await cubit.load();

    // Act
    cubit.toggle('staff');
    await cubit.save();

    // Assert
    verify(() => repository.syncUserRoles(9, const <String>[])).called(1);
  });

  test('a failed save keeps the selection it failed to send', () async {
    // Arrange — losing the ticks to a dropped connection would make the retry as much work as
    // the first attempt.
    when(() => repository.syncUserRoles(any(), any())).thenAnswer(
      (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
    );

    final cubit = cubitFor(const {});
    addTearDown(cubit.close);
    await cubit.load();

    // Act
    cubit.toggle('accountant');
    await cubit.save();

    // Assert
    expect(cubit.state.failure, isNotNull);
    expect(cubit.state.selected, {'accountant'});
    expect(cubit.state.saved, isNull);
  });

  test('changing the selection clears the error about the previous attempt', () async {
    // Arrange — an error still on screen while the user changes what they are asking for
    // describes a request nobody made.
    when(() => repository.syncUserRoles(any(), any())).thenAnswer(
      (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
    );

    final cubit = cubitFor(const {});
    addTearDown(cubit.close);
    await cubit.load();
    cubit.toggle('accountant');
    await cubit.save();

    // Act
    cubit.toggle('staff');

    // Assert
    expect(cubit.state.failure, isNull);
  });

  test('hasChangesAgainst sees a swap, not just a count', () async {
    // Arrange — one role out and a different one in leaves the size unchanged, and a length
    // check alone would call that "no change" and disable the save button.
    final cubit = cubitFor({'staff'});
    addTearDown(cubit.close);
    await cubit.load();

    // Act
    cubit
      ..toggle('staff')
      ..toggle('accountant');

    // Assert
    expect(cubit.state.selected, hasLength(1));
    expect(cubit.state.hasChangesAgainst(cubit.initialRoles), isTrue);
  });
}
