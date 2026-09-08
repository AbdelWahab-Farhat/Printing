import 'package:bloc_test/bloc_test.dart';
import 'package:dayaa/core/push/push_service.dart';
import 'package:dayaa/features/settings/presentation/viewmodel/settings_cubit.dart';
import 'package:dayaa/features/settings/repositories/settings_repository.dart';
import 'package:dayaa/features/settings/usecases/get_settings.dart';
import 'package:dayaa/features/settings/usecases/set_notifications_enabled.dart';
import 'package:flutter_test/flutter_test.dart';

/// A preference that has to survive the app being closed — which is the only thing about it
/// worth testing, and the thing a `Switch` alone would not do.
///
/// A fake store rather than a mock: it is three lines, and asserting on what it *holds*
/// afterwards says more than asserting that a method was called.
///
/// Arrange - Act - Assert throughout.
/// A fake push service, for the same reason as the fake store: what matters is *what it was
/// told to do*, and counting that reads better than verifying a mock.
///
/// The registry and the stored preference are two different facts, and the Cubit is the only
/// thing that keeps them in step outside sign-in and sign-out — so «turning the switch off
/// released the device» is exactly the assertion worth making here.
class _FakePushService implements PushService {
  int registers = 0;
  int releases = 0;

  /// What the phone will claim when asked. False stands for a user who denied the OS prompt.
  bool osAllows = true;

  @override
  Future<bool> register({bool askPermission = true}) async {
    registers++;

    return osAllows;
  }

  @override
  Future<void> release() async => releases++;

  @override
  Future<bool> hasOsPermission() async => osAllows;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
      push: _FakePushService(),
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
      push: _FakePushService(),
    );

    // Assert
    expect(cubit.state.notificationsEnabled, isTrue);

    cubit.close();
  });

  group('toggling', () {
    late _FakeSettingsRepository store;
    late _FakePushService push;

    SettingsCubit build() => SettingsCubit(
      getSettings: GetSettings(store),
      setNotificationsEnabled: SetNotificationsEnabled(store),
      push: push,
    );

    setUp(() {
      store = _FakeSettingsRepository();
      push = _FakePushService();
    });

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

    blocTest<SettingsCubit, SettingsState>(
      'turning it off releases the device rather than only remembering a false',
      build: build,
      // Act
      act: (cubit) => cubit.toggleNotifications(isEnabled: false),
      // Assert — a device left registered would go on being pushed to, and the switch would
      // have changed nothing the user could observe.
      verify: (_) {
        expect(push.releases, 1);
        expect(push.registers, 0);
      },
    );

    blocTest<SettingsCubit, SettingsState>(
      'a phone that refuses shows blocked, and does not flip the stored answer back to off',
      build: build,
      seed: () => const SettingsState(notificationsEnabled: false),
      // Arrange — the user says yes to us and no to the OS prompt.
      act: (cubit) async {
        push.osAllows = false;
        await cubit.toggleNotifications(isEnabled: true);
      },
      // Assert — the preference stays on, because the user's answer to *our* question is still
      // yes and has to survive them granting permission later. The row shows blocked instead.
      verify: (cubit) {
        expect(cubit.state.notificationsEnabled, isTrue);
        expect(cubit.state.osAllows, isFalse);
        expect(cubit.state.isBlockedByOs, isTrue);
        expect(store.notificationsEnabled, isTrue);
      },
    );
  });
}
