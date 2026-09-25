import 'package:dayaa_client/core/theme/theme_mode_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which appearance the app opens in, and whether it remembers.
///
/// **The default is the whole feature for most people.** A phone already knows whether its owner
/// wants light or dark; opening on [ThemeMode.system] is the app not asking a question that has
/// been answered. The stored choice exists for the people that is wrong for, and for them the
/// thing that must not break is that it survives a launch.
///
/// Arrange - Act - Assert throughout.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<SharedPreferences> preferences([Map<String, Object> initial = const {}]) async {
    SharedPreferences.setMockInitialValues(initial);

    return SharedPreferences.getInstance();
  }

  test('a phone that has never been asked follows itself', () async {
    // Arrange
    final prefs = await preferences();

    // Act
    final cubit = ThemeModeCubit(prefs);

    // Assert
    expect(cubit.state, ThemeMode.system);
  });

  test('a stored choice is what the app opens in', () async {
    // Arrange — the disk as the previous launch left it.
    final prefs = await preferences({'theme_mode': 'light'});

    // Act
    final cubit = ThemeModeCubit(prefs);

    // Assert
    expect(cubit.state, ThemeMode.light);
  });

  test('choosing applies now and is written for next time', () async {
    // Arrange
    final prefs = await preferences();
    final cubit = ThemeModeCubit(prefs);

    // Act
    await cubit.choose(ThemeMode.dark);

    // Assert — the app is dark, and a fresh cubit on the same disk agrees.
    expect(cubit.state, ThemeMode.dark);
    expect(prefs.getString('theme_mode'), 'dark');
    expect(ThemeModeCubit(prefs).state, ThemeMode.dark);
  });

  test('choosing what is already chosen emits nothing', () async {
    // Arrange
    final prefs = await preferences();
    final cubit = ThemeModeCubit(prefs);
    final seen = <ThemeMode>[];
    final subscription = cubit.stream.listen(seen.add);

    // Act
    await cubit.choose(ThemeMode.system);

    // Assert — a rebuild of the entire app is not free, and nothing changed.
    await subscription.cancel();
    expect(seen, isEmpty);
  });

  test('a value this build does not know falls back rather than throwing', () async {
    // Arrange — what a downgrade looks like from here: a mode written by a later build.
    final prefs = await preferences({'theme_mode': 'sepia'});

    // Act
    final cubit = ThemeModeCubit(prefs);

    // Assert — `firstWhere` without an `orElse` would have thrown on launch, before any screen.
    expect(cubit.state, ThemeMode.system);
  });

  test('every mode has a label and a line of its own', () {
    // Arrange - Act
    final labels = ThemeMode.values.map((mode) => mode.label).toSet();
    final descriptions = ThemeMode.values.map((mode) => mode.description).toSet();

    // Assert — the sheet draws all three at once; two sharing a label is a sheet nobody can use.
    expect(labels, hasLength(ThemeMode.values.length));
    expect(descriptions, hasLength(ThemeMode.values.length));
  });
}
