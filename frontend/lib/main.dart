import 'dart:async';
import 'package:dayaa/app.dart';
import 'package:dayaa/core/config/app_config.dart';
import 'package:dayaa/core/di/injector.dart';
import 'package:dayaa/core/push/push_service.dart';
import 'package:dayaa/core/router/app_router.dart';
import 'package:dayaa/features/notifications/presentation/viewmodel/unread_badge_cubit.dart';
import 'package:dayaa/firebase_options.dart';
import 'package:dayaa/firebase_options_dev.dart';
import 'package:firebase_core/firebase_core.dart';
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

  // Before `Injector.init`, because the container builds a `PushService` that reaches for
  // `FirebaseMessaging.instance` — and that throws rather than returning null on an app that was
  // never configured.
  //
  // **A failure here must not stop the app.** Push is one feature; the order book, the customers
  // and the whole in-app notification centre are plain authenticated endpoints that owe Firebase
  // nothing. A missing google-services.json on somebody's machine should cost them notifications,
  // not the application.
  //
  // **والخياراتُ تُنتقى بالنكهة.** مُعرّفُ `DefaultFirebaseOptions` هو تطبيقُ الإنتاج، وتمريرُه
  // من حزمة `ly.dayaa.app.dev` يطلب تسجيلاً لدى تطبيقٍ لا يملك هذه الحزمة فيُرفَض — فتموت
  // الإشعاراتُ وحدَها بينما كلُّ شيءٍ آخر يعمل. و`google-services.json` لا يُنقذ: التهيئةُ
  // بخياراتٍ صريحةٍ هنا تَجُبّ ما فيه.
  try {
    await Firebase.initializeApp(
      options: AppConfig.isDev
          ? DevFirebaseOptions.currentPlatform
          : DefaultFirebaseOptions.currentPlatform,
    );
  } on Exception catch (error) {
    debugPrint('Firebase did not start; push is off for this run: $error');
  }

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

  // Wired after the container exists and before the first frame, so a notification tapped on a
  // cold start has somewhere to be delivered by the time the router is up.
  //
  // **The terminated case is read by the splash, not here** — `getInitialMessage()` must not be
  // acted on until the splash has decided whether there is a usable session, or a cold-start tap
  // sends an unauthenticated user at an authenticated screen.
  final push = sl<PushService>()
    ..onOpenRoute = _openFromNotification
    ..onForegroundMessage = () => sl<UnreadBadgeCubit>().load();
  await push.start();

  runApp(const DayaaApp());

  // Taken down only now, with the app built and its first frame on the way. Removing it any
  // earlier — before `runApp` — would uncover a blank window; leaving it to the package's own
  // default would have uncovered one mid-`Injector.init`.
  FlutterNativeSplash.remove();
}


/// Where a tapped notification goes.
///
/// **An unrecognised route must not reach the router's error page.** An older app against a
/// newer backend is the ordinary case for this, not a corruption: the server may name a
/// destination this build has never heard of. Landing on the notifications list instead is the
/// honest fallback — the message is still there to read.
void _openFromNotification(String route) {
  try {
    unawaited(AppRouter.instance.push(route));
  } on Exception {
    unawaited(AppRouter.instance.push(Routes.notifications));
  }
}
