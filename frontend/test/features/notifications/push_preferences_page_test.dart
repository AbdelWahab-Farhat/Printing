import 'package:dartz/dartz.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/features/notifications/models/push_preference.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/push_preferences_cubit.dart';
import 'package:dayaa/features/notifications/presentation/views/push_preferences_page.dart';
import 'package:dayaa/features/notifications/repositories/notifications_repository.dart';
import 'package:dayaa/features/notifications/usecases/get_push_preferences.dart';
import 'package:dayaa/features/notifications/usecases/set_push_preference.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

/// «إشعارات الهاتف» — what an administrator sees for one employee.
///
/// Arrange - Act - Assert throughout.
class _MockRepository extends Mock implements NotificationsRepository {}

void main() {
  late _MockRepository repository;

  const groups = [
    PushPreferenceGroup(
      type: 'order.shortage',
      label: 'نواقص طلبية',
      icon: 'warning',
      switches: [PushSwitch(scope: '', label: 'نواقص طلبية', push: true)],
    ),
    PushPreferenceGroup(
      type: 'order.status',
      label: 'حالة طلبية',
      icon: 'order',
      switches: [
        PushSwitch(scope: 'ready', label: 'جاهزة', push: true),
        PushSwitch(scope: 'settled', label: 'تم التسوية', push: false),
      ],
    ),
  ];

  setUp(() {
    repository = _MockRepository();
    sl.registerFactoryParam<PushPreferencesCubit, int, void>(
      (userId, _) => PushPreferencesCubit(
        userId: userId,
        getPreferences: GetPushPreferences(repository),
        setPreference: SetPushPreference(repository),
      ),
    );
  });

  tearDown(() => sl.reset());

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
          child: PushPreferencesPage(userId: 4, employeeName: 'محمد'),
        ),
      ),
    );
  }

  bool switchValue(WidgetTester tester, String key) =>
      tester.widget<SwitchListTile>(find.byKey(ValueKey(key))).value;

  testWidgets('one row for a single type, a row per status under order status', (tester) async {
    // Arrange
    when(() => repository.pushPreferences(4)).thenAnswer((_) async => const Right(groups));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('محمد'), findsOneWidget);
    expect(find.text('حالة طلبية'), findsOneWidget);
    expect(switchValue(tester, 'push-order.shortage'), isTrue);
    expect(switchValue(tester, 'push-order.status-ready'), isTrue);
    expect(switchValue(tester, 'push-order.status-settled'), isFalse);
  });

  testWidgets('tapping a status switch turns that status off', (tester) async {
    // Arrange
    when(() => repository.pushPreferences(4)).thenAnswer((_) async => const Right(groups));
    when(
      () => repository.setPushPreference(
        userId: 4,
        type: 'order.status',
        scope: 'ready',
        push: false,
      ),
    ).thenAnswer((_) async => const Right(groups));
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Act
    await tester.tap(find.byKey(const ValueKey('push-order.status-ready')));
    await tester.pumpAndSettle();

    // Assert
    expect(switchValue(tester, 'push-order.status-ready'), isFalse);
    verify(
      () => repository.setPushPreference(
        userId: 4,
        type: 'order.status',
        scope: 'ready',
        push: false,
      ),
    ).called(1);
  });

  testWidgets('an employee with no group notifications is told so', (tester) async {
    // Arrange
    when(() => repository.pushPreferences(4)).thenAnswer((_) async => const Right([]));

    // Act
    await tester.pumpWidget(host());
    await tester.pumpAndSettle();

    // Assert
    expect(find.textContaining('لا تصل هذا الموظف'), findsOneWidget);
  });
}
