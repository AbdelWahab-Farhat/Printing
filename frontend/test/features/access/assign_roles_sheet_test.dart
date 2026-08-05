import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/widgets/app_button.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/presentation/viewmodel/user_roles_cubit.dart';
import 'package:printing/features/access/presentation/widgets/assign_roles_sheet.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/access/usecases/get_roles.dart';
import 'package:printing/features/access/usecases/sync_user_roles.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// How the roles sheet is put together — the footer in particular.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;

  const roles = [
    Role(id: 1, name: 'admin', label: 'مدير', grantsEverything: true, isSystem: true),
    Role(id: 2, name: 'staff', label: 'موظف', isSystem: true),
  ];

  const user = AuthUser(
    id: 9,
    name: 'موظف',
    phone: '0911000001',
    roles: [UserRole(name: 'staff', label: 'موظف')],
  );

  setUp(() {
    repository = _MockAccessRepository();
    when(() => repository.roles()).thenAnswer((_) async => const Right(roles));

    // Only the one factory the sheet reaches for. The rest of the container is somebody else's
    // test, and registering it here would tie this file to every future dependency.
    sl.registerFactoryParam<UserRolesCubit, int, Set<String>>(
      (userId, initialRoles) => UserRolesCubit(
        userId: userId,
        initialRoles: initialRoles,
        getRoles: GetRoles(repository),
        syncUserRoles: SyncUserRoles(repository),
      ),
    );
  });

  tearDown(() => sl.reset());

  /// The app's own frame: ScreenUtil at the reference size, Arabic, RTL.
  Widget host() {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => MaterialApp(
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: TextButton(
                onPressed: () => showAssignRolesSheet(context: context, user: user),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the save action spans the sheet, not just its own words', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Assert — the sheet's one primary action reads as a bar across the footer, the same as the
    // save button on every form behind it. Shrink-wrapped, it is a chip lost in white space.
    final button = tester.getRect(find.byType(AppButton));
    final sheet = tester.getRect(find.byType(DraggableScrollableSheet));

    expect(button.width, greaterThan(sheet.width * 0.8));
    expect(
      button.center.dx,
      moreOrLessEquals(sheet.center.dx, epsilon: 1),
    );
  });

  testWidgets('the footer stays put while the list scrolls under it', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byType(AppButton));

    // Act — drag the list, not the handle.
    await tester.drag(find.text('مدير'), const Offset(0, -120));
    await tester.pumpAndSettle();

    // Assert
    expect(tester.getRect(find.byType(AppButton)), before);
  });
}
