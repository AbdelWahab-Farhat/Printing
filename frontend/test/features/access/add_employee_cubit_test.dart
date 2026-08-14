import 'package:dartz/dartz.dart';
import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/features/access/models/role.dart';
import 'package:dayaa/features/access/presentation/viewmodel/add_employee_cubit.dart';
import 'package:dayaa/features/access/repositories/access_repository.dart';
import 'package:dayaa/features/access/usecases/create_user.dart';
import 'package:dayaa/features/access/usecases/get_roles.dart';
import 'package:dayaa/features/auth/models/auth_user.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// Registering a colleague: what is sent, what survives a rejection, and what the roles list
/// failing is allowed to stop.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;
  late AddEmployeeCubit cubit;

  const roles = [
    Role(id: 1, name: 'admin', label: 'مدير', grantsEverything: true, isSystem: true),
    Role(id: 2, name: 'staff', label: 'موظف', isSystem: true),
  ];

  const created = AuthUser(
    id: 9,
    name: 'سالم المبروك',
    phone: '0921234567',
    email: 'salem@printing.ly',
    employeeCode: '1009',
    roles: [UserRole(name: 'staff', label: 'موظف')],
  );

  void answerCreateWith(Either<Failure, AuthUser> result) {
    when(
      () => repository.createUser(
        name: any(named: 'name'),
        email: any(named: 'email'),
        phone: any(named: 'phone'),
        password: any(named: 'password'),
        roleNames: any(named: 'roleNames'),
      ),
    ).thenAnswer((_) async => result);
  }

  Future<void> submitValid() => cubit.submit(
    name: 'سالم المبروك',
    email: 'salem@printing.ly',
    phone: '0921234567',
    password: 'password123',
  );

  setUp(() {
    repository = _MockAccessRepository();
    cubit = AddEmployeeCubit(
      getRoles: GetRoles(repository),
      createUser: CreateUser(repository),
    );

    when(() => repository.roles()).thenAnswer((_) async => const Right(roles));
  });

  tearDown(() async {
    await cubit.close();
  });

  group('the roles to choose from', () {
    test('are loaded, with nothing ticked to start with', () async {
      // Arrange

      // Act
      await cubit.loadRoles();

      // Assert
      expect(cubit.state.roles, roles);
      expect(cubit.state.selectedRoles, isEmpty);
    });

    test('failing to load does not put an error on the form', () async {
      // Arrange — the account is the thing being created, and roles can be set afterwards from
      // the staff list. A dropped connection here must not stop somebody registering the person
      // standing in front of them, nor paint the name box red.
      when(() => repository.roles()).thenAnswer(
        (_) async => const Left(Failure.network(message: FailureMessages.noConnection)),
      );

      // Act
      await cubit.loadRoles();

      // Assert
      expect(cubit.state.roles, isEmpty);
      expect(cubit.state.failure, isNull);
      expect(cubit.state.isLoadingRoles, isFalse);
    });

    test('ticking one sends nothing on its own', () async {
      // Arrange
      await cubit.loadRoles();

      // Act
      cubit.toggleRole('staff');

      // Assert
      expect(cubit.state.selectedRoles, {'staff'});
      verifyNever(
        () => repository.createUser(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          roleNames: any(named: 'roleNames'),
        ),
      );
    });
  });

  group('submit', () {
    test('sends the trimmed fields and the ticked roles, sorted', () async {
      // Arrange
      answerCreateWith(const Right(created));
      await cubit.loadRoles();
      cubit
        ..toggleRole('staff')
        ..toggleRole('admin');

      // Act
      await cubit.submit(
        name: '  سالم المبروك  ',
        email: ' salem@printing.ly ',
        phone: ' 0921234567 ',
        password: 'password123',
      );

      // Assert — trimmed, because a trailing space in an email is a 422 nobody can see; sorted,
      // so two identical selections never produce two different request bodies.
      verify(
        () => repository.createUser(
          name: 'سالم المبروك',
          email: 'salem@printing.ly',
          phone: '0921234567',
          password: 'password123',
          roleNames: ['admin', 'staff'],
        ),
      ).called(1);
      expect(cubit.state.created, created);
    });

    test('an account with no roles is allowed, and sends an empty list', () async {
      // Arrange — it can sign in and do nothing, which is a real thing to create.
      answerCreateWith(const Right(created));
      await cubit.loadRoles();

      // Act
      await submitValid();

      // Assert
      verify(
        () => repository.createUser(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          roleNames: const <String>[],
        ),
      ).called(1);
    });

    test('the password is sent exactly as typed, never trimmed', () async {
      // Arrange — a leading or trailing space is a legitimate character in a password, and
      // silently removing it would create an account nobody can sign into.
      answerCreateWith(const Right(created));

      // Act
      await cubit.submit(
        name: 'سالم',
        email: 'salem@printing.ly',
        phone: '0921234567',
        password: ' pass word 123 ',
      );

      // Assert
      verify(
        () => repository.createUser(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: ' pass word 123 ',
          roleNames: any(named: 'roleNames'),
        ),
      ).called(1);
    });

    test('a 422 marks the field it is about and keeps everything ticked', () async {
      // Arrange — the form redraws on failure, and losing the roles to a duplicate phone would
      // make the second attempt as much work as the first.
      answerCreateWith(
        const Left(
          Failure.server(
            message: 'البيانات المدخلة غير صحيحة',
            fieldErrors: {
              'phone': ['رقم الهاتف مستخدم مسبقاً'],
              'email': ['البريد الإلكتروني مستخدم مسبقاً'],
            },
          ),
        ),
      );
      await cubit.loadRoles();
      cubit.toggleRole('staff');

      // Act
      await submitValid();

      // Assert
      expect(cubit.state.phoneError, 'رقم الهاتف مستخدم مسبقاً');
      expect(cubit.state.emailError, 'البريد الإلكتروني مستخدم مسبقاً');
      expect(cubit.state.nameError, isNull);
      expect(cubit.state.selectedRoles, {'staff'});
      expect(cubit.state.created, isNull);
      expect(cubit.state.isSubmitting, isFalse);
    });

    test('a failure already shown under a box is not repeated as a snackbar', () async {
      // Arrange — `isFieldFailure` is what the screen asks before showing one.
      answerCreateWith(
        const Left(
          Failure.server(
            message: 'البيانات المدخلة غير صحيحة',
            fieldErrors: {
              'name': ['الاسم مطلوب'],
            },
          ),
        ),
      );

      // Act
      await submitValid();

      // Assert
      expect(cubit.state.isFieldFailure, isTrue);
    });

    test('a refusal with no field to blame is left for the snackbar', () async {
      // Arrange — a 403 from somebody who is not an administrator belongs to no input box.
      answerCreateWith(
        const Left(Failure.forbidden(message: FailureMessages.forbidden)),
      );

      // Act
      await submitValid();

      // Assert
      expect(cubit.state.isFieldFailure, isFalse);
      expect(cubit.state.failure, isNotNull);
    });

    test('a complaint about the roles is surfaced separately', () async {
      // Arrange — Laravel keys these `roles.0`, and they belong above the list they are about.
      answerCreateWith(
        const Left(
          Failure.server(
            message: 'البيانات المدخلة غير صحيحة',
            fieldErrors: {
              'roles.0': ['الدور المحدد غير موجود'],
            },
          ),
        ),
      );

      // Act
      await submitValid();

      // Assert
      expect(cubit.state.rolesError, 'الدور المحدد غير موجود');
      expect(cubit.state.nameError, isNull);
    });

    test('a second tap while one submit is in flight creates nothing more', () async {
      // Arrange — email and phone are both unique, so a duplicate POST would be a 422 rather
      // than a second account; but the screen has already moved on by the time either answers.
      when(
        () => repository.createUser(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          roleNames: any(named: 'roleNames'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));

        return const Right(created);
      });

      // Act
      final first = submitValid();
      await submitValid();
      await first;

      // Assert
      verify(
        () => repository.createUser(
          name: any(named: 'name'),
          email: any(named: 'email'),
          phone: any(named: 'phone'),
          password: any(named: 'password'),
          roleNames: any(named: 'roleNames'),
        ),
      ).called(1);
    });

    test('correcting a field clears the error under it', () async {
      // Arrange
      answerCreateWith(
        const Left(
          Failure.server(
            message: 'البيانات المدخلة غير صحيحة',
            fieldErrors: {
              'phone': ['رقم الهاتف مستخدم مسبقاً'],
            },
          ),
        ),
      );
      await submitValid();

      // Act
      cubit.clearFailure();

      // Assert
      expect(cubit.state.phoneError, isNull);
    });
  });
}
