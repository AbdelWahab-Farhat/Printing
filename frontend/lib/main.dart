import 'package:flutter/material.dart';
import 'package:printing/app.dart';
import 'package:printing/core/di/injector.dart';
import 'package:printing/core/router/app_router.dart';

/// Start-up, in order, and nothing else.
///
/// Every step here has to finish before the first frame — anything that does not belongs in a
/// Cubit that loads after the UI is up, because work done here is time the user spends looking
/// at a splash screen.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Injector.init(
    // The interceptor has just cleared a rejected token; all that is left is to get the user
    // somewhere sensible. Passed in as a callback so the network layer never imports the
    // router — that dependency would point the wrong way.
    // Login, not home. `Routes.home` is '/', which is *inside* the signed-in shell: a rejected
    // token would land there, HomeCubit would immediately ask `/auth/me`, and the app would 401
    // its way around in a circle — a shell rendering with no session, every gated control
    // silently absent and a card with nobody's name on it.
    onUnauthorized: () async {
      AppRouter.instance.go(Routes.login);
    },
  );

  runApp(const PrintingApp());
}
