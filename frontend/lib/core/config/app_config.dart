import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Which build this is. Chosen at compile time with `--dart-define=FLAVOR=dev`, so a release
/// build cannot be talked into pointing at the development API by anything at runtime.
///
/// **One file each, and no two share one.** The env file is the only thing deciding which API a
/// build talks to, so a flavour without its own would be a build silently pointed at whichever
/// server its neighbour uses — the kind of mistake that is invisible until real data lands
/// somewhere it should not.
/// **Two, and a third was tried and removed.** A `user` flavour existed briefly so the build
/// handed to customers could point somewhere of its own — but there is one production API, so
/// its env file named a different path to the same server and the two builds were
/// indistinguishable. A flavour is worth its keep only when it points somewhere else; until a
/// second server actually answers, adding one back would recreate that.
enum Flavor {
  /// The machine the developer is sitting at. See `BASE_URL_ANDROID`.
  dev('.env.dev'),

  /// Everything that is not a developer's laptop — the build that ships.
  prod('.env');

  const Flavor(this.envFile);

  /// Which file [AppConfig.load] reads. Bundled as an asset — a flavour added here and not
  /// listed under `assets:` in `pubspec.yaml` fails at launch, not at build.
  final String envFile;

  /// **Only [dev].** This gates the Android emulator's `10.0.2.2` rewrite, so any other flavour
  /// answering true would rewrite its host to an address that exists solely inside an emulator
  /// and reach nothing at all.
  bool get isDevelopment => this == Flavor.dev;

  static Flavor get current {
    const name = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

    // Falls back to `prod` rather than throwing: a typo in a build command must not produce a
    // release pointed at a developer's laptop.
    return Flavor.values.firstWhere(
      (flavor) => flavor.name == name,
      orElse: () => Flavor.prod,
    );
  }
}

/// Everything the app needs to know about *where* it is running.
///
/// One place reads `dotenv`, and it is this one. A `dotenv.env['…']` anywhere else is a
/// missing key waiting to become a null-check at a call site that has no idea what to do
/// about it.
abstract final class AppConfig {
  static Flavor get flavor => Flavor.current;

  static bool get isDev => flavor.isDevelopment;

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
      _orDefault('MAP_TILE_URL', 'https://tile.openstreetmap.org/{z}/{x}/{y}.png');

  /// Where a place search goes. Same reasoning as [mapTileUrl].
  static String get geocoderBaseUrl =>
      _orDefault('GEOCODER_BASE_URL', 'https://nominatim.openstreetmap.org');

  /// Reads a key, treating **blank as absent**.
  ///
  /// `??` alone is not enough and the difference is not academic: `MAP_TILE_URL=` in a `.env`
  /// gives `''`, not null, so a plain `??` hands an empty string to the map and every tile
  /// fails with "No host specified in URI" — a blank grey grid that still pans and still
  /// answers with coordinates.
  ///
  /// A key documented as optional will be written blank; that is what "optional" invites.
  static String _orDefault(String key, String fallback) {
    final value = dotenv.env[key];

    return (value == null || value.trim().isEmpty) ? fallback : value.trim();
  }

  /// Identifies this app to the tile server and the geocoder.
  ///
  /// Nominatim's policy requires it and enforces it: a request carrying a library's default
  /// user agent is answered with a 403 whose body is HTML. Because the envelope parser
  /// correctly refuses to show HTML as a message, that presents as "search silently finds
  /// nothing" — which is why this has a test of its own.
  static const String mapUserAgent = 'Dayaa/1.0 (ly.dayaa.app; support@dayaa.ly)';

  /// What `flutter_map` needs for the tile server: a package name, not a full agent string.
  ///
  /// It composes its own — `flutter_map (<this>)` — so handing it [mapUserAgent] would nest one
  /// agent string inside another.
  /// نفس `applicationId` على أندرويد و`PRODUCT_BUNDLE_IDENTIFIER` على iOS، حرفاً بحرف: هذا ما
  /// يقرؤه مشغّل خادم البلاطات في سجلّاته حين يقرّر من يحجب، وقيمة لا تطابق التطبيق المنشور
  /// تجعل الحجب يقع على اسم لا يملكه أحد.
  static const String mapPackageName = 'ly.dayaa.app';

  /// Long enough for a slow Libyan mobile connection, short enough that a dead server does not
  /// leave a spinner running for a minute.
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);
  static const Duration sendTimeout = Duration(seconds: 30); // uploads need the extra room
}
