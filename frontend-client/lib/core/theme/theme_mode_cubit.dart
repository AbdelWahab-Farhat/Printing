import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Which appearance the app is wearing.
///
/// **A singleton above the router**, like the basket: the theme is not a property of any screen,
/// and a `BlocProvider` per page would rebuild only that page while the rest of the app kept the
/// old palette until it happened to be rebuilt.
///
/// **It opens on [ThemeMode.system].** A phone that is set to light at noon and dark at night has
/// already been told what its owner wants, and asking them a second time in our settings is the
/// app assuming it is the centre of their day. The choice exists for the people that is wrong
/// for — a dark-mode phone whose owner wants this one app light — and for them it is remembered.
///
/// **Written to `SharedPreferences`, not to the secure store.** Which palette somebody prefers is
/// not a secret; `token_storage.dart` is for the things that are, and putting a theme beside a
/// token is how a store stops being obviously for secrets.
class ThemeModeCubit extends Cubit<ThemeMode> {
  ThemeModeCubit(this._preferences) : super(_restore(_preferences));

  final SharedPreferences _preferences;

  static const String _key = 'theme_mode';

  /// Reads the stored choice, or [ThemeMode.system] when there is none — and also when there is
  /// one this build does not recognise, which is what a downgrade looks like from here.
  static ThemeMode _restore(SharedPreferences preferences) {
    final stored = preferences.getString(_key);

    return ThemeMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  /// Applies [mode] now and remembers it for next launch.
  ///
  /// The write is not awaited by the caller and must not be: the palette changes on this frame,
  /// and a screen that waited for the disk before repainting would flicker for no reason a user
  /// could name. A failed write costs the *next* launch its preference, nothing more.
  Future<void> choose(ThemeMode mode) async {
    if (state == mode) return;

    emit(mode);

    await _preferences.setString(_key, mode.name);
  }
}

/// What each mode is called on screen.
///
/// Here rather than in the widget because the profile screen names them and so does the sheet
/// that changes them, and two lists of three strings drift.
extension ThemeModeLabel on ThemeMode {
  String get label => switch (this) {
    ThemeMode.system => 'حسب النظام',
    ThemeMode.light => 'فاتح',
    ThemeMode.dark => 'داكن',
  };

  /// A line under the label, for the sheet where there is room to explain.
  String get description => switch (this) {
    ThemeMode.system => 'يتبع إعداد هاتفك',
    ThemeMode.light => 'دائماً فاتح',
    ThemeMode.dark => 'دائماً داكن',
  };
}
