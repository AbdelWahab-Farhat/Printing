import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';
import 'package:printing/core/utils/app_icons.dart';
import 'package:printing/core/utils/context_extensions.dart';
import 'package:printing/core/widgets/app_dialog.dart';
import 'package:printing/features/auth/presentation/viewmodel/logout_cubit.dart';

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
  static const List<_Destination> _destinations = [
    _Destination(title: 'الرئيسية', label: 'الرئيسية', icon: _IconOf.home),
    _Destination(title: 'قائمة الطلبات', label: 'الطلبات', icon: _IconOf.orders),
    _Destination(title: 'المنتجات', label: 'المنتجات', icon: _IconOf.products),
    _Destination(title: 'العملاء', label: 'العملاء', icon: _IconOf.customers),
  ];

  @override
  Widget build(BuildContext context) {
    final current = _destinations[navigationShell.currentIndex];

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
      ),
      drawer: const _RootDrawer(),
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        // `initialLocation: true` only when re-tapping the current tab: that is what pops a
        // destination back to its first screen, while a tap on a different tab restores
        // wherever the user last was inside it.
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        backgroundColor: context.colorScheme.surface,
        indicatorColor: context.colorScheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
        height: 72.h,
        destinations: [
          for (final destination in _destinations)
            NavigationDestination(
              icon: Icon(destination.icon.outlined),
              selectedIcon: Icon(destination.icon.filled),
              label: destination.label,
            ),
        ],
      ),
    );
  }
}

/// One tab: what the bar calls it, what the app bar calls it, and what it looks like.
///
/// Two strings because the two places have different room. "قائمة الطلبات" is the screen's
/// name and reads correctly at the top; in a four-tab bar it would be squeezed to "قائمة…".
class _Destination {
  const _Destination({required this.title, required this.label, required this.icon});

  final String title;
  final String label;
  final _IconOf icon;
}

/// The two states a bar icon has, resolved per platform through [AppIcons].
///
/// An enum rather than two [IconData] fields on [_Destination], so a destination cannot be
/// declared with a filled icon from one idea and an outline from another.
enum _IconOf {
  home,
  orders,
  products,
  customers;

  IconData get filled => switch (this) {
    _IconOf.home => AppIcons.home,
    _IconOf.orders => AppIcons.orders,
    _IconOf.products => AppIcons.products,
    _IconOf.customers => AppIcons.customers,
  };

  /// Material has a matching outline for each; Cupertino's set is filled-only, so the same
  /// glyph stands in and the selection indicator behind it carries the state.
  IconData get outlined => AppIcons.isCupertino
      ? filled
      : switch (this) {
          _IconOf.home => Icons.home_outlined,
          _IconOf.orders => Icons.receipt_long_outlined,
          _IconOf.products => Icons.shopping_bag_outlined,
          _IconOf.customers => Icons.people_alt_outlined,
        };
}

/// The sidebar: everything that is not a tab, and the way out.
class _RootDrawer extends StatelessWidget {
  const _RootDrawer();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LogoutCubit>(
      create: (_) => sl<LogoutCubit>(),
      child: const _RootDrawerBody(),
    );
  }
}

class _RootDrawerBody extends StatelessWidget {
  const _RootDrawerBody();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: context.colorScheme.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 16.h),
              child: Row(
                children: [
                  Image.asset('assets/images/logo.png', height: 44.w, width: 44.w),
                  SizedBox(width: 12.w),
                  Text(
                    'PrintX',
                    textDirection: TextDirection.ltr,
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            _DrawerLink(
              icon: AppIcons.warehouse,
              label: 'المخزن',
              onTap: () => context.push(Routes.warehouse),
            ),
            _DrawerLink(
              icon: AppIcons.city,
              label: 'مدن التوصيل',
              onTap: () => context.push(Routes.cities),
            ),
            const Spacer(),
            const Divider(height: 1),
            const _LogoutTile(),
            SizedBox(height: 8.h),
          ],
        ),
      ),
    );
  }
}

class _DrawerLink extends StatelessWidget {
  const _DrawerLink({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: context.colorScheme.onSurfaceVariant),
      title: Text(label),
      onTap: () {
        // Closed first: leaving the drawer open behind the screen it opened means finding it
        // still there on the way back.
        Navigator.of(context).pop();
        onTap();
      },
    );
  }
}

/// The way out, in the error colour, behind a confirmation.
///
/// Signing out is one tap from losing a half-finished screen and needing a password to get back
/// in — cheap to confirm, expensive to do by accident with a thumb.
class _LogoutTile extends StatelessWidget {
  const _LogoutTile();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LogoutCubit, LogoutState>(
      listener: (context, state) {
        if (state is! LogoutSignedOut) return;

        // `go`, not `push`: the session is over, so there must be nothing behind the login
        // screen for the back button to return to.
        context.go(Routes.login);
        // Said the same way whether or not the server was reached, because from here it is the
        // same thing: the token is off this device. `state.failure` records the difference for
        // anyone who needs it, and nobody signing out needs to read about it.
        context.showSuccess('تم تسجيل الخروج');
      },
      builder: (context, state) {
        final isSubmitting = state is LogoutSubmitting;
        final scheme = context.colorScheme;

        return ListTile(
          leading: isSubmitting
              ? SizedBox(
                  height: 22.w,
                  width: 22.w,
                  child: CircularProgressIndicator(strokeWidth: 2.4, color: scheme.error),
                )
              : Icon(AppIcons.logout, color: scheme.error),
          title: Text(
            'تسجيل الخروج',
            style: context.textTheme.bodyLarge?.copyWith(
              color: scheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          onTap: isSubmitting ? null : () => unawaited(_confirmAndSubmit(context)),
        );
      },
    );
  }

  Future<void> _confirmAndSubmit(BuildContext context) async {
    final cubit = context.read<LogoutCubit>();

    final confirmed = await showCustomDialog(
      context: context,
      title: 'تسجيل الخروج',
      description: 'سيتم إنهاء جلستك على هذا الجهاز، وستحتاج إلى إدخال كلمة المرور مرة أخرى.',
      confirmLabel: 'خروج',
      severity: DialogSeverity.warning,
    );

    if (confirmed ?? false) await cubit.submit();
  }
}
