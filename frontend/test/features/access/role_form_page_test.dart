import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/error/failure.dart';
import 'package:printing/core/widgets/app_snackbar.dart';
import 'package:printing/features/access/models/role.dart';
import 'package:printing/features/access/presentation/viewmodel/role_form_cubit.dart';
import 'package:printing/features/access/presentation/views/role_form_page.dart';
import 'package:printing/features/access/repositories/access_repository.dart';
import 'package:printing/features/access/usecases/create_role.dart';
import 'package:printing/features/access/usecases/get_permissions.dart';
import 'package:printing/features/access/usecases/update_role.dart';

/// **A refusal from the server has to end up on the screen.** Every time, on every path.
///
/// The one that prompted this file: the API answered a role form with
/// `422 {"errors": {"name": ["اسم الدور يجب أن يكون أحرفاً إنجليزية صغيرة…"]}}` and the console
/// was the only place it was ever read. A screen that swallows a refusal leaves the user tapping
/// «حفظ» at a form that appears to do nothing.
///
/// So these tests assert the *user-visible* outcome and stay deliberately dumb about how it got
/// there: the text is on screen, wherever the screen chose to put it.
///
/// Arrange - Act - Assert throughout.
class _MockAccessRepository extends Mock implements AccessRepository {}

void main() {
  late _MockAccessRepository repository;

  const catalogue = [
    PermissionGroup(
      title: 'الطلبيات',
      permissions: [PermissionOption(name: 'orders.view', label: 'عرض الطلبيات')],
    ),
  ];

  setUp(() {
    repository = _MockAccessRepository();
    when(() => repository.permissions()).thenAnswer((_) async => const Right(catalogue));

    sl.registerFactory<RoleFormCubit>(
      () => RoleFormCubit(
        getPermissions: GetPermissions(repository),
        createRole: CreateRole(repository),
        updateRole: UpdateRole(repository),
      ),
    );
  });

  tearDown(() => sl.reset());

  /// Takes the toast down before the widget tree is finalised. Its dismiss timer and its
  /// animation outlive the test otherwise, and the framework fails the test for the leak rather
  /// than for anything it was asserting.
  Future<void> clear(WidgetTester tester) async {
    resetSnackBars();
    await tester.pump();
  }

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
        home: RoleFormPage(),
      ),
    );
  }

  /// Fills the name and taps «حفظ».
  Future<void> submit(WidgetTester tester, {String name = 'accountant'}) async {
    await tester.enterText(find.byType(TextFormField).first, name);
    await tester.pumpAndSettle();

    await tester.tap(find.text('إنشاء الدور'));
    await tester.pumpAndSettle();
  }

  testWidgets('a 422 about the name is put on the screen, not only in the console', (tester) async {
    // Arrange — exactly what the API sent: the envelope's own message, plus Laravel's `errors`
    // keyed by field.
    when(
      () => repository.createRole(
        name: any(named: 'name'),
        permissions: any(named: 'permissions'),
      ),
    ).thenAnswer(
      (_) async => const Left(
        ServerFailure(
          message: 'البيانات المدخلة غير صحيحة',
          statusCode: 422,
          fieldErrors: {
            'name': ['اسم الدور يجب أن يكون أحرفاً إنجليزية صغيرة وأرقاماً وشرطات فقط'],
          },
        ),
      ),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await submit(tester);

    // Assert — the server's own sentence, under the box the user has to change.
    expect(
      find.text('اسم الدور يجب أن يكون أحرفاً إنجليزية صغيرة وأرقاماً وشرطات فقط'),
      findsOneWidget,
    );
  });

  testWidgets('a 422 about a field this form has no box for still reaches the user', (
    tester,
  ) async {
    // Arrange — the gap that matters: `fieldErrors` naming something the screen cannot render
    // inline. Nothing was hung under an input and nothing was shown, so the refusal vanished.
    when(
      () => repository.createRole(
        name: any(named: 'name'),
        permissions: any(named: 'permissions'),
      ),
    ).thenAnswer(
      (_) async => const Left(
        ServerFailure(
          message: 'البيانات المدخلة غير صحيحة',
          statusCode: 422,
          fieldErrors: {
            'guard_name': ['الحارس المحدد غير معروف'],
          },
        ),
      ),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await submit(tester);

    // Assert — a snackbar, because there is nowhere else for it to go.
    expect(find.textContaining('الحارس المحدد غير معروف'), findsOneWidget);
    await clear(tester);
  });

  testWidgets('a refusal with no field errors at all is shown too', (tester) async {
    // Arrange — a 409, a 500, a rule that is not about one input.
    when(
      () => repository.createRole(
        name: any(named: 'name'),
        permissions: any(named: 'permissions'),
      ),
    ).thenAnswer(
      (_) async =>
          const Left(ServerFailure(message: 'لا يمكن إنشاء الأدوار الآن', statusCode: 409)),
    );

    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await submit(tester);

    // Assert
    expect(find.textContaining('لا يمكن إنشاء الأدوار الآن'), findsOneWidget);
    await clear(tester);
  });

  testWidgets('the catalogue failing to load says so instead of showing empty sections', (
    tester,
  ) async {
    // Arrange — the catalogue is fetched before anything is typed, and its refusal travels the
    // same road as the form's. Pinned because a form drawing zero permissions and saying nothing
    // looks like a role that may simply grant nothing.
    when(() => repository.permissions()).thenAnswer(
      (_) async => const Left(ServerFailure(message: 'تعذّر جلب الصلاحيات', statusCode: 500)),
    );

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('تعذّر جلب الصلاحيات'), findsOneWidget);
    await clear(tester);
  });
}
