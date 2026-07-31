import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/features/cities/presentation/views/cities_page.dart';

/// Route names, as constants.
///
/// `context.push(Routes.cities)` — never a typed-out `'/cities'`. A path string at a call site
/// is a broken link the compiler cannot see, and it will be found by a tester, not by a build.
abstract final class Routes {
  static const String home = '/';
  static const String cities = '/cities';
}

/// The app's navigation.
///
/// GoRouter only: no `Navigator.push(MaterialPageRoute(...))` anywhere. One router means deep
/// links, the Android back button and the browser's history all behave, and every one of those
/// is something an imperative push quietly breaks.
abstract final class AppRouter {
  static final GoRouter instance = GoRouter(
    initialLocation: Routes.home,
    routes: [
      GoRoute(
        path: Routes.home,
        builder: (context, state) => const _HomePlaceholder(),
      ),
      GoRoute(
        path: Routes.cities,
        builder: (context, state) => const CitiesPage(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('الصفحة غير موجودة\n${state.uri}', textAlign: TextAlign.center)),
    ),
  );
}

/// Stands in until the real home screen lands, so the app runs end-to-end from day one.
class _HomePlaceholder extends StatelessWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Printing')),
      body: Center(
        child: FilledButton.icon(
          onPressed: () => context.push(Routes.cities),
          icon: const Icon(Icons.location_city_rounded),
          label: const Text('مدن التوصيل'),
        ),
      ),
    );
  }
}
