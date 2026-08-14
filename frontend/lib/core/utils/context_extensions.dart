import 'package:dayaa/core/error/failure.dart';
import 'package:dayaa/core/widgets/app_snackbar.dart';
import 'package:flutter/material.dart';

/// Shortcuts onto `Theme.of(this)` and friends.
///
/// `context.colorScheme.primary` instead of `Theme.of(context).colorScheme.primary` — the same
/// lookup, but short enough that nobody is tempted to reach for a hard-coded `Color(0xff…)`
/// because the proper way was too long to type.
extension ContextX on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Size get screenSize => MediaQuery.sizeOf(this);

  /// The keyboard's height — 0 when it is closed.
  double get keyboardInset => MediaQuery.viewInsetsOf(this).bottom;

  bool get isKeyboardOpen => keyboardInset > 0;
}

/// Showing the result of something that failed or succeeded, from anywhere with a context.
extension FeedbackX on BuildContext {
  void showSuccess(String message, {String? details}) => unawaitedSnack(
    context: this,
    title: message,
    subtitle: details,
    type: SnackType.success,
  );

  void showError(String message, {String? details}) => unawaitedSnack(
    context: this,
    title: message,
    subtitle: details,
    type: SnackType.error,
  );

  void showInfo(String message, {String? details}) =>
      unawaitedSnack(context: this, title: message, subtitle: details);

  /// Renders a [Failure] with the right tone: a dropped connection is a warning the user can
  /// act on by retrying, while a refusal from the server is an error.
  ///
  /// **A 422 brings its field messages with it.** Laravel's envelope says «البيانات المدخلة غير
  /// صحيحة» — which tells the user only that *something* is wrong — and puts the sentence they
  /// can actually act on in `errors`. A screen with a box to hang that under should do so and
  /// never reach for this; a screen without one used to drop it on the floor, so the only place
  /// «اسم الدور يجب أن يكون أحرفاً إنجليزية صغيرة» was ever read was the debug console.
  void showFailure(Failure failure) => unawaitedSnack(
    context: this,
    title: failure.message,
    subtitle: failure.details,
    type: failure.isNetwork ? SnackType.warning : SnackType.error,
  );
}

/// `showCustomSnackBar` is async so it can await its own exit animation; callers never care.
/// Wrapping it once here keeps `unawaited_futures` satisfied without an ignore at every site.
void unawaitedSnack({
  required BuildContext context,
  required String title,
  String? subtitle,
  SnackType type = SnackType.info,
}) {
  showCustomSnackBar(context: context, title: title, subtitle: subtitle, type: type)
      .ignore();
}
