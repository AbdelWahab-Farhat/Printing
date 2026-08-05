import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/features/settings/presentation/viewmodel/settings_cubit.dart';
import 'package:printing/features/settings/repositories/settings_repository.dart';
import 'package:printing/features/settings/usecases/get_settings.dart';
import 'package:printing/features/settings/usecases/set_notifications_enabled.dart';

/// A preference that has to survive the app being closed — which is the only thing about it
/// worth testing, and the thing a `Switch` alone would not do.
///
/// A fake store rather than a mock: it is three lines, and asserting on what it *holds*
/// afterwards says more than asserting that a method was called.
///
/// Arrange - Act - Assert throughout.
class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository({bool notificationsEnabled = true})
    : _notificationsEnabled = notificationsEnabled;

  bool _notificationsEnabled;
  int writes = 0;

  @override
  bool get notificationsEnabled => _notificationsEnabled;

  @override
  Future<void> setNotificationsEnabled({required bool isEnabled}) async {
    writes++;
    _notificationsEnabled = isEnabled;
  }
}

void main() {
  test('opens showing what the device is actually set to', () {
    // Arrange
    final store = _FakeSettingsRepository(notificationsEnabled: false);

    // Act — no load step: the value is already in memory, so the first frame is correct and the
    // switch never animates from a position the device was not in.
    final cubit = SettingsCubit(
      getSettings: GetSettings(store),
      setNotificationsEnabled: SetNotificationsEnabled(store),
    );

    // Assert
    expect(cubit.state.notificationsEnabled, isFalse);

    cubit.close();
  });

  test('a device that has never been asked gets notifications on', () {
    // Arrange — a shop that misses an order because a default was quietly off has been let
    // down by the app.
    final store = _FakeSettingsRepository();

    // Act
    final cubit = SettingsCubit(
      getSettings: GetSettings(store),
      setNotificationsEnabled: SetNotificationsEnabled(store),
    );

    // Assert
    expect(cubit.state.notificationsEnabled, isTrue);

    cubit.close();
  });

  group('toggling', () {
    late _FakeSettingsRepository store;

    SettingsCubit build() => SettingsCubit(
      getSettings: GetSettings(store),
      setNotificationsEnabled: SetNotificationsEnabled(store),
    );

    setUp(() => store = _FakeSettingsRepository());

    blocTest<SettingsCubit, SettingsState>(
      'turning it off is written down, not just drawn',
      build: build,
      // Act
      act: (cubit) => cubit.toggleNotifications(isEnabled: false),
      // Assert
      expect: () => const [SettingsState(notificationsEnabled: false)],
      verify: (_) => expect(store.notificationsEnabled, isFalse),
    );

    blocTest<SettingsCubit, SettingsState>(
      'setting it to what it already is writes nothing',
      build: build,
      // Act — a rebuild, or a stray tap that lands on the value already showing.
      act: (cubit) => cubit.toggleNotifications(isEnabled: true),
      // Assert
      expect: () => const <SettingsState>[],
      verify: (_) => expect(store.writes, 0),
    );

    blocTest<SettingsCubit, SettingsState>(
      'off then on again ends where it started, with both writes made',
      build: build,
      // Act
      act: (cubit) async {
        await cubit.toggleNotifications(isEnabled: false);
        await cubit.toggleNotifications(isEnabled: true);
      },
      // Assert
      expect: () => const [
        SettingsState(notificationsEnabled: false),
        SettingsState(notificationsEnabled: true),
      ],
      verify: (_) {
        expect(store.notificationsEnabled, isTrue);
        expect(store.writes, 2);
      },
    );
  });
}
