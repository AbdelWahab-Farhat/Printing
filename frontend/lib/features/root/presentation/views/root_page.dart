import 'package:dayaa/core/permissions/app_permission.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/core/utils/app_icons.dart';
import 'package:dayaa/core/utils/context_extensions.dart';
import 'package:dayaa/core/widgets/permission_gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

/// Whether معدلات تكلفة التصنيع appears in the drawer.
///
/// **Hidden, not removed.** The screen, its route, its permissions, its repository and its
/// tests are all still here and still passing — this drawer row is the only door to them, so
/// closing the door is the whole change. Flip this to `true` to reopen it.
///
/// A flag rather than a deleted block: the code stays compiled and covered, so it cannot rot
/// quietly while it is out of sight, and coming back is one word rather than an archaeology
/// exercise in the history.
const bool _showManufacturingCostRates = false;

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

/// The sidebar: everything that is not a tab.
///
/// Signing out used to live at the bottom of this panel. It moved into الإعدادات with the rest
/// of the account, because two ways to do the irreversible thing is one more than necessary —
/// and a drawer is for going somewhere, which is what this now does.
class _RootDrawer extends StatelessWidget {
  const _RootDrawer();

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
                    'دعاية',
                    style: context.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Gated, not greyed: a link that only ever leads to a screen this account cannot
            // read is a row to leave out. The route guards it again — this is the courtesy,
            // that is the boundary.
            PermissionGate(
              permission: AppPermission.viewInventory,
              child: _DrawerLink(
                icon: AppIcons.warehouse,
                label: 'المخزن',
                onTap: () => context.push(Routes.warehouse),
              ),
            ),
            _DrawerLink(
              icon: AppIcons.city,
              label: 'مدن التوصيل',
              onTap: () => context.push(Routes.cities),
            ),
            // Who we buy from. Gated for the same reason the carriers below are: a supplier is
            // chosen from the purchase-order screen's own picker, so no other form needs the
            // list to be readable.
            PermissionGate(
              permission: AppPermission.viewVendors,
              child: _DrawerLink(
                icon: AppIcons.vendors,
                label: 'الموردون',
                onTap: () => context.push(Routes.vendors),
              ),
            ),
            // The paperwork raised against those suppliers. Its own grant, not vendors.*:
            // agreeing terms with a supplier and raising an order against them are two jobs.
            PermissionGate(
              permission: AppPermission.viewPurchaseOrders,
              child: _DrawerLink(
                icon: AppIcons.purchaseOrders,
                label: 'أوامر الشراء',
                onTap: () => context.push(Routes.purchaseOrders),
              ),
            ),
            // Beside أوامر الشراء because it is the same kind of back-office reference data: a
            // standing figure curated once and read by every order that reaches الطباعة.
            //
            // Hidden for now — see [_showManufacturingCostRates].
            if (_showManufacturingCostRates)
              PermissionGate(
                permission: AppPermission.viewManufacturingCostRates,
                child: _DrawerLink(
                  icon: AppIcons.manufacturingCostRates,
                  label: 'معدلات تكلفة التصنيع',
                  onTap: () => context.push(Routes.manufacturingCostRates),
                ),
              ),
            // Gated: unlike the map above, this list is not needed to fill any form in — a
            // carrier is chosen from the dispatch screen's own picker.
            PermissionGate(
              permission: AppPermission.viewShippingCompanies,
              child: _DrawerLink(
                icon: AppIcons.warehouse,
                label: 'شركات التوصيل',
                onTap: () => context.push(Routes.shippingCompanies),
              ),
            ),
            // Not gated: `business_fields.view` is granted to every role, because the customer
            // form cannot be filled in without this list. The screen itself hides the controls
            // an account without `business_fields.manage` cannot use.
            _DrawerLink(
              icon: AppIcons.businessField,
              label: 'مجالات العمل',
              onTap: () => context.push(Routes.businessFields),
            ),
            // Gated on *reading* products, not on managing them: somebody who may see the
            // catalogue may see how it is organised. Adding and renaming is hidden inside.
            PermissionGate(
              permission: AppPermission.viewProducts,
              child: _DrawerLink(
                icon: AppIcons.productCategory,
                label: 'تصنيفات المنتجات',
                onTap: () => context.push(Routes.productCategories),
              ),
            ),
            // Gated, not greyed: a link that only ever leads to a screen this account cannot
            // read is a row to leave out, not one to explain. The route guards it again — this
            // is the courtesy, that is the boundary.
            PermissionGate(
              permission: AppPermission.viewUsers,
              child: _DrawerLink(
                icon: AppIcons.employees,
                label: 'الموظفون',
                onTap: () => context.push(Routes.employees),
              ),
            ),
            PermissionGate(
              permission: AppPermission.manageRoles,
              child: _DrawerLink(
                icon: AppIcons.roles,
                label: 'الأدوار والصلاحيات',
                onTap: () => context.push(Routes.roles),
              ),
            ),
            // Last of the rows, because it is a manager's screen rather than a daily one — and
            // the only one here that is read rather than curated.
            PermissionGate(
              permission: AppPermission.viewProfitAndLossReport,
              child: _DrawerLink(
                icon: AppIcons.report,
                label: 'الأرباح والخسائر',
                onTap: () => context.push(Routes.profitAndLoss),
              ),
            ),
            const Spacer(),
            const Divider(height: 1),
            _DrawerLink(
              icon: AppIcons.settings,
              label: 'الإعدادات',
              onTap: () => context.push(Routes.settings),
            ),
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
