import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/features/auth/presentation/viewmodel/logout_cubit.dart';
import 'package:printing/features/auth/repositories/auth_repository.dart';
import 'package:printing/features/auth/usecases/logout.dart';
import 'package:printing/features/settings/presentation/viewmodel/settings_cubit.dart';
import 'package:printing/features/settings/presentation/views/settings_page.dart';
import 'package:printing/features/settings/repositories/settings_repository.dart';
import 'package:printing/features/settings/usecases/get_settings.dart';
import 'package:printing/features/settings/usecases/set_notifications_enabled.dart';

/// **A row that responds to a tap has to look like it did.**
///
/// The one that prompted this file: every card on this screen was a `Container` carrying its own
/// background colour, and the two rows inside it are a `SwitchListTile` and a `ListTile`. Those
/// paint their ink splash on the nearest `Material` *ancestor*, so the coloured `Container` sat
/// in front of the splash and swallowed it — the switch still flipped and «تسجيل الخروج» still
/// fired, and both looked like nothing had happened. Flutter reports this shape itself, which is
/// why asserting no error is enough to pin it.
///
/// Arrange - Act - Assert throughout.
class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockSettingsRepository settings;
  late _MockAuthRepository auth;

  setUp(() {
    settings = _MockSettingsRepository();
    auth = _MockAuthRepository();

    when(() => settings.notificationsEnabled).thenReturn(true);
    when(() => settings.setNotificationsEnabled(isEnabled: any(named: 'isEnabled')))
        .thenAnswer((_) async {});
    when(() => auth.logout()).thenAnswer((_) async => const Right(unit));

    sl
      ..registerFactory<SettingsCubit>(
        () => SettingsCubit(
          getSettings: GetSettings(settings),
          setNotificationsEnabled: SetNotificationsEnabled(settings),
        ),
      )
      ..registerFactory<LogoutCubit>(() => LogoutCubit(logout: Logout(auth)))
      // «حول التطبيق» reads the signed-in user straight off the session — a real one, empty,
      // because this file is about how the cards are painted and not about who is looking.
      ..registerSingleton<Session>(Session());
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
        home: SettingsPage(),
      ),
    );
  }

  testWidgets('the rows can show their own ink', (tester) async {
    // Arrange
    await tester.pumpWidget(host());

    // Act
    await tester.pump();

    // Assert — Flutter itself refuses this shape: «ListTile background color or ink splashes may
    // be invisible». Anything it reported would be sitting here waiting to be taken.
    expect(tester.takeException(), isNull);
  });

  testWidgets('each card puts a Material between its colour and its rows', (tester) async {
    // Arrange
    await tester.pumpWidget(host());
    await tester.pump();

    // Act — the switch is the row whose splash was being swallowed.
    final tile = find.byType(SwitchListTile);

    // Assert — the nearest surface above it is a `Material`, which is what a splash needs; a
    // `Container` painting the card's colour in between is the bug this pins.
    expect(tile, findsOneWidget);
    expect(
      find.ancestor(of: tile, matching: find.byType(Material)),
      findsWidgets,
      reason: 'a ListTile with no Material above it has nowhere to paint its ink',
    );
  });
}
