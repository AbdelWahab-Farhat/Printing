import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Which build this is. Chosen at compile time with `--dart-define=FLAVOR=dev`, so a release
/// build cannot be talked into pointing at the development API by anything at runtime.
enum Flavor {
  dev,
  prod;

  static Flavor get current {
    const name = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

    return Flavor.values.firstWhere(
      (flavor) => flavor.name == name,
      orElse: () => Flavor.prod,
    );
  }

  String get envFile => this == Flavor.dev ? '.env.dev' : '.env';
}

/// Everything the app needs to know about *where* it is running.
///
/// One place reads `dotenv`, and it is this one. A `dotenv.env['…']` anywhere else is a
/// missing key waiting to become a null-check at a call site that has no idea what to do
/// about it.
abstract final class AppConfig {
  static Flavor get flavor => Flavor.current;

  static bool get isDev => flavor == Flavor.dev;

  static Future<void> load() => dotenv.load(fileName: flavor.envFile);

  /// The API root, already including `/api/v1`.
  ///
  /// The Android emulator cannot reach the host's `127.0.0.1` — that address is the emulator
  /// itself — so development on Android goes through `10.0.2.2`. Getting this wrong costs an
  /// afternoon of "the app just hangs", which is why it is resolved here rather than typed
  /// into a config by each developer.
  static String get baseUrl {
    if (isDev && !kIsWeb && Platform.isAndroid) {
      final androidUrl = dotenv.env['BASE_URL_ANDROID'];
      if (androidUrl != null && androidUrl.isNotEmpty) return androidUrl;
    }

    final url = dotenv.env['BASE_URL'];
    assert(url != null && url.isNotEmpty, 'BASE_URL is missing from ${flavor.envFile}');

    return url ?? '';
  }

  /// Where map tiles come from.
  ///
  /// In `.env` rather than hard-coded, and that is not ceremony: OpenStreetMap's tile policy
  /// says in as many words that commercial use "should be especially aware that access may be
  /// withdrawn at any point". Moving to MapTiler, Stadia or LocationIQ has to be a config change
  /// and a restart, not a release.
  static String get mapTileUrl =>
      dotenv.env['MAP_TILE_URL'] ?? 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Where a place search goes. Same reasoning as [mapTileUrl].
  static String get geocoderBaseUrl =>
      dotenv.env['GEOCODER_BASE_URL'] ?? 'https://nominatim.openstreetmap.org';

  /// Identifies this app to the tile server and the geocoder.
  ///
  /// Nominatim's policy requires it and enforces it: a request carrying a library's default
  /// user agent is answered with a 403 whose body is HTML. Because the envelope parser
  /// correctly refuses to show HTML as a message, that presents as "search silently finds
  /// nothing" — which is why this has a test of its own.
  static const String mapUserAgent = 'PrintX/1.0 (printing-bags; support@printx.ly)';

  /// Long enough for a slow Libyan mobile connection, short enough that a dead server does not
  /// leave a spinner running for a minute.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 30); // uploads need the extra room
}
