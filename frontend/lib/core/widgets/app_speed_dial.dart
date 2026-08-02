import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/permissions/app_permission.dart';
import 'package:printing/core/session/session.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';

/// How loudly one action should read.
///
/// A tone, not a colour: the screen says what an action *means* and this file decides what that
/// looks like, so a warning is the same warning everywhere.
enum AppActionTone {
  /// The thing the screen exists for.
  primary,

  /// A supporting action.
  neutral,

  /// Takes something away. Reversible — nothing in this app deletes.
  warning,
}

/// One thing a screen's floating button can do.
///
/// A plain object so a screen declares its actions as *data* — including navigation, which is
/// just what [onTap] happens to do — instead of assembling a widget tree per screen.
///
/// ```dart
/// AppAction(
///   label: 'تعديل العميل',
///   icon: AppIcons.edit,
///   permission: AppPermission.manageCustomers,
///   onTap: (context) => context.push(Routes.editCustomer(id)),
/// )
/// ```
class AppAction {
  const AppAction({
    required this.label,
    required this.icon,
    required this.onTap,
    this.permission,
    this.tone = AppActionTone.neutral,
  });

  final String label;
  final IconData icon;

  /// Given the context so it can navigate, open a sheet, or ask a Cubit. May be async; the dial
  /// does not wait on it, because the dial closes the moment it is tapped.
  final FutureOr<void> Function(BuildContext context) onTap;

  /// Hidden unless the signed-in person holds this. Null means always shown.
  ///
  /// **A courtesy, never a boundary** — the server refuses the request regardless. Hiding it
  /// spares somebody work they cannot finish.
  final AppPermission? permission;

  final AppActionTone tone;
}

/// The app's floating button: one action, or a dial that opens into several.
///
/// A screen hands it a list and nothing else. That list is filtered by permission here, so no
/// screen writes its own `can(...)` check around a button, and:
///
///   * **nothing survives** → nothing is rendered. An empty dial is furniture.
///   * **exactly one** survives → a plain extended button carrying that action's label. A dial
///     that opens to reveal a single choice is a tax on every use of it, and this happens for
///     real: a staff account with `customers.view` and nothing else sees one action here.
///   * **more than one** → the dial.
///
/// ## The right-to-left problem, and how it stopped being one
///
/// `flutter_speed_dial` lays a child out as `Row([label, button])` with
/// `mainAxisAlignment.start`. Under an Arabic `Directionality` that start is the right edge, so
/// the row packs against the opposite side from the button the `Scaffold` placed and the labels
/// walk off screen — this shipped once showing «تعديل ال…» clipped at the margin.
///
/// The fix is three things that only work together: the dial is given the direction it was
/// written for, `switchLabelPosition` puts each label on the side there is room on, and
/// [location] pins the button to the edge that leaves that room. Undo any one and the labels
/// leave the screen.
///
/// The package's own `label` slot is not used at all, and that is the fix rather than a
/// preference: it renders inside the `Scaffold`'s floating-button slot, which is 56 wide, so
/// «تعديل العميل» came out squeezed to 26 pixels and painted over its own icon. Each action is
/// one pill instead — icon and name inside the child button — whose width this file measures
/// from the longest name in the dial.
class AppSpeedDial extends StatelessWidget {
  const AppSpeedDial({required this.actions, super.key});

  final List<AppAction> actions;

  /// Where a `Scaffold` has to put this.
  ///
  /// The trailing edge — the bottom **left** in Arabic, where every other floating button in
  /// this app already sits. It is a constant rather than each screen's own choice because it is
  /// one decision with `switchLabelPosition` in [_Dial]: measured on a 430-wide phone, this
  /// pairing puts the whole dial inside 40–276, while the other side pushes the buttons out to
  /// 618 and off the screen.
  static const FloatingActionButtonLocation location =
      FloatingActionButtonLocation.endFloat;

