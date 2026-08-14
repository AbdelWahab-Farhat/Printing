import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/presentation/viewmodel/role_detail_cubit.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/access/usecases/get_permissions.dart';
import 'package:dayaa/features/access/usecases/get_role.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// The role screen: the role, the catalogue, and the grouping that turns one into the other.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;
  late RoleDetailCubit cubit;

  const catalogue = [
    PermissionGroup(
      title: 'الطلبيات',
      permissions: [
        PermissionOption(name: 'orders.view', label: 'عرض الطلبيات'),
        PermissionOption(name: 'orders.manage', label: 'إضافة وتعديل الطلبيات'),
      ],
    ),
    PermissionGroup(
      title: 'العملاء',
      permissions: [PermissionOption(name: 'customers.view', label: 'عرض العملاء')],
    ),
  ];

  const accountant = Role(
    id: 3,
    name: 'accountant',
    label: 'محاسب',
    permissions: [
      PermissionOption(name: 'orders.view', label: 'عرض الطلبيات'),
      PermissionOption(name: 'customers.view', label: 'عرض العملاء'),
    ],
    usersCount: 2,
  );

  setUp(() {
    repository = _MockAccessRepository();
    cubit = RoleDetailCubit(
      roleId: 3,
      getRole: GetRole(repository),
      getPermissions: GetPermissions(repository),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('loads the role and sorts what it grants into the catalogue\'s sections', () async {
    // Arrange
    when(() => repository.role(3)).thenAnswer((_) async => const Right(accountant));
    when(() => repository.permissions()).thenAnswer((_) async => const Right(catalogue));

    // Act
    await cubit.load();

    // Assert
    final state = cubit.state as RoleDetailLoaded;
    expect(state.role, accountant);
    expect(state.groups.map((g) => g.title), ['الطلبيات', 'العملاء']);
    expect(state.groups.first.names, ['orders.view']);
  });

  test('the administrator loads with no sections — its list really is empty', () async {
    // Arrange — access from a gate rule rather than rows, which the screen reports instead of
    // drawing an empty section list.
    const admin = Role(
      id: 1,
      name: 'admin',
      label: 'مدير',
      grantsEverything: true,
      canEditPermissions: false,
      usersCount: 1,
    );
    when(() => repository.role(3)).thenAnswer((_) async => const Right(admin));
    when(() => repository.permissions()).thenAnswer((_) async => const Right(catalogue));

    // Act
    await cubit.load();

    // Assert
    final state = cubit.state as RoleDetailLoaded;
    expect(state.groups, isEmpty);
    expect(state.role.grantsEverything, isTrue);
  });

  test('a failed role blanks the screen, because there is nothing to show without it', () async {
    // Arrange
    when(() => repository.role(3)).thenAnswer(
      (_) async => const Left(Failure.forbidden(message: FailureMessages.forbidden)),
    );
    when(() => repository.permissions()).thenAnswer((_) async => const Right(catalogue));

    // Act
    await cubit.load();

    // Assert
    expect(cubit.state, isA<RoleDetailFailure>());
  });

  test('a failed catalogue still shows every permission, under one heading', () async {
    // Arrange — the permissions are what the user came for; losing them to protect a
    // subheading would be the wrong trade.
    when(() => repository.role(3)).thenAnswer((_) async => const Right(accountant));
    when(() => repository.permissions()).thenAnswer(
      (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
    );

    // Act
    await cubit.load();

    // Assert
    final state = cubit.state as RoleDetailLoaded;
    expect(state.groups, hasLength(1));
    expect(state.groups.single.title, 'صلاحيات أخرى');
    expect(state.groups.single.names, ['customers.view', 'orders.view']);
  });

  test('a reload does not blank the screen somebody is reading', () async {
    // Arrange
    when(() => repository.role(3)).thenAnswer((_) async => const Right(accountant));
    when(() => repository.permissions()).thenAnswer((_) async => const Right(catalogue));
    await cubit.load();

    final seen = <RoleDetailState>[];
    final subscription = cubit.stream.listen(seen.add);

    // Act — coming back from the edit screen.
    await cubit.refresh();
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    // Assert — no spinner in between.
    expect(seen.whereType<RoleDetailLoading>(), isEmpty);
  });
}
