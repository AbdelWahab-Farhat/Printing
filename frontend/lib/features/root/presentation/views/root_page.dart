import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/session/session.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/features/notifications/presentation/widgets/notification_bell.dart';
import 'package:dayaa/features/root/presentation/widgets/root_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// The frame every signed-in screen sits inside: one app bar, one bottom bar, one drawer.
///
/// **Why a shell and not an app bar per screen.** Each screen building its own would mean the
/// bar rebuilding on every navigation — the title sliding, the drawer closing — and four copies
/// of the same widget to keep in step. Here the frame is built once and only the body swaps.
///
/// [StatefulShellRoute.indexedStack] rather than a plain `IndexedStack` behind a counter: each
/// destination keeps its own navigation stack and its own scroll position, so leaving the
/// catalogue half-scrolled and coming back does not send the user to the top of a reloaded page.
class RootPage extends StatelessWidget {
  const RootPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  /// The destinations, in the order they appear in the bar — and in the same order as the
  /// branches in [AppRouter], which is what `navigationShell.currentIndex` indexes into.
  ///
  /// المخزون sits where المنتجات used to: the workshop opens the stock every day and the
  /// catalogue once in a while, so the daily thing gets the bar and the rare thing moved to
  /// the drawer. It is also the one tab that carries a permission — the other three are
  /// readable by every role, so gating them would be rows of `null`.
  static const List<_Destination> _destinations = [
    _Destination(title: 'الرئيسية', label: 'الرئيسية', icon: _IconOf.home),
    _Destination(title: 'قائمة الطلبات', label: 'الطلبات', icon: _IconOf.orders),
    _Destination(
      title: 'المخزن',
      label: 'المخزون',
      icon: _IconOf.warehouse,
      permission: AppPermission.viewInventory,
    ),
    // **Three registers, one tab.** «العملاء» named only the first of them once الموردون and
    // المستثمرون moved out of the drawer and onto this screen — see [PartiesPage].
    _Destination(title: 'الجهات', label: 'الجهات', icon: _IconOf.customers),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _destinations[navigationShell.currentIndex];
    final session = sl<Session>();

    return Scaffold(
      backgroundColor: context.colorScheme.surface,
      appBar: AppBar(
        title: Text(current.title),
        centerTitle: true,
        titleTextStyle: context.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: context.colorScheme.onSurface,
        ),
        backgroundColor: context.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        // The default hamburger is a Material glyph on both platforms; this one follows the
        // device like every other icon in the app.
        leading: Builder(
          builder: (context) => IconButton(
            onPressed: Scaffold.of(context).openDrawer,
            icon: Icon(AppIcons.menu),
            tooltip: 'القائمة',
          ),
        ),
        actions: [
          // Both shells carry the same bell — this one and the investor portal's, which sits
          // outside this shell entirely. See [NotificationBell].
          const NotificationBell(),
          // The workshop-wide ledger — the door [WarehousesPage] hung off its own bar when it
          // lived behind the drawer. The shell owns the bar now, so the shell offers it, and
          // only on the tab it is about.
          if (current.icon == _IconOf.warehouse)
            IconButton(
              tooltip: 'سجل الحركات',
              onPressed: () => context.push(Routes.stockMovements),
              icon: Icon(AppIcons.history),
            ),
        ],
      ),
      drawer: const RootDrawer(),
      body: navigationShell,
      // Rebuilt when the session changes, for the same reason [PermissionGate] listens: a
      // permission set really does change with the tree mounted — pulling to refresh the home
      // screen re-reads `/auth/me`, and so does the healing refresh after a 403.
      bottomNavigationBar: ValueListenableBuilder<int>(
        valueListenable: session.revision,
        builder: (context, _, _) {
          // Gated, not greyed, exactly as the drawer's rows are: a tab whose every screen
          // this account cannot read is a tab to leave out. The branch's own redirect is the
          // boundary; this is the courtesy. The tab the user is *on* always stays, so a grant
          // revoked mid-visit cannot leave the bar pointing at nothing.
          final visible = [
            for (var i = 0; i < _destinations.length; i++)
              if (_destinations[i].permission == null ||
                  session.can(_destinations[i].permission!) ||
                  i == navigationShell.currentIndex)
                i,
          ];

          return NavigationBar(
            selectedIndex: visible.indexOf(navigationShell.currentIndex),
            // `initialLocation: true` only when re-tapping the current tab: that is what pops
            // a destination back to its first screen, while a tap on a different tab restores
            // wherever the user last was inside it.
            onDestinationSelected: (index) => navigationShell.goBranch(
              visible[index],
              initialLocation: visible[index] == navigationShell.currentIndex,
            ),
            backgroundColor: context.colorScheme.surface,
            indicatorColor: context.colorScheme.primaryContainer,
            surfaceTintColor: Colors.transparent,
            height: 72.h,
            destinations: [
              for (final branch in visible)
                NavigationDestination(
                  icon: Icon(_destinations[branch].icon.outlined),
                  selectedIcon: Icon(_destinations[branch].icon.filled),
                  label: _destinations[branch].label,
                ),
            ],
          );
        },
      ),
    );
  }
}

/// One tab: what the bar calls it, what the app bar calls it, and what it looks like.
///
/// Two strings because the two places have different room. "قائمة الطلبات" is the screen's
/// name and reads correctly at the top; in a four-tab bar it would be squeezed to "قائمة…".
class _Destination {
  const _Destination({
    required this.title,
    required this.label,
    required this.icon,
    this.permission,
  });

  final String title;
  final String label;
  final _IconOf icon;

  /// What reading the tab's screen needs, when it needs anything: without the grant the tab
  /// is left out of the bar. Null for the tabs every role may read.
  final AppPermission? permission;
}

/// The two states a bar icon has, resolved per platform through [AppIcons].
///
/// An enum rather than two [IconData] fields on [_Destination], so a destination cannot be
/// declared with a filled icon from one idea and an outline from another.
enum _IconOf {
  home,
  orders,
  warehouse,
  customers;

  IconData get filled => switch (this) {
    _IconOf.home => AppIcons.home,
    _IconOf.orders => AppIcons.orders,
    _IconOf.warehouse => AppIcons.warehouse,
    _IconOf.customers => AppIcons.customers,
  };

  /// Material has a matching outline for each; Cupertino's set is filled-only, so the same
  /// glyph stands in and the selection indicator behind it carries the state.
  IconData get outlined => AppIcons.isCupertino
      ? filled
      : switch (this) {
          _IconOf.home => Icons.home_outlined,
          _IconOf.orders => Icons.receipt_long_outlined,
          _IconOf.warehouse => Icons.inventory_2_outlined,
          _IconOf.customers => Icons.people_alt_outlined,
        };
}
