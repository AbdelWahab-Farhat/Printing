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
/// ## The right-to-left problem this exists to solve, once
///
/// `flutter_speed_dial` lays each child out as `Row([label, button])` with
/// `mainAxisAlignment.start` and `mainAxisSize.max`. Under an Arabic `Directionality` that start
/// becomes the right edge, so the row packs itself against the opposite side from the button the
/// `Scaffold` placed — and the labels walk off the screen. The first build of this showed
/// «تعديل ال…» clipped at the left margin with its buttons nowhere.
///
/// So the dial is given the direction it was written for, and only the label text is turned back
/// around. That pairs with [location], which must be passed to the `Scaffold` — the two are one
/// decision and neither works alone.
class AppSpeedDial extends StatelessWidget {
  const AppSpeedDial({required this.actions, super.key});

  final List<AppAction> actions;

  /// Where a `Scaffold` has to put this.
  ///
  /// `startFloat` is the **right** edge in Arabic, and that is the point: the labels open
  /// inwards from the button, so the button has to be on the side there is room to open into.
  /// A plain FAB elsewhere in the app has no labels and no such constraint, which is why they
  /// are not all the same.
  static const FloatingActionButtonLocation location =
      FloatingActionButtonLocation.startFloat;

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
            if (action.permission == null || session.can(action.permission!)) action,
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
      onPressed: () => unawaited(Future<void>.sync(() => action.onTap(context))),
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

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    // See the class doc: the package's own geometry, with the Arabic put back only where it is
    // read. Removing this puts the labels off the side of the screen.
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
      child: Icon(action.icon),
      backgroundColor: colours.$1,
      foregroundColor: colours.$2,
      // `labelWidget`, not `label`: the dial around it is left-to-right by necessity, and the
      // Arabic inside it must not be.
      labelWidget: Directionality(
        textDirection: TextDirection.rtl,
        child: Material(
          elevation: 3,
          color: context.colorScheme.surface,
          borderRadius: BorderRadius.circular(10.r),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Text(
              action.label,
              style: context.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
      onTap: () => unawaited(Future<void>.sync(() => action.onTap(context))),
    );
  }
}

/// (background, foreground) for a tone.
(Color, Color) _colours(BuildContext context, AppActionTone tone) {
  final scheme = context.colorScheme;

  return switch (tone) {
    AppActionTone.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
    AppActionTone.neutral => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    AppActionTone.warning => (scheme.errorContainer, scheme.onErrorContainer),
  };
}
