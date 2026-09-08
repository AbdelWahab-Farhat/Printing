import 'dart:async';
import 'dart:io' show Platform;

import 'package:dayaa/features/notifications/usecases/register_device_token.dart';
import 'package:dayaa/features/notifications/usecases/release_device_token.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Everything push, in one file — as `SetNotificationsEnabled`'s docblock asked for.
///
/// **Why one file rather than a call at each site.** Registration has four moments (sign-in,
/// toggle on, toggle off, sign-out) and two of them are easy to forget. Spread across the
/// screens that trigger them, the sign-out release is the one that goes missing, and the symptom
/// — a shared counter phone still buzzing with the previous employee's orders — looks nothing
/// like a missing line in a logout method.
///
/// **This class never decides whether notifications are wanted.** The stored preference is the
/// caller's business; this only does what it is told, so there is one place to read for "what
/// does the server think this device is" and no second opinion.
class PushService {
  PushService({
    required RegisterDeviceToken registerToken,
    required ReleaseDeviceToken releaseToken,
    FirebaseMessaging? messaging,
  })  : _registerToken = registerToken,
        _releaseToken = releaseToken,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final RegisterDeviceToken _registerToken;
  final ReleaseDeviceToken _releaseToken;
  final FirebaseMessaging _messaging;

  StreamSubscription<String>? _tokenRefresh;
  StreamSubscription<RemoteMessage>? _foreground;
  StreamSubscription<RemoteMessage>? _opened;

  /// The last token handed to the server, so [release] can name the right one after the phone
  /// has rotated it. Null means "nothing registered from this process".
  String? _registered;

  /// Something arrived while the app was open. The badge listens; nothing else has to.
  void Function()? onForegroundMessage;

  /// The user tapped a notification and there is somewhere to go. **Never called with null** —
  /// an announcement carries no route and simply opens the app.
  void Function(String route)? onOpenRoute;

  /// Wires the three streams. Safe to call more than once; the previous subscriptions go first.
  ///
  /// Called once at start-up, **before** anybody signs in — listening costs nothing and a token
  /// rotation can happen at any time, including while signed out, where [_register] correctly
  /// does nothing because there is no session for the request to authenticate.
  Future<void> start() async {
    await stop();

    // FCM rotates tokens on its own schedule. A rotation the server never hears about is a
    // device that silently stops receiving anything, with no error anywhere.
    _tokenRefresh = _messaging.onTokenRefresh.listen((token) {
      if (_registered == null) return; // signed out — nothing to keep in step
      unawaited(_send(token));
    });

    _foreground = FirebaseMessaging.onMessage.listen((_) => onForegroundMessage?.call());

    // Background → tapped. The app is already alive, so the router is ready and this can push
    // straight away — unlike the terminated case, which [initialRoute] handles.
    _opened = FirebaseMessaging.onMessageOpenedApp.listen(_openFrom);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS can present a banner over the running app itself; Android cannot, which is the
      // whole of the platform difference here.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }

  Future<void> stop() async {
    await _tokenRefresh?.cancel();
    await _foreground?.cancel();
    await _opened?.cancel();
    _tokenRefresh = null;
    _foreground = null;
    _opened = null;
  }

  /// The route a cold start was launched from, or null for an ordinary launch.
  ///
  /// **Read this only after the splash has resolved the session.** The router's
  /// `initialLocation` is the splash precisely because it is the one place that decides whether
  /// there is a usable session; navigating a cold-start notification before that answer exists
  /// sends an unauthenticated user at an authenticated screen.
  Future<String?> initialRoute() async {
    final message = await _messaging.getInitialMessage();

    return _routeOf(message);
  }

  /// Asks the OS, and answers whether push may actually be delivered.
  ///
  /// **Called at sign-in, never at launch.** A prompt on the splash — before the user has seen
  /// anything worth being notified about — is the reliable way to earn a permanent denial, and
  /// iOS will not ask twice.
  Future<bool> requestPermission() async {
    final settings = await _messaging.requestPermission();

    return _granted(settings.authorizationStatus);
  }

  /// Whether the OS currently allows notifications, without prompting.
  ///
  /// The settings screen needs this: the stored preference can say «مفعّل» while the phone
  /// blocks everything, and a toggle that says yes while the OS says no stops the user looking
  /// for the real cause.
  Future<bool> hasOsPermission() async {
    final settings = await _messaging.getNotificationSettings();

    return _granted(settings.authorizationStatus);
  }

  /// Registers this device. Call after sign-in and when the toggle goes on.
  ///
  /// Returns false when the OS refused — the caller shows the blocked state rather than
  /// pretending it worked.
  Future<bool> register({bool askPermission = true}) async {
    final allowed = askPermission ? await requestPermission() : await hasOsPermission();
    if (!allowed) return false;

    final token = await _messaging.getToken();
    if (token == null) return false;

    await _send(token);

    return true;
  }

  /// Releases this device. Call at sign-out **before the bearer token is cleared**, and when the
  /// toggle goes off.
  ///
  /// Failure is swallowed on purpose: sign-out must not be blocked by a network error. The
  /// server-side row then outlives the session, which is why the backend also drops a token the
  /// moment FCM reports it dead.
  Future<void> release() async {
    final token = _registered ?? await _messaging.getToken();
    _registered = null;
    if (token == null) return;

    await _releaseToken(token: token);
  }

  Future<void> _send(String token) async {
    final result = await _registerToken(token: token, platform: _platform());
    result.fold((_) {}, (_) => _registered = token);
  }

  void _openFrom(RemoteMessage message) {
    final route = _routeOf(message);
    if (route != null) onOpenRoute?.call(route);
  }

  /// The server puts the destination in `data.route`, and it is **nullable by design** — an
  /// announcement has nowhere to go. An empty string is treated as absent rather than pushed at
  /// the router, which would land on the error page.
  String? _routeOf(RemoteMessage? message) {
    final route = message?.data['route'];

    return route is String && route.isNotEmpty ? route : null;
  }

  /// Matches the server's `DevicePlatform` enum — `android`, `ios`, `web`. A value outside those
  /// three is rejected by the request's validation, so this must not invent one.
  String _platform() {
    if (kIsWeb) return 'web';

    return Platform.isIOS ? 'ios' : 'android';
  }

  bool _granted(AuthorizationStatus status) =>
      status == AuthorizationStatus.authorized ||
      status == AuthorizationStatus.provisional;
}
