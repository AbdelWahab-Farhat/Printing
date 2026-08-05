import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/presentation/viewmodel/role_form_cubit.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/access/usecases/create_role.dart';
import 'package:printing/features/access/usecases/get_permissions.dart';
import 'package:printing/features/access/usecases/update_role.dart';

/// The role form: the catalogue it offers, the ticks it keeps, and what it sends.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;
  late RoleFormCubit cubit;

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

  const created = Role(id: 7, name: 'designer', label: 'designer');

  setUp(() {
    repository = _MockAccessRepository();
    cubit = RoleFormCubit(
      getPermissions: GetPermissions(repository),
      createRole: CreateRole(repository),
      updateRole: UpdateRole(repository),
    );

    when(() => repository.permissions()).thenAnswer((_) async => const Right(catalogue));
  });

  tearDown(() async {
    await cubit.close();
  });

  group('load', () {
    test('creating starts with the catalogue and nothing ticked', () async {
      // Arrange — nothing to seed from.

      // Act
      await cubit.load();

      // Assert
      expect(cubit.state.catalogue, catalogue);
      expect(cubit.state.selected, isEmpty);
      expect(cubit.state.catalogueCount, 3);
    });

    test('editing seeds the ticks from the role, without asking the server again', () async {
      // Arrange — the list that opened this screen already carried the role's permissions.
      const editing = Role(
        id: 3,
        name: 'accountant',
        label: 'محاسب',
        permissions: [
          PermissionOption(name: 'orders.view', label: 'عرض الطلبيات'),
          PermissionOption(name: 'customers.view', label: 'عرض العملاء'),
        ],
      );

      // Act
      await cubit.load(editing: editing);

      // Assert
      expect(cubit.state.selected, {'orders.view', 'customers.view'});
      verifyNever(() => repository.role(any()));
    });

    test('a catalogue that fails leaves the failure on screen, not an empty form', () async {
      // Arrange
      when(() => repository.permissions()).thenAnswer(
        (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
      );

      // Act
      await cubit.load();

      // Assert
      expect(cubit.state.catalogue, isEmpty);
      expect(cubit.state.failure, isNotNull);
      expect(cubit.state.isLoadingCatalogue, isFalse);
    });
  });

  group('ticking', () {
    test('toggle adds then removes one permission', () async {
      // Arrange
      await cubit.load();

      // Act
      cubit.toggle('orders.view');
      final afterAdd = cubit.state.selected;
      cubit.toggle('orders.view');

      // Assert
      expect(afterAdd, {'orders.view'});
      expect(cubit.state.selected, isEmpty);
    });

    test('a partly ticked section fills on one tap, rather than emptying', () async {
      // Arrange — «حالات الطلبيات» alone is ten boxes, and the direction people mean when they
      // reach for a group toggle on a half-filled section is "all of it".
      await cubit.load();
      cubit.toggle('orders.view');

      // Act
      cubit.toggleGroup(catalogue.first);

      // Assert
      expect(cubit.state.selected, {'orders.view', 'orders.manage'});
      expect(cubit.state.isWholeGroupSelected(catalogue.first), isTrue);
    });

    test('a fully ticked section empties on the next tap', () async {
      // Arrange
      await cubit.load();
      cubit.toggleGroup(catalogue.first);

      // Act
      cubit.toggleGroup(catalogue.first);

      // Assert
      expect(cubit.state.selected, isEmpty);
    });

    test('a group toggle leaves other sections alone', () async {
      // Arrange
      await cubit.load();
      cubit.toggle('customers.view');

      // Act
      cubit.toggleGroup(catalogue.first);

      // Assert
      expect(cubit.state.selected, {'customers.view', 'orders.view', 'orders.manage'});
      expect(cubit.state.selectedIn(catalogue.last), 1);
    });
  });

  group('submit', () {
    test('creating sends the ticked names, sorted', () async {
      // Arrange
      when(
        () => repository.createRole(
          name: any(named: 'name'),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => const Right(created));

      await cubit.load();
      cubit.toggle('orders.view');
      cubit.toggle('customers.view');

      // Act
      await cubit.submit(name: 'designer');

      // Assert — sorted, so two identical selections never produce two different request bodies.
      verify(
        () => repository.createRole(
          name: 'designer',
          permissions: ['customers.view', 'orders.view'],
        ),
      ).called(1);
      expect(cubit.state.saved, created);
    });

    test('editing replaces the whole permission set rather than renaming alone', () async {
      // Arrange — sending the set is what makes the request idempotent; omitting it would mean
      // «leave it alone», which is not what this form is asking for.
      when(
        () => repository.updateRole(
          roleId: any(named: 'roleId'),
          name: any(named: 'name'),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => const Right(created));

      await cubit.load();
      cubit.toggle('orders.view');

      // Act
      await cubit.submit(roleId: 3, name: 'accountant');

      // Assert
      verify(
        () => repository.updateRole(
          roleId: 3,
          name: 'accountant',
          permissions: ['orders.view'],
        ),
      ).called(1);
    });

    test('a role that grants nothing is allowed — it sends an empty list', () async {
      // Arrange — «staff» is exactly this, and stripping every permission is a real edit.
      when(
        () => repository.createRole(
          name: any(named: 'name'),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async => const Right(created));

      await cubit.load();

      // Act
      await cubit.submit(name: 'trainee');

      // Assert
      verify(
        () => repository.createRole(name: 'trainee', permissions: const <String>[]),
      ).called(1);
    });

    test('a 422 keeps every tick and puts the message under the name box', () async {
      // Arrange — the form redraws on failure, and losing twenty ticks to a duplicate name
      // would make the second attempt as much work as the first.
      when(
        () => repository.createRole(
          name: any(named: 'name'),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          Failure.server(
            message: 'البيانات المدخلة غير صحيحة',
            fieldErrors: {
              'name': ['اسم الدور مستخدم مسبقاً'],
            },
          ),
        ),
      );

      await cubit.load();
      cubit.toggle('orders.view');
      cubit.toggle('orders.manage');

      // Act
      await cubit.submit(name: 'admin');

      // Assert
      expect(cubit.state.nameError, 'اسم الدور مستخدم مسبقاً');
      expect(cubit.state.selected, {'orders.view', 'orders.manage'});
      expect(cubit.state.saved, isNull);
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('a complaint about the permissions themselves is surfaced separately', () async {
      // Arrange — Laravel keys these `permissions.0`, and they have nowhere better to go than
      // above the sections they are about.
      when(
        () => repository.createRole(
          name: any(named: 'name'),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          Failure.server(
            message: 'البيانات المدخلة غير صحيحة',
            fieldErrors: {
              'permissions.0': ['الصلاحية المحددة غير معروفة في النظام'],
            },
          ),
        ),
      );

      await cubit.load();
      cubit.toggle('orders.view');

      // Act
      await cubit.submit(name: 'designer');

      // Assert
      expect(cubit.state.permissionsError, 'الصلاحية المحددة غير معروفة في النظام');
      expect(cubit.state.nameError, isNull);
    });

    test('a second tap while one submit is in flight sends nothing', () async {
      // Arrange
      when(
        () => repository.createRole(
          name: any(named: 'name'),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));

        return const Right(created);
      });

      await cubit.load();

      // Act
      final first = cubit.submit(name: 'designer');
      await cubit.submit(name: 'designer');
      await first;

      // Assert — one role created, not two.
      verify(
        () => repository.createRole(
          name: any(named: 'name'),
          permissions: any(named: 'permissions'),
        ),
      ).called(1);
    });

    test('correcting the name clears the error under it', () async {
      // Arrange
      when(
        () => repository.createRole(
          name: any(named: 'name'),
          permissions: any(named: 'permissions'),
        ),
      ).thenAnswer(
        (_) async => const Left(
          Failure.server(
            message: 'البيانات المدخلة غير صحيحة',
            fieldErrors: {
              'name': ['اسم الدور مستخدم مسبقاً'],
            },
          ),
        ),
      );

      await cubit.load();
      await cubit.submit(name: 'admin');

      // Act
      cubit.clearFailure();

      // Assert
      expect(cubit.state.nameError, isNull);
    });
  });
}
