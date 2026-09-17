import 'package:dayaa_client/core/utils/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// The bar the five sections live behind.
///
/// **An `indexedStack`, so each section keeps its scroll position and its Cubit.** A customer
/// who scrolls halfway down the catalogue, checks an order and comes back should find the
/// catalogue where they left it — rebuilding the branch would send them to the top and fire the
/// request again.
///
/// **«تصاميمي» earns a tab, «الدعم» does not.** Designs are the feature this app exists to make
/// possible — artwork uploaded once and pointed at by every order — and a section buried behind
/// the home screen is one customers do not find. Support is the opposite: somewhere you go when
/// something has gone wrong, which is rare enough to reach from «الخدمات» on the home screen.
class HomeShell extends StatelessWidget {
  const HomeShell({required this.shell, super.key});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // `initialLocation` on the branch already showing: tapping the current tab returns it
        // to its first screen, which is what every app does and what people try.
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          NavigationDestination(
            icon: Icon(AppIcons.home),
            label: 'الرئيسية',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.products),
            label: 'المنتجات',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.orders),
            label: 'طلباتي',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.designs),
            label: 'تصاميمي',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.person),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }
}
