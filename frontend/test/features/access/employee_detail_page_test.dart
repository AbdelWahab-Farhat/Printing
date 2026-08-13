import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/features/access/presentation/viewmodel/employee_detail_cubit.dart';
import 'package:printing/features/access/presentation/views/employee_detail_page.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/access/usecases/get_user.dart';
import 'package:printing/features/access/usecases/set_user_activation.dart';
import 'package:printing/features/access/usecases/set_user_password.dart';
import 'package:printing/features/auth/models/auth_user.dart';

/// What the employee screen shows, and — mostly — what it refuses to show.
///
/// **Four different guards meet on this one screen**, which is what makes it worth a widget
/// test rather than a look: `users.manage` for the details and the activation, `users.salary`
/// for the wage *card*, the administrator alone for the password, and «not yourself» for
/// stopping an account. Each is a section or an action that has to be *absent*, and absence is
/// the thing nobody notices has broken.
///
/// The wage has no action of its own — it is a field on the edit form — so what is checked here
/// is only whether the card that displays it is drawn.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;

  const employee = AuthUser(
    id: 4,
    name: 'محمد عز الدين',
    phone: '0944909851',
    employeeCode: 'E4',
    salary: '2500.00',
    roles: [UserRole(name: 'accountant', label: 'محاسب')],
  );

  /// The signed-in reader — never the employee being looked at, unless a test says so.
  AuthUser reader({
    List<AppPermission> permissions = const [],
    bool isAdmin = false,
    int id = 99,
  }) {
    return AuthUser(
      id: id,
      name: 'القارئ',
      phone: '0910000000',
      isAdmin: isAdmin,
      permissions: [for (final permission in permissions) permission.wire],
    );
  }

  void arrange(AuthUser signedIn, {AuthUser shown = employee}) {
    when(() => repository.user(4)).thenAnswer((_) async => Right(shown));

    sl
      ..registerSingleton<Session>(Session()..adopt(signedIn))
      ..registerFactoryParam<EmployeeDetailCubit, int, void>(
        (userId, _) => EmployeeDetailCubit(
          userId: userId,
          getUser: GetUser(repository),
          setPassword: SetUserPassword(repository),
          setActivation: SetUserActivation(repository),
        ),
      );
  }

  setUp(() => repository = _MockAccessRepository());

  tearDown(() => sl.reset());

  /// The app's own frame: ScreenUtil at the reference size, Arabic, RTL.
  Widget host() {
    return ScreenUtilInit(
      designSize: const Size(430, 932),
      builder: (context, _) => const MaterialApp(
        locale: Locale('ar'),
        supportedLocales: [Locale('ar')],
        localizationsDelegates: [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Directionality(
          textDirection: TextDirection.rtl,
          child: EmployeeDetailPage(userId: 4),
        ),
      ),
    );
  }

  // ─────────────────────────── what it says ───────────────────────────

  testWidgets('the employee is on screen once they arrive', (tester) async {
    // Arrange
    arrange(reader(permissions: [AppPermission.viewUsers]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('محمد عز الدين'), findsWidgets);
    expect(find.text('0944909851'), findsOneWidget);
    expect(find.text('محاسب'), findsOneWidget);
  });

  testWidgets('a stopped account says so, loudly and once', (tester) async {
    // Arrange
    arrange(
      reader(permissions: [AppPermission.viewUsers]),
      shown: employee.copyWith(isActive: false),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — the one fact that changes what every action below it means.
    expect(find.text('هذا الحساب موقوف — لا يستطيع تسجيل الدخول'), findsOneWidget);
  });

  testWidgets('a working account carries no band announcing that it works', (tester) async {
    // Arrange
    arrange(reader(permissions: [AppPermission.viewUsers]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — a badge on every screen stops being read, which is the whole reason the stopped
    // one is worth drawing.
    expect(find.textContaining('موقوف'), findsNothing);
  });

  // ─────────────────────────── the wage ───────────────────────────

  testWidgets('the salary is drawn for a reader holding that permission', (tester) async {
    // Arrange
    arrange(
      reader(permissions: [AppPermission.viewUsers, AppPermission.manageUserSalaries]),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — grouped and named in dinars, not the raw '2500.00' the wire carries.
    expect(find.text('الراتب الشهري'), findsOneWidget);
    expect(find.text('2,500 د.ل'), findsOneWidget);
  });

  testWidgets('the whole salary section is absent without it', (tester) async {
    // Arrange — the server sends no `salary` key to this reader at all; drawing an empty card
    // would imply there is a figure they are not being shown.
    arrange(reader(permissions: [AppPermission.viewUsers]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('الراتب الشهري'), findsNothing);
  });

  testWidgets('an employee with no agreed wage says «لم يُحدَّد» rather than zero', (
    tester,
  ) async {
    // Arrange
    arrange(
      reader(permissions: [AppPermission.viewUsers, AppPermission.manageUserSalaries]),
      shown: employee.copyWith(salary: null),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — «0 د.ل» would be a wage of nothing, which is a different claim.
    expect(find.text('لم يُحدَّد'), findsOneWidget);
  });

  // ─────────────────────────── the actions ───────────────────────────

  testWidgets('a reader who may only look is offered nothing to do', (tester) async {
    // Arrange
    arrange(reader(permissions: [AppPermission.viewUsers]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert — every action on this screen is guarded, so an empty dial is not rendered at all.
    expect(find.text('تعديل البيانات'), findsNothing);
    expect(find.text('تغيير كلمة المرور'), findsNothing);
    expect(find.text('إيقاف الحساب'), findsNothing);
  });

  testWidgets('resetting a password is offered to an administrator and to nobody else', (
    tester,
  ) async {
    // Arrange — every permission the catalogue has, and not an administrator. The server guards
    // this one with a gate ability that cannot be ticked onto a role, so no permission can buy
    // it here either.
    arrange(reader(permissions: AppPermission.values));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تغيير كلمة المرور'), findsNothing);
    expect(find.text('تعديل البيانات'), findsOneWidget);
  });

  testWidgets('an administrator is offered it', (tester) async {
    // Arrange
    arrange(reader(permissions: [AppPermission.viewUsers], isAdmin: true));

    // Act — one surviving action is drawn as a plain button rather than a dial, so there is
    // nothing to open.
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تغيير كلمة المرور'), findsOneWidget);
  });

  testWidgets('nobody is offered a way to stop their own account', (tester) async {
    // Arrange — the reader *is* the employee on screen.
    arrange(
      reader(permissions: [AppPermission.viewUsers, AppPermission.manageUsers], id: 4),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Assert — it would revoke the token making the request and lock them out of the screen
    // that undoes it. The server refuses it too; this only spares the tap.
    expect(find.text('إيقاف الحساب'), findsNothing);
    expect(find.text('تعديل البيانات'), findsOneWidget);
  });

  testWidgets('the wage has no action of its own — it is a field on the edit form', (
    tester,
  ) async {
    // Arrange — every permission there is, so nothing is hidden for want of one.
    arrange(reader(permissions: AppPermission.values, isAdmin: true));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Assert — the card that *shows* the wage is on the page; the dial offers «تعديل البيانات»
    // and no separate way to set it.
    expect(find.text('الراتب الشهري'), findsOneWidget);
    expect(find.text('تعديل البيانات'), findsOneWidget);
  });

  testWidgets('stopping somebody else is offered, with the permission to manage users', (
    tester,
  ) async {
    // Arrange
    arrange(reader(permissions: [AppPermission.viewUsers, AppPermission.manageUsers]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('إيقاف الحساب'), findsOneWidget);
  });

  testWidgets('a stopped account is offered the way back on, not the way off', (tester) async {
    // Arrange
    arrange(
      reader(permissions: [AppPermission.viewUsers, AppPermission.manageUsers]),
      shown: employee.copyWith(isActive: false),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('تشغيل الحساب'), findsOneWidget);
    expect(find.text('إيقاف الحساب'), findsNothing);
  });
}