  @override
  Widget build(BuildContext context) {
    final session = sl<Session>();

    return ValueListenableBuilder<int>(
      // A permission set really does change with the tree mounted — every pull-to-refresh
      // re-reads it — and a dial that kept an action the server has since withdrawn would
      // offer work that ends in a 403.
      valueListenable: session.revision,
      builder: (context, _, _) {
        final allowed = [
          for (final action in actions)
            if (action.permission == null || session.can(action.permission!))
              action,
        ];

        if (allowed.isEmpty) return const SizedBox.shrink();
        if (allowed.length == 1) return _Single(action: allowed.single);

        return _Dial(actions: allowed);
      },
    );
  }
}

class _Single extends StatelessWidget {
  const _Single({required this.action});

  final AppAction action;

  @override
  Widget build(BuildContext context) {
    final colours = _colours(context, action.tone);

    return FloatingActionButton.extended(
      onPressed: () =>
          unawaited(Future<void>.sync(() => action.onTap(context))),
      backgroundColor: colours.$1,
      foregroundColor: colours.$2,
      icon: Icon(action.icon),
      label: Text(action.label),
    );
  }
}

class _Dial extends StatelessWidget {
  const _Dial({required this.actions});

  final List<AppAction> actions;

  /// How wide one pill has to be for the longest name in this dial.
  ///
  /// Measured rather than guessed: `childrenButtonSize` is a single size for every child, so a
  /// fixed number either floats «التصاميم» in empty space or cuts «تسجيل راجع لدى المندوب».
  /// Capped so a very long name shortens instead of hanging off the screen.
  double _pillWidth(BuildContext context) {
    final style = context.textTheme.labelLarge?.copyWith(
      fontWeight: FontWeight.w700,
    );
    var widest = 0.0;

    for (final action in actions) {
      final painter = TextPainter(
        text: TextSpan(text: action.label, style: style),
        textDirection: TextDirection.rtl,
      )..layout();

      widest = widest > painter.width ? widest : painter.width;
    }

    // icon + gap + text + the padding on both ends.
    final needed = 20.sp + 10.w + widest + 32.w;
    final ceiling = MediaQuery.sizeOf(context).width - 48.w;

    return needed > ceiling ? ceiling : needed;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // See the class doc: the package's own geometry, with the Arabic put back only where it is
    // read. Removing this puts the children off the side of the screen.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: SpeedDial(
        icon: AppIcons.more,
        activeIcon: AppIcons.close,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        overlayColor: scheme.scrim,
        overlayOpacity: 0.4,
        spacing: 12,
        spaceBetweenChildren: 10,
        // Start-aligns the children column. A pill is far wider than the 56 the main button is,
        // and centred on it, it hangs 54 pixels off the left edge — measured, not guessed.
        switchLabelPosition: true,
        childrenButtonSize: Size(_pillWidth(context), 52.h),
        children: [
          // Reversed so the first action a screen declares ends up nearest the thumb. A list
          // reads top-down; a dial opens bottom-up.
          for (final action in actions.reversed) _childOf(context, action),
        ],
      ),
    );
  }

  SpeedDialChild _childOf(BuildContext context, AppAction action) {
    final colours = _colours(context, action.tone);

    return SpeedDialChild(
      // The icon and its name in **one** pill. They used to be a coloured square and a separate
      // white card beside it, which reads as two stickers stuck together rather than as one
      // thing to press — and only half of it looked pressable.
      child: Directionality(
        // The dial around this is left-to-right out of necessity; the Arabic inside it is not.
        textDirection: TextDirection.rtl,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, size: 20.sp),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(
                action.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
      shape: const StadiumBorder(),
      backgroundColor: colours.$1,
      foregroundColor: colours.$2,
      onTap: () => unawaited(Future<void>.sync(() => action.onTap(context))),
    );
  }
}

/// (background, foreground) for a tone.
(Color, Color) _colours(BuildContext context, AppActionTone tone) {
  final scheme = context.colorScheme;

  return switch (tone) {
    AppActionTone.primary => (
      scheme.primaryContainer,
      scheme.onPrimaryContainer,
    ),
    AppActionTone.neutral => (
      scheme.secondaryContainer,
      scheme.onSecondaryContainer,
    ),
    AppActionTone.warning => (scheme.errorContainer, scheme.onErrorContainer),
  };
}
