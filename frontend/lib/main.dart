import 'package:dayaa/app.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Start-up, in order, and nothing else.
///
/// Every step here has to finish before the first frame — anything that does not belongs in a
/// Cubit that loads after the UI is up, because work done here is time the user spends looking
/// at a splash screen.
Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();

  // Hold the system's splash screen over the work below.
  //
  // Without this it is dismissed the moment Flutter can draw *anything*, which is before
  // `Injector.init` has read the `.env` and built Dio — so the logo would blink out, a bare
  // surface would sit there for a beat, and the same logo would fade back in on [SplashPage].
  // Held, the two screens are one picture: same mark, same background, no seam.
  FlutterNativeSplash.preserve(widgetsBinding: binding);

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

  runApp(const DayaaApp());

  // Taken down only now, with the app built and its first frame on the way. Removing it any
  // earlier — before `runApp` — would uncover a blank window; leaving it to the package's own
  // default would have uncovered one mid-`Injector.init`.
  FlutterNativeSplash.remove();
}
